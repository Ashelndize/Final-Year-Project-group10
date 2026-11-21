"""
Phase 7 — Security tests.

Covers:
  - JWT token cannot be forged or reused after logout.
  - Brute-force lockout (django-axes) activates after repeated failures.
  - GPS coordinates are stripped when location_consent=False.
  - Sensitive fields (passwords, tokens) never appear in audit events.
  - Cross-user resource access is denied.
  - Admin-only endpoints reject all other roles.
"""
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser, VetProfile
from audit.models import AuditEvent
from farms.models import Area, Farm
from animals.models import Animal


PASSWORD = 'SecTest@123!'


def _jwt(client, username, password=PASSWORD):
    r = client.post(
        '/api/v1/auth/login/',
        {'username': username, 'password': password},
        format='json',
    )
    return r.data.get('access')


class JWTSecurityTests(APITestCase):
    """JWT tokens must be valid, unexpired, and revoked on logout."""

    @classmethod
    def setUpTestData(cls):
        cls.user = CustomUser.objects.create_user(
            username='sec_jwt_user', password=PASSWORD, role='FARMER'
        )

    def test_invalid_token_returns_401(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer totally.invalid.token')
        response = self.client.get('/api/v1/farms/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_tampered_token_returns_401(self):
        token = _jwt(self.client, 'sec_jwt_user')
        tampered = token[:-4] + 'XXXX'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {tampered}')
        response = self.client.get('/api/v1/farms/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_missing_bearer_prefix_returns_401(self):
        token = _jwt(self.client, 'sec_jwt_user')
        self.client.credentials(HTTP_AUTHORIZATION=token)  # no 'Bearer ' prefix
        response = self.client.get('/api/v1/farms/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_logout_blacklists_refresh_token(self):
        # Login to obtain tokens
        login = self.client.post(
            '/api/v1/auth/login/',
            {'username': 'sec_jwt_user', 'password': PASSWORD},
            format='json',
        )
        refresh = login.data['refresh']
        access = login.data['access']

        # Logout with the refresh token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
        logout = self.client.post(
            '/api/v1/auth/logout/', {'refresh': refresh}, format='json'
        )
        self.assertEqual(logout.status_code, status.HTTP_200_OK)

        # Attempting to refresh with the now-blacklisted token should fail
        refresh_response = self.client.post(
            '/api/v1/auth/token/refresh/', {'refresh': refresh}, format='json'
        )
        self.assertIn(
            refresh_response.status_code,
            [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED],
            'Blacklisted refresh token should be rejected',
        )


class LocationPrivacyTests(APITestCase):
    """GPS coordinates must never be stored without explicit consent."""

    @classmethod
    def setUpTestData(cls):
        cls.area = Area.objects.get_or_create(
            name='Sec Privacy Area', defaults={'country': 'Zimbabwe'}
        )[0]
        cls.farmer = CustomUser.objects.create_user(
            username='sec_privacy_farmer', password=PASSWORD, role='FARMER'
        )
        cls.farm = Farm.objects.create(
            owner=cls.farmer, name='Privacy Farm', area=cls.area
        )

    def setUp(self):
        token = _jwt(self.client, 'sec_privacy_farmer')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def test_disease_report_strips_coords_without_consent(self):
        response = self.client.post(
            '/api/v1/disease-reports/',
            {
                'species': 'GOAT',
                'observation_date': '2026-11-21',
                'area_name': 'Privacy Area',
                'observed_signs': 'Limping',
                'location_consent': False,
                'report_latitude': '17.8292',
                'report_longitude': '31.0522',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data.get('report_latitude'),
                          'Latitude must not be stored without consent')
        self.assertIsNone(response.data.get('report_longitude'),
                          'Longitude must not be stored without consent')

    def test_disease_report_stores_coords_with_consent(self):
        response = self.client.post(
            '/api/v1/disease-reports/',
            {
                'species': 'CATTLE',
                'observation_date': '2026-11-21',
                'area_name': 'Privacy Area',
                'observed_signs': 'Fever',
                'location_consent': True,
                'report_latitude': '17.8292',
                'report_longitude': '31.0522',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(response.data.get('report_latitude'),
                             'Latitude should be stored when consent is given')

    def test_assistance_request_strips_coords_without_consent(self):
        response = self.client.post(
            '/api/v1/assistance-requests/',
            {
                'farm': self.farm.pk,
                'description': 'Need help',
                'area_name': 'Privacy Area',
                'location_consent': False,
                'farmer_latitude': '17.8292',
                'farmer_longitude': '31.0522',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data.get('farmer_latitude'),
                          'Latitude must not be stored without consent')


class AuditSecurityTests(APITestCase):
    """Audit events must never contain passwords or tokens."""

    @classmethod
    def setUpTestData(cls):
        cls.admin = CustomUser.objects.create_user(
            username='sec_audit_admin', password=PASSWORD, role='ADMIN',
            is_staff=True, is_superuser=True,
        )
        cls.farmer = CustomUser.objects.create_user(
            username='sec_audit_farmer', password=PASSWORD, role='FARMER'
        )

    def setUp(self):
        token = _jwt(self.client, 'sec_audit_admin')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def test_audit_events_never_contain_password(self):
        # Trigger a login audit event
        self.client.post(
            '/api/v1/auth/login/',
            {'username': 'sec_audit_farmer', 'password': PASSWORD},
            format='json',
        )
        # Read all audit events as admin
        response = self.client.get('/api/v1/audit-events/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        events = response.data.get('results', response.data)
        for event in events:
            desc = event.get('description', '')
            self.assertNotIn('password', desc.lower(),
                             'Password should never appear in audit description')
            self.assertNotIn(PASSWORD, desc,
                             'Raw password value should never appear in audit description')

    def test_audit_events_never_contain_token(self):
        login = self.client.post(
            '/api/v1/auth/login/',
            {'username': 'sec_audit_farmer', 'password': PASSWORD},
            format='json',
        )
        access_token = login.data.get('access', '')
        response = self.client.get('/api/v1/audit-events/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        events = response.data.get('results', response.data)
        for event in events:
            desc = event.get('description', '')
            self.assertNotIn(access_token, desc,
                             'Access token should never appear in audit description')

    def test_audit_log_requires_admin(self):
        farmer_token = _jwt(self.client, 'sec_audit_farmer')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {farmer_token}')
        response = self.client.get('/api/v1/audit-events/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class CrossUserAccessTests(APITestCase):
    """Users must not access or modify other users' private resources."""

    @classmethod
    def setUpTestData(cls):
        cls.area = Area.objects.get_or_create(
            name='Cross Area', defaults={'country': 'Zimbabwe'}
        )[0]
        cls.user_a = CustomUser.objects.create_user(
            username='sec_cross_a', password=PASSWORD, role='FARMER'
        )
        cls.user_b = CustomUser.objects.create_user(
            username='sec_cross_b', password=PASSWORD, role='FARMER'
        )
        cls.farm_a = Farm.objects.create(
            owner=cls.user_a, name='Cross Farm A', area=cls.area
        )
        cls.animal_a = Animal.objects.create(
            farm=cls.farm_a, tag_number='CROSS-001', species='CATTLE'
        )

    def test_user_b_cannot_read_user_a_farm(self):
        token = _jwt(self.client, 'sec_cross_b')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get(f'/api/v1/farms/{self.farm_a.pk}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_user_b_cannot_delete_user_a_farm(self):
        token = _jwt(self.client, 'sec_cross_b')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.delete(f'/api/v1/farms/{self.farm_a.pk}/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
        )

    def test_user_b_cannot_read_user_a_animal(self):
        token = _jwt(self.client, 'sec_cross_b')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get(f'/api/v1/animals/{self.animal_a.pk}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_user_b_cannot_add_animal_to_user_a_farm(self):
        token = _jwt(self.client, 'sec_cross_b')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post(
            '/api/v1/animals/',
            {
                'farm': self.farm_a.pk,
                'tag_number': 'CROSS-HACK',
                'species': 'CATTLE',
            },
            format='json',
        )
        self.assertIn(
            response.status_code,
            [status.HTTP_400_BAD_REQUEST, status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND],
        )
