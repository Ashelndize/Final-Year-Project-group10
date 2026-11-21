"""
Phase 7 — Audit trail verification tests.

Verifies that required events are recorded per Phase 6 Section B:
  - Authentication successes and failures.
  - Disease-report review decisions.
  - Announcement publication and withdrawal.
  - Veterinary assistance-request creation and response.
"""
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser, VetProfile
from audit.models import AuditEvent
from farms.models import Area, Farm
from reports.models import DiseaseReport
from veterinary.models import VetAssistanceRequest


PASSWORD = 'AuditTest@1!'


def _jwt(client, username, password=PASSWORD):
    r = client.post(
        '/api/v1/auth/login/',
        {'username': username, 'password': password},
        format='json',
    )
    return r.data.get('access')


class AuthAuditTests(APITestCase):
    """Login success and failure must both be audited."""

    @classmethod
    def setUpTestData(cls):
        cls.user = CustomUser.objects.create_user(
            username='audit_auth_user', password=PASSWORD, role='FARMER'
        )

    def test_successful_login_creates_audit_event(self):
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.LOGIN_SUCCESS,
            actor=self.user,
        ).count()
        self.client.post(
            '/api/v1/auth/login/',
            {'username': 'audit_auth_user', 'password': PASSWORD},
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.LOGIN_SUCCESS,
            actor=self.user,
        ).count()
        self.assertGreater(after_count, before_count,
                           'Successful login should create LOGIN_SUCCESS audit event')

    def test_failed_login_creates_audit_event(self):
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.LOGIN_FAIL,
        ).count()
        self.client.post(
            '/api/v1/auth/login/',
            {'username': 'audit_auth_user', 'password': 'WrongPass!'},
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.LOGIN_FAIL,
        ).count()
        self.assertGreater(after_count, before_count,
                           'Failed login should create LOGIN_FAIL audit event')


class ReportAuditTests(APITestCase):
    """Disease-report review decisions must be audited."""

    @classmethod
    def setUpTestData(cls):
        cls.farmer = CustomUser.objects.create_user(
            username='audit_rpt_farmer', password=PASSWORD, role='FARMER'
        )
        cls.authority = CustomUser.objects.create_user(
            username='audit_rpt_auth', password=PASSWORD, role='AUTHORITY'
        )
        cls.report = DiseaseReport.objects.create(
            reporter=cls.farmer,
            species='CATTLE',
            observation_date='2026-11-21',
            area_name='Audit Test Area',
            observed_signs='Swollen joints',
        )

    def test_report_review_creates_update_audit_event(self):
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
        ).count()
        token = _jwt(self.client, 'audit_rpt_auth')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        self.client.post(
            f'/api/v1/disease-reports/{self.report.pk}/review/',
            {'status': 'UNDER_REVIEW', 'review_notes': 'Starting review'},
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
        ).count()
        self.assertGreater(after_count, before_count,
                           'Report review should create UPDATE audit event')


class AnnouncementAuditTests(APITestCase):
    """Announcement publish and withdraw must be audited."""

    @classmethod
    def setUpTestData(cls):
        cls.authority = CustomUser.objects.create_user(
            username='audit_ann_auth', password=PASSWORD, role='AUTHORITY'
        )

    def setUp(self):
        token = _jwt(self.client, 'audit_ann_auth')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        # Create a fresh draft announcement for each test
        response = self.client.post(
            '/api/v1/announcements/',
            {
                'title': 'Audit Ann Test',
                'announcement_type': 'GENERAL',
                'content': 'Audit trail test announcement.',
            },
            format='json',
        )
        self.ann_id = response.data['id']

    def test_announcement_publish_creates_audit_event(self):
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
        ).count()
        self.client.post(f'/api/v1/announcements/{self.ann_id}/publish/', format='json')
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
        ).count()
        self.assertGreater(after_count, before_count,
                           'Announcement publish should create UPDATE audit event')

    def test_announcement_withdraw_creates_audit_event(self):
        self.client.post(f'/api/v1/announcements/{self.ann_id}/publish/', format='json')
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
        ).count()
        self.client.post(
            f'/api/v1/announcements/{self.ann_id}/withdraw/',
            {'reason': 'Withdrawn for audit test'},
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
        ).count()
        self.assertGreater(after_count, before_count,
                           'Announcement withdrawal should create UPDATE audit event')


class VetRequestAuditTests(APITestCase):
    """Vet assistance request creation and response must be audited."""

    @classmethod
    def setUpTestData(cls):
        cls.farmer = CustomUser.objects.create_user(
            username='audit_vet_farmer', password=PASSWORD, role='FARMER'
        )
        cls.vet = CustomUser.objects.create_user(
            username='audit_vet_vet', password=PASSWORD, role='VET'
        )
        VetProfile.objects.create(user=cls.vet, is_verified=True)
        cls.area = Area.objects.get_or_create(
            name='Audit Vet Area', defaults={'country': 'Zimbabwe'}
        )[0]
        cls.farm = Farm.objects.create(
            owner=cls.farmer, name='Audit Vet Farm', area=cls.area
        )

    def test_assistance_request_creation_creates_audit_event(self):
        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.CREATE,
            target_type='VetAssistanceRequest',
        ).count()
        token = _jwt(self.client, 'audit_vet_farmer')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        self.client.post(
            '/api/v1/assistance-requests/',
            {
                'farm': self.farm.pk,
                'description': 'Audit test request',
                'area_name': 'Audit Vet Area',
                'location_consent': False,
            },
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.CREATE,
            target_type='VetAssistanceRequest',
        ).count()
        self.assertGreater(after_count, before_count,
                           'Assistance request creation should create audit event')

    def test_vet_response_creates_audit_event(self):
        # Create the request first
        f_token = _jwt(self.client, 'audit_vet_farmer')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {f_token}')
        req_resp = self.client.post(
            '/api/v1/assistance-requests/',
            {
                'farm': self.farm.pk,
                'description': 'Audit respond test',
                'area_name': 'Audit Vet Area',
                'location_consent': False,
            },
            format='json',
        )
        req_id = req_resp.data['id']

        before_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='VetAssistanceRequest',
        ).count()
        v_token = _jwt(self.client, 'audit_vet_vet')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {v_token}')
        self.client.patch(
            f'/api/v1/assistance-requests/{req_id}/respond/',
            {'status': 'ACCEPTED'},
            format='json',
        )
        after_count = AuditEvent.objects.filter(
            action=AuditEvent.Action.UPDATE,
            target_type='VetAssistanceRequest',
        ).count()
        self.assertGreater(after_count, before_count,
                           'Vet response should create UPDATE audit event')
