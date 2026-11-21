from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from accounts.models import CustomUser
from farms.models import Area, Farm
from .models import DiseaseReport


class DiseaseReportTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.area = Area.objects.create(name='Harare', province='Harare', country='Zimbabwe')
        self.farmer = CustomUser.objects.create_user(
            username='farmer_rp4', password='Farmer@1234', role='FARMER'
        )
        self.authority = CustomUser.objects.create_user(
            username='auth_rp4', password='Authority@1234', role='AUTHORITY'
        )
        self.farm = Farm.objects.create(
            name='Test Farm', farm_type='MIXED', owner=self.farmer, area=self.area
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_farmer_can_submit_report(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/disease-reports/', {
            'species': 'CATTLE',
            'observation_date': '2026-11-20',
            'area_name': 'Harare North',
            'observed_signs': 'Fever, loss of appetite, nasal discharge',
            'location_consent': False,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['status'], 'SUBMITTED')
        self.assertFalse(resp.data['is_confirmed_outbreak'])

    def test_location_stripped_without_consent(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/disease-reports/', {
            'species': 'GOAT',
            'observation_date': '2026-11-20',
            'area_name': 'Harare',
            'observed_signs': 'Limping',
            'location_consent': False,
            'report_latitude': '-17.825',
            'report_longitude': '31.033',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        obj = DiseaseReport.objects.get(pk=resp.data['id'])
        self.assertIsNone(obj.report_latitude)
        self.assertIsNone(obj.report_longitude)

    def test_farmer_cannot_set_confirmed_outbreak(self):
        self._auth(self.farmer)
        report = DiseaseReport.objects.create(
            reporter=self.farmer,
            species='CATTLE',
            observation_date='2026-11-20',
            area_name='Harare',
            observed_signs='Severe illness',
            status=DiseaseReport.STATUS_ACCEPTED,
        )
        resp = self.client.post(f'/api/v1/disease-reports/{report.pk}/confirm_outbreak/')
        self.assertIn(resp.status_code, [403, 404])

    def test_authority_can_review(self):
        self._auth(self.farmer)
        create_resp = self.client.post('/api/v1/disease-reports/', {
            'species': 'SHEEP',
            'observation_date': '2026-11-20',
            'area_name': 'Bulawayo',
            'observed_signs': 'Unusual deaths',
            'location_consent': False,
        })
        report_id = create_resp.data['id']
        self._auth(self.authority)
        resp = self.client.post(
            f'/api/v1/disease-reports/{report_id}/review/',
            {'status': 'UNDER_REVIEW'},
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'UNDER_REVIEW')

    def test_unconfirmed_report_not_treated_as_outbreak(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/disease-reports/', {
            'species': 'PIG',
            'observation_date': '2026-11-20',
            'area_name': 'Gweru',
            'observed_signs': 'Skin lesions',
            'location_consent': False,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        # is_confirmed_outbreak must remain False for new submissions
        self.assertFalse(resp.data['is_confirmed_outbreak'])
        self.assertEqual(resp.data['status'], 'SUBMITTED')
