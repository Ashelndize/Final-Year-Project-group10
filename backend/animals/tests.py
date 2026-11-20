from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from accounts.models import CustomUser
from farms.models import Farm, Area
from .models import Animal


def make_farmer_with_farm(username):
    user = CustomUser.objects.create_user(
        username=username, password='Test@1234Animal',
        role='FARMER', email=f'{username}@test.com',
        first_name='Test', last_name='Farmer'
    )
    area = Area.objects.create(name=f'Area-{username}')
    farm = Farm.objects.create(owner=user, name=f'Farm-{username}', area=area)
    return user, farm


class AnimalAPITest(APITestCase):
    def setUp(self):
        self.farmer1, self.farm1 = make_farmer_with_farm('anim_farmer1')
        self.farmer2, self.farm2 = make_farmer_with_farm('anim_farmer2')
        self.animal1 = Animal.objects.create(
            farm=self.farm1, tag_number='A001', species='CATTLE', sex='F'
        )
        self.animal2 = Animal.objects.create(
            farm=self.farm2, tag_number='A002', species='GOAT', sex='M'
        )

    def test_farmer_sees_only_own_animals(self):
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.get(reverse('animal-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        tags = [a['tag_number'] for a in response.data['results']]
        self.assertIn('A001', tags)
        self.assertNotIn('A002', tags)

    def test_farmer_cannot_view_other_animal(self):
        self.client.force_authenticate(user=self.farmer1)
        response = self.client.get(reverse('animal-detail', args=[self.animal2.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_farmer_can_register_animal(self):
        self.client.force_authenticate(user=self.farmer1)
        data = {'farm': self.farm1.pk, 'tag_number': 'A999', 'species': 'CATTLE', 'sex': 'M'}
        response = self.client.post(reverse('animal-list'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_farmer_cannot_register_animal_on_other_farm(self):
        self.client.force_authenticate(user=self.farmer1)
        data = {'farm': self.farm2.pk, 'tag_number': 'A998', 'species': 'CATTLE', 'sex': 'M'}
        response = self.client.post(reverse('animal-list'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
