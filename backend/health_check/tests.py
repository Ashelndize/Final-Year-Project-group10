"""
Unit tests for the health_check app.

Run with: python manage.py test health_check
"""

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status


class HealthCheckEndpointTest(TestCase):
    """Tests for GET /api/v1/health/"""

    def setUp(self):
        self.client = APIClient()

    def test_health_check_returns_200(self):
        """Health-check endpoint must return HTTP 200."""
        url = reverse('health-check')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_health_check_returns_ok_status(self):
        """Health-check response body must contain status: ok."""
        url = reverse('health-check')
        response = self.client.get(url)
        data = response.json()
        self.assertEqual(data.get('status'), 'ok')

    def test_health_check_returns_service_name(self):
        """Health-check response body must include the service name."""
        url = reverse('health-check')
        response = self.client.get(url)
        data = response.json()
        self.assertEqual(data.get('service'), 'livestock-backend')

    def test_health_check_does_not_require_authentication(self):
        """Health-check endpoint must be accessible without a JWT token."""
        # No credentials attached — should still succeed
        url = reverse('health-check')
        response = self.client.get(url)
        self.assertNotEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertNotEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_health_check_post_not_allowed(self):
        """POST to the health-check endpoint must return 405 Method Not Allowed."""
        url = reverse('health-check')
        response = self.client.post(url, {})
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
