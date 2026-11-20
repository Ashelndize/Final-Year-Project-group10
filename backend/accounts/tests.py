from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from .models import CustomUser, FarmerProfile, VetProfile


class UserModelTest(TestCase):
    def test_create_farmer(self):
        user = CustomUser.objects.create_user(
            username='testfarmer', password='Test@1234', role='FARMER',
            email='testfarmer@test.com'
        )
        self.assertTrue(user.is_farmer)
        self.assertFalse(user.is_vet)
        self.assertFalse(user.is_system_admin)

    def test_create_vet(self):
        user = CustomUser.objects.create_user(
            username='testvet', password='Test@1234', role='VET',
            email='testvet@test.com'
        )
        self.assertTrue(user.is_vet)
        self.assertFalse(user.is_farmer)

    def test_user_str(self):
        user = CustomUser.objects.create_user(
            username='strtest', password='Test@1234', role='FARMER',
            email='strtest@test.com'
        )
        self.assertIn('strtest', str(user))
        self.assertIn('FARMER', str(user))


class RegisterAPITest(APITestCase):
    def test_register_farmer(self):
        data = {
            'username': 'newfarmer', 'email': 'newfarmer@test.com',
            'first_name': 'New', 'last_name': 'Farmer',
            'password': 'StrongPass@123', 'password2': 'StrongPass@123',
            'role': 'FARMER',
        }
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(CustomUser.objects.filter(username='newfarmer').exists())
        self.assertTrue(FarmerProfile.objects.filter(user__username='newfarmer').exists())

    def test_register_vet(self):
        data = {
            'username': 'newvet', 'email': 'newvet@test.com',
            'first_name': 'New', 'last_name': 'Vet',
            'password': 'StrongPass@123', 'password2': 'StrongPass@123',
            'role': 'VET',
        }
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(VetProfile.objects.filter(user__username='newvet').exists())

    def test_register_mismatched_passwords(self):
        data = {
            'username': 'baduser', 'email': 'bad@test.com',
            'first_name': 'Bad', 'last_name': 'User',
            'password': 'StrongPass@123', 'password2': 'WrongPass@123',
            'role': 'FARMER',
        }
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_admin_role_blocked(self):
        data = {
            'username': 'hacker', 'email': 'hacker@test.com',
            'first_name': 'Bad', 'last_name': 'Actor',
            'password': 'StrongPass@123', 'password2': 'StrongPass@123',
            'role': 'ADMIN',
        }
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_authority_role_blocked(self):
        data = {
            'username': 'hacker2', 'email': 'hacker2@test.com',
            'first_name': 'Bad', 'last_name': 'Actor',
            'password': 'StrongPass@123', 'password2': 'StrongPass@123',
            'role': 'AUTHORITY',
        }
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class AuthAPITest(APITestCase):
    def setUp(self):
        self.user = CustomUser.objects.create_user(
            username='authtest', password='Auth@1234Test', role='FARMER',
            email='authtest@test.com', first_name='Auth', last_name='Test'
        )

    def test_login(self):
        data = {'username': 'authtest', 'password': 'Auth@1234Test'}
        response = self.client.post(reverse('token-obtain'), data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_login_invalid_credentials(self):
        data = {'username': 'authtest', 'password': 'WrongPassword'}
        response = self.client.post(reverse('token-obtain'), data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_endpoint_authenticated(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(reverse('me'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'authtest')

    def test_me_endpoint_unauthenticated(self):
        response = self.client.get(reverse('me'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_logout(self):
        login_data = {'username': 'authtest', 'password': 'Auth@1234Test'}
        login_response = self.client.post(reverse('token-obtain'), login_data)
        refresh_token = login_response.data['refresh']
        self.client.force_authenticate(user=self.user)
        response = self.client.post(reverse('logout'), {'refresh': refresh_token})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
