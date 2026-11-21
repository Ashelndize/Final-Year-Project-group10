"""
Phase 7 — End-to-end workflow test.

Covers the 12-step sequence required by the Phase 7 spec:
  1.  Farmer creates an account.
  2.  Farmer creates a farm.
  3.  Farmer registers an animal.
  4.  Farmer records a health event.
  5.  Vaccination schedule recorded for that animal.
  6.  Farmer requests veterinary assistance.
  7.  A veterinarian responds within their permissions.
  8.  A permitted user submits a disease report.
  9.  An authorized reviewer assesses the report.
  10. The authorized authority publishes an official notice when justified.
  11. Relevant users receive the in-app notification.
  12. Sensitive actions appear in the audit history.
"""
import datetime

from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser, VetProfile
from audit.models import AuditEvent
from farms.models import Area
from health.models import VaccinationProtocol, VaccinationSchedule
from notifications.models import Notification


PASSWORD = 'IntTest@123!'


def _jwt(client, username, password=PASSWORD):
    r = client.post(
        '/api/v1/auth/login/',
        {'username': username, 'password': password},
        format='json',
    )
    return r.data['access']


class EndToEndWorkflowTest(APITestCase):
    """
    Single test method that walks every step of the required workflow.
    Each assertion is labelled with its step number so a failure immediately
    identifies which step broke.
    """

    @classmethod
    def setUpTestData(cls):
        # Shared fixtures that are never mutated.
        cls.area = Area.objects.create(
            name='E2E Test Area', province='Harare', country='Zimbabwe'
        )
        cls.protocol = VaccinationProtocol.objects.create(
            name='E2E FMD Protocol',
            species='CATTLE',
            vaccine_name='FMD Vaccine',
            doses_required=1,
            interval_days=365,
        )

        cls.vet_user = CustomUser.objects.create_user(
            username='e2e_vet', password=PASSWORD, role='VET'
        )
        VetProfile.objects.create(user=cls.vet_user, is_verified=True)

        cls.authority_user = CustomUser.objects.create_user(
            username='e2e_authority', password=PASSWORD, role='AUTHORITY'
        )

        # Second farmer used as a bystander for notification count validation
        cls.farmer2 = CustomUser.objects.create_user(
            username='e2e_farmer2', password=PASSWORD, role='FARMER'
        )

    def test_full_12_step_workflow(self):
        # ------------------------------------------------------------------ #
        # Step 1 — Farmer creates an account via the registration endpoint.   #
        # ------------------------------------------------------------------ #
        reg_response = self.client.post(
            '/api/v1/auth/register/',
            {
                'username': 'e2e_farmer',
                'password': PASSWORD,
                'password2': PASSWORD,
                'email': 'farmer@e2e.test',
                'first_name': 'E2E',
                'last_name': 'Farmer',
                'role': 'FARMER',
            },
            format='json',
        )
        self.assertEqual(reg_response.status_code, status.HTTP_201_CREATED,
                         'Step 1 — farmer registration failed')
        self.assertTrue(
            CustomUser.objects.filter(username='e2e_farmer').exists(),
            'Step 1 — registered user not found in DB',
        )

        farmer_token = _jwt(self.client, 'e2e_farmer')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')

        # ------------------------------------------------------------------ #
        # Step 2 — Farmer creates a farm.                                      #
        # ------------------------------------------------------------------ #
        farm_response = self.client.post(
            '/api/v1/farms/',
            {
                'name': 'E2E Farm',
                'farm_type': 'MIXED',
                'area': self.area.pk,
                'address': '1 E2E Road',
            },
            format='json',
        )
        self.assertEqual(farm_response.status_code, status.HTTP_201_CREATED,
                         'Step 2 — farm creation failed')
        farm_id = farm_response.data['id']

        # ------------------------------------------------------------------ #
        # Step 3 — Farmer registers an animal on that farm.                   #
        # ------------------------------------------------------------------ #
        animal_response = self.client.post(
            '/api/v1/animals/',
            {
                'farm': farm_id,
                'tag_number': 'E2E-001',
                'name': 'Bessie',
                'species': 'CATTLE',
                'sex': 'F',
            },
            format='json',
        )
        self.assertEqual(animal_response.status_code, status.HTTP_201_CREATED,
                         'Step 3 — animal registration failed')
        animal_id = animal_response.data['id']

        # ------------------------------------------------------------------ #
        # Step 4 — Farmer records a health event for the animal.              #
        # ------------------------------------------------------------------ #
        health_response = self.client.post(
            '/api/v1/health-records/',
            {
                'animal': animal_id,
                'record_date': '2026-11-21',
                'health_status': 'HEALTHY',
                'symptoms': '',
                'diagnosis': '',
                'notes': 'Routine check',
            },
            format='json',
        )
        self.assertEqual(health_response.status_code, status.HTTP_201_CREATED,
                         'Step 4 — health record creation failed')

        # ------------------------------------------------------------------ #
        # Step 5 — Vaccination schedule is recorded for the animal.           #
        # (Created programmatically as protocol creation requires ADMIN role) #
        # ------------------------------------------------------------------ #
        from animals.models import Animal
        animal_obj = Animal.objects.get(pk=animal_id)
        schedule = VaccinationSchedule.objects.create(
            animal=animal_obj,
            protocol=self.protocol,
            due_date=datetime.date(2027, 1, 1),
        )
        # Verify the farmer can read it back via the API
        sched_response = self.client.get('/api/v1/vaccination-schedules/')
        self.assertEqual(sched_response.status_code, status.HTTP_200_OK,
                         'Step 5 — vaccination schedule list failed')
        ids = [s['id'] for s in sched_response.data.get('results', sched_response.data)]
        self.assertIn(schedule.pk, ids, 'Step 5 — created schedule not visible to farmer')

        # ------------------------------------------------------------------ #
        # Step 6 — Farmer requests veterinary assistance.                     #
        # ------------------------------------------------------------------ #
        assist_response = self.client.post(
            '/api/v1/assistance-requests/',
            {
                'farm': farm_id,
                'description': 'Animal showing unusual symptoms',
                'area_name': 'E2E Test Area',
                'location_consent': False,
            },
            format='json',
        )
        self.assertEqual(assist_response.status_code, status.HTTP_201_CREATED,
                         'Step 6 — assistance request creation failed')
        request_id = assist_response.data['id']
        self.assertEqual(assist_response.data['status'], 'PENDING',
                         'Step 6 — new request should be PENDING')

        # ------------------------------------------------------------------ #
        # Step 7 — A veterinarian responds within their permissions.          #
        # ------------------------------------------------------------------ #
        vet_token = _jwt(self.client, 'e2e_vet')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {vet_token}')

        respond_response = self.client.patch(
            f'/api/v1/assistance-requests/{request_id}/respond/',
            {'status': 'ACCEPTED', 'vet_notes': 'On my way'},
            format='json',
        )
        self.assertEqual(respond_response.status_code, status.HTTP_200_OK,
                         'Step 7 — vet respond failed')
        self.assertEqual(respond_response.data['status'], 'ACCEPTED',
                         'Step 7 — status should be ACCEPTED after vet responds')

        # Farmer cannot use the /respond/ action (IsVet enforced)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')
        farmer_respond = self.client.patch(
            f'/api/v1/assistance-requests/{request_id}/respond/',
            {'status': 'COMPLETED'},
            format='json',
        )
        self.assertEqual(farmer_respond.status_code, status.HTTP_403_FORBIDDEN,
                         'Step 7 — farmer should not be allowed to use /respond/')

        # ------------------------------------------------------------------ #
        # Step 8 — A permitted user (farmer) submits a disease report.        #
        # ------------------------------------------------------------------ #
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')
        report_response = self.client.post(
            '/api/v1/disease-reports/',
            {
                'species': 'CATTLE',
                'observation_date': '2026-11-21',
                'area_name': 'E2E Test Area',
                'observed_signs': 'Fever and lethargy',
                'notes': 'Affects 3 animals',
                'location_consent': False,
            },
            format='json',
        )
        self.assertEqual(report_response.status_code, status.HTTP_201_CREATED,
                         'Step 8 — disease report submission failed')
        report_id = report_response.data['id']
        self.assertFalse(report_response.data.get('is_confirmed_outbreak', True),
                         'Step 8 — outbreak must not be auto-confirmed on submission')

        # ------------------------------------------------------------------ #
        # Step 9 — An authorized reviewer (AUTHORITY) assesses the report.   #
        # ------------------------------------------------------------------ #
        auth_token = _jwt(self.client, 'e2e_authority')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')

        review_response = self.client.post(
            f'/api/v1/disease-reports/{report_id}/review/',
            {'status': 'UNDER_REVIEW', 'review_notes': 'Investigating'},
            format='json',
        )
        self.assertEqual(review_response.status_code, status.HTTP_200_OK,
                         'Step 9 — report review failed')
        self.assertEqual(review_response.data['status'], 'UNDER_REVIEW',
                         'Step 9 — report status should be UNDER_REVIEW')

        # Farmer cannot review (permission guard)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')
        farmer_review = self.client.post(
            f'/api/v1/disease-reports/{report_id}/review/',
            {'status': 'UNDER_REVIEW'},
            format='json',
        )
        self.assertIn(farmer_review.status_code,
                      [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND],
                      'Step 9 — farmer should not be able to review a report')

        # ------------------------------------------------------------------ #
        # Step 10 — Authority publishes an official announcement.             #
        # ------------------------------------------------------------------ #
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {auth_token}')
        ann_response = self.client.post(
            '/api/v1/announcements/',
            {
                'title': 'E2E Cattle Advisory',
                'announcement_type': 'ADVISORY',
                'content': 'Cattle health advisory for E2E test area.',
                'prevention_guidance': 'Isolate affected animals.',
                'affected_species': 'CATTLE',
            },
            format='json',
        )
        self.assertEqual(ann_response.status_code, status.HTTP_201_CREATED,
                         'Step 10 — announcement creation failed')
        ann_id = ann_response.data['id']
        self.assertEqual(ann_response.data['status'], 'DRAFT',
                         'Step 10 — new announcement should be DRAFT')

        publish_response = self.client.post(
            f'/api/v1/announcements/{ann_id}/publish/',
            format='json',
        )
        self.assertEqual(publish_response.status_code, status.HTTP_200_OK,
                         'Step 10 — announcement publish failed')
        self.assertEqual(publish_response.data['status'], 'PUBLISHED',
                         'Step 10 — announcement should be PUBLISHED')

        # Farmer cannot publish (IsAuthority enforced)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')
        farmer_pub = self.client.post(f'/api/v1/announcements/{ann_id}/publish/', format='json')
        self.assertIn(farmer_pub.status_code,
                      [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND],
                      'Step 10 — farmer should not be able to publish')

        # ------------------------------------------------------------------ #
        # Step 11 — Relevant users receive in-app notifications.              #
        # ------------------------------------------------------------------ #
        # All FARMER and VET users should have received a notification.
        expected_recipients = {
            CustomUser.objects.get(username='e2e_farmer').pk,
            self.farmer2.pk,
            self.vet_user.pk,
        }
        notified_ids = set(
            Notification.objects.filter(
                title__icontains='E2E Cattle Advisory'
            ).values_list('recipient_id', flat=True)
        )
        self.assertTrue(
            expected_recipients.issubset(notified_ids),
            f'Step 11 — not all expected users notified. '
            f'Expected {expected_recipients}, got {notified_ids}',
        )

        # ------------------------------------------------------------------ #
        # Step 12 — Sensitive actions appear in the audit history.            #
        # ------------------------------------------------------------------ #
        # Verify that key audit events exist for actions performed above.
        audit_actions = set(
            AuditEvent.objects.filter(
                target_type__in=['VetAssistanceRequest', 'DiseaseReport', 'OfficialAnnouncement']
            ).values_list('action', flat=True)
        )
        self.assertIn(AuditEvent.Action.CREATE, audit_actions,
                      'Step 12 — no CREATE audit events found')
        self.assertIn(AuditEvent.Action.UPDATE, audit_actions,
                      'Step 12 — no UPDATE audit events found')
