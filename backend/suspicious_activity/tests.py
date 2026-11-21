from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status

from accounts.models import CustomUser
from reports.models import DiseaseReport
from .models import SuspiciousActivityFlag
from .rules import check_report_burst


def _get_jwt(client, username, password):
    response = client.post(
        '/api/v1/auth/login/',
        {'username': username, 'password': password},
        format='json',
    )
    return response.data['access']


class SuspiciousActivityTests(APITestCase):

    def setUp(self):
        self.farmer = CustomUser.objects.create_user(
            username='testfarmer_sa',
            password='TestPass123!',
            role='FARMER',
        )
        self.authority = CustomUser.objects.create_user(
            username='testauthority_sa',
            password='TestPass123!',
            role='AUTHORITY',
        )
        token = _get_jwt(self.client, 'testauthority_sa', 'TestPass123!')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def _create_reports(self, count):
        for i in range(count):
            DiseaseReport.objects.create(
                reporter=self.farmer,
                species='CATTLE',
                observation_date='2026-11-21',
                area_name=f'Area {i}',
                observed_signs='Fever',
            )

    def test_report_burst_no_flag_below_threshold(self):
        self._create_reports(3)
        result = check_report_burst(self.farmer)
        self.assertIsNone(result)

    def test_report_burst_flag_above_threshold(self):
        self._create_reports(6)
        result = check_report_burst(self.farmer)
        self.assertIsNotNone(result)
        self.assertIsInstance(result, SuspiciousActivityFlag)
        self.assertEqual(result.rule_key, 'report_burst')

    def test_flag_already_exists_no_duplicate(self):
        self._create_reports(6)
        first = check_report_burst(self.farmer)
        self.assertIsNotNone(first)
        second = check_report_burst(self.farmer)
        self.assertIsNone(second)
        self.assertEqual(
            SuspiciousActivityFlag.objects.filter(
                rule_key='report_burst', actor=self.farmer
            ).count(),
            1,
        )

    def test_flag_resolve_changes_status(self):
        flag = SuspiciousActivityFlag.objects.create(
            rule_key='report_burst',
            explanation='Test flag',
            actor=self.farmer,
            window_start=timezone.now(),
            window_end=timezone.now(),
            evidence={'count': 6},
        )
        url = f'/api/v1/suspicious-flags/{flag.pk}/resolve/'
        response = self.client.post(
            url,
            {'status': 'REVIEWED_OK', 'outcome_note': 'Looks fine'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        flag.refresh_from_db()
        self.assertEqual(flag.status, 'REVIEWED_OK')

    def test_flag_false_positive_requires_note(self):
        flag = SuspiciousActivityFlag.objects.create(
            rule_key='report_burst',
            explanation='Test flag',
            actor=self.farmer,
            window_start=timezone.now(),
            window_end=timezone.now(),
            evidence={'count': 6},
        )
        url = f'/api/v1/suspicious-flags/{flag.pk}/resolve/'
        response = self.client.post(
            url,
            {'status': 'FALSE_POSITIVE'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
