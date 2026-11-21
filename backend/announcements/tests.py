from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from accounts.models import CustomUser
from farms.models import Area
from .models import OfficialAnnouncement


class OfficialAnnouncementTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.area = Area.objects.create(name='Harare', province='Harare', country='Zimbabwe')
        self.authority = CustomUser.objects.create_user(
            username='auth_ann', password='Authority@1234', role='AUTHORITY'
        )
        self.farmer = CustomUser.objects.create_user(
            username='farmer_ann', password='Farmer@1234', role='FARMER'
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def _make_draft(self):
        self._auth(self.authority)
        resp = self.client.post('/api/v1/announcements/', {
            'title': 'FMD Advisory',
            'announcement_type': 'ADVISORY',
            'content': 'Foot and Mouth Disease has been reported in the region.',
            'prevention_guidance': 'Vaccinate cattle. Avoid movement of livestock.',
            'affected_area_name': 'Harare North',
            'affected_species': 'CATTLE',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        return resp.data['id']

    def test_authority_can_create_draft(self):
        ann_id = self._make_draft()
        self.assertIsNotNone(ann_id)

    def test_farmer_cannot_create_announcement(self):
        self._auth(self.farmer)
        resp = self.client.post('/api/v1/announcements/', {
            'title': 'Farmer announcement',
            'announcement_type': 'ADVISORY',
            'content': 'Test',
        })
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_authority_can_publish(self):
        ann_id = self._make_draft()
        resp = self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'PUBLISHED')
        self.assertIsNotNone(resp.data['published_at'])

    def test_farmer_can_read_published_announcement(self):
        ann_id = self._make_draft()
        self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        self._auth(self.farmer)
        resp = self.client.get('/api/v1/announcements/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 1)

    def test_farmer_cannot_see_draft(self):
        self._make_draft()  # stays as draft
        self._auth(self.farmer)
        resp = self.client.get('/api/v1/announcements/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 0)

    def test_authority_can_withdraw_with_reason(self):
        ann_id = self._make_draft()
        self._auth(self.authority)
        self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        resp = self.client.post(
            f'/api/v1/announcements/{ann_id}/withdraw/',
            {'reason': 'Situation resolved — no further risk.'},
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'WITHDRAWN')

    def test_withdraw_requires_reason(self):
        ann_id = self._make_draft()
        self._auth(self.authority)
        self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        resp = self.client.post(f'/api/v1/announcements/{ann_id}/withdraw/', {})
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_publish_draft_twice(self):
        ann_id = self._make_draft()
        self._auth(self.authority)
        self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        resp = self.client.post(f'/api/v1/announcements/{ann_id}/publish/')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
