from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from accounts.models import CustomUser
from farms.models import Area, Farm
from .models import VetAssistanceRequest


class VetAssistanceRequestTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.area = Area.objects.create(name='Harare', province='Harare', country='Zimbabwe')
        self.farmer = CustomUser.objects.create_user(
            username='farmer_p4', password='Farmer@1234', role='FARMER'
        )
        self.vet = CustomUser.objects.create_user(
            username='vet_p4', password='Vet@12345Dev', role='VET'
        )
        self.farm = Farm.objects.create(
            name='Test Farm', farm_type='MIXED', owner=self.farmer, area=self.area
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_farmer_can_create_request(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/assistance-requests/', {
            'farm': self.farm.id,
            'description': 'My cow is sick',
            'area_name': 'Harare',
            'location_consent': False,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['status'], 'PENDING')

    def test_vet_cannot_create_request(self):
        self._auth(self.vet)
        resp = self.client.post('/api/v1/assistance-requests/', {
            'farm': self.farm.id,
            'description': 'Test',
            'location_consent': False,
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_farmer_sees_only_own_requests(self):
        self._auth(self.farmer)
        VetAssistanceRequest.objects.create(
            farmer=self.farmer, farm=self.farm, description='Test', area_name='Harare'
        )
        other_farmer = CustomUser.objects.create_user(
            username='farmer2_p4', password='Farmer@1234', role='FARMER'
        )
        other_farm = Farm.objects.create(
            name='Other Farm', farm_type='MIXED', owner=other_farmer, area=self.area
        )
        VetAssistanceRequest.objects.create(
            farmer=other_farmer, farm=other_farm, description='Other', area_name='Bulawayo'
        )
        resp = self.client.get('/api/v1/assistance-requests/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 1)

    def test_vet_can_respond(self):
        self._auth(self.farmer)
        create_resp = self.client.post('/api/v1/assistance-requests/', {
            'farm': self.farm.id,
            'description': 'Urgent help needed',
            'area_name': 'Harare',
            'location_consent': False,
        })
        req_id = create_resp.data['id']
        self._auth(self.vet)
        resp = self.client.patch(
            f'/api/v1/assistance-requests/{req_id}/respond/',
            {'status': 'ACCEPTED', 'vet_notes': 'On my way'},
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'ACCEPTED')

    def test_location_stripped_without_consent(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/assistance-requests/', {
            'farm': self.farm.id,
            'description': 'Test',
            'area_name': 'Harare',
            'location_consent': False,
            'farmer_latitude': '-17.825166',
            'farmer_longitude': '31.033510',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        obj = VetAssistanceRequest.objects.get(pk=resp.data['id'])
        self.assertIsNone(obj.farmer_latitude)
        self.assertIsNone(obj.farmer_longitude)
