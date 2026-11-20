from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from accounts.models import CustomUser
from .models import Area, Farm


def make_farmer(username='farmer_a'):
    user = CustomUser.objects.create_user(
        username=username, password='Test@1234Farm',
        role='FARMER', email=f'{username}@test.com',
        first_name='Test', last_name='Farmer'
    )
    return user


class FarmModelTest(TestCase):
    def test_farm_str(self):
        farmer = make_farmer('farm_str_test')
        area = Area.objects.create(name='Test Area')
        farm = Farm.objects.create(owner=farmer, name='My Farm', area=area)
        self.assertIn('My Farm', str(farm))
        self.assertIn('farm_str_test', str(farm))


class FarmAPITest(APITestCase):
    def setUp(self):
        self.farmer1 = make_farmer('farm_api_farmer1')
        self.farmer2 = make_farmer('farm_api_farmer2')
        self.area = Area.objects.create(name='Test Province Area')
        self.farm1 = Farm.objects.create(owner=self.farmer1, name='Farm One', area=self.area)
        self.farm2 = Farm.objects.create(owner=self.farmer2, name='Farm Two', area=self.area)

    def test_farmer_sees_only_own_farms(self):
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.get(reverse('farm-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [f['name'] for f in response.data['results']]
        self.assertIn('Farm One', names)
        self.assertNotIn('Farm Two', names)

    def test_farmer_cannot_see_other_farmer_farm(self):
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.get(reverse('farm-detail', args=[self.farm2.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_unauthenticated_cannot_list_farms(self):
        response = self.client.get(reverse('farm-list'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_farmer_can_create_farm(self):
        self.client.force_authenticate(user=self.farmer1)
        data = {'name': 'New Farm', 'farm_type': 'BEEF', 'area': self.area.pk}
        response = self.client.post(reverse('farm-list'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['owner'], self.farmer1.pk)

    def test_farmer_cannot_delete_other_farmer_farm(self):
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.delete(reverse('farm-detail', args=[self.farm2.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
