from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from accounts.models import CustomUser
from farms.models import Farm, Area
from animals.models import Animal
from .models import HealthRecord, VaccinationProtocol
import datetime


def make_farmer_animal(username):
    user = CustomUser.objects.create_user(
        username=username, password='Test@1234Health',
        role='FARMER', email=f'{username}@test.com',
        first_name='Test', last_name='Farmer'
    )
    area = Area.objects.create(name=f'HArea-{username}')
    farm = Farm.objects.create(owner=user, name=f'HFarm-{username}', area=area)
    animal = Animal.objects.create(farm=farm, tag_number='HA001', species='CATTLE', sex='F')
    return user, animal


class HealthRecordAPITest(APITestCase):
    def setUp(self):
        self.farmer1, self.animal1 = make_farmer_animal('health_farmer1')
        self.farmer2, self.animal2 = make_farmer_animal('health_farmer2')

    def test_farmer_can_create_health_record(self):
        self.client.force_authenticate(user=self.farmer1)
        data = {
            'animal': self.animal1.pk,
            'record_date': str(datetime.date.today()),
            'health_status': 'HEALTHY',
            'weight_kg': '250.00',
        }
        response = self.client.post(reverse('health-record-list'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_farmer_cannot_create_health_record_for_other_animal(self):
        self.client.force_authenticate(user=self.farmer1)
        data = {
            'animal': self.animal2.pk,
            'record_date': str(datetime.date.today()),
            'health_status': 'HEALTHY',
        }
        response = self.client.post(reverse('health-record-list'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_farmer_cannot_see_other_farmer_health_records(self):
        HealthRecord.objects.create(
            animal=self.animal2, recorded_by=self.farmer2,
            record_date=datetime.date.today(), health_status='SICK'
        )
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.get(reverse('health-record-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)
