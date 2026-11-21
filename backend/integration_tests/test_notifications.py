"""
Phase 7 — Notification tests.

Verifies that in-app notifications are sent correctly when official
announcements are published, and that the notification read/mark-all-read
workflow functions correctly.
"""
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser
from notifications.models import Notification


PASSWORD = 'NotifTest@1!'


def _jwt(client, username, password=PASSWORD):
    r = client.post(
        '/api/v1/auth/login/',
        {'username': username, 'password': password},
        format='json',
    )
    return r.data.get('access')


class AnnouncementNotificationTests(APITestCase):
    """Publishing an announcement must create Notification records for all
    active FARMER and VET users."""

    @classmethod
    def setUpTestData(cls):
        cls.authority = CustomUser.objects.create_user(
            username='notif_authority', password=PASSWORD, role='AUTHORITY'
        )
        cls.farmer1 = CustomUser.objects.create_user(
            username='notif_farmer1', password=PASSWORD, role='FARMER'
        )
        cls.farmer2 = CustomUser.objects.create_user(
            username='notif_farmer2', password=PASSWORD, role='FARMER'
        )
        cls.vet1 = CustomUser.objects.create_user(
            username='notif_vet1', password=PASSWORD, role='VET'
        )

    def _publish_announcement(self, title='Notif Test Advisory'):
        token = _jwt(self.client, 'notif_authority')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        create = self.client.post(
            '/api/v1/announcements/',
            {
                'title': title,
                'announcement_type': 'ADVISORY',
                'content': 'Notification test announcement.',
            },
            format='json',
        )
        ann_id = create.data['id']
        self.client.post(f'/api/v1/announcements/{ann_id}/publish/', format='json')
        return ann_id

    def test_all_farmers_and_vets_notified_on_publish(self):
        self._publish_announcement('All Users Notif Test')
        for username, user in [
            ('notif_farmer1', self.farmer1),
            ('notif_farmer2', self.farmer2),
            ('notif_vet1', self.vet1),
        ]:
            with self.subTest(username=username):
                count = Notification.objects.filter(
                    recipient=user,
                    title__icontains='All Users Notif Test',
                ).count()
                self.assertGreater(count, 0,
                                   f'{username} should have received a notification')

    def test_authority_not_notified_on_publish(self):
        """Authorities issue announcements; they are not in the notification target list."""
        self._publish_announcement('Authority Exclusion Test')
        count = Notification.objects.filter(
            recipient=self.authority,
            title__icontains='Authority Exclusion Test',
        ).count()
        self.assertEqual(count, 0,
                         'The issuing authority should not receive their own notification')

    def test_farmer_can_read_notifications(self):
        self._publish_announcement('Read Test Advisory')
        token = _jwt(self.client, 'notif_farmer1')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get('/api/v1/notifications/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get('results', response.data)
        self.assertGreater(len(results), 0, 'Farmer should see notifications')

    def test_farmer_can_mark_notification_as_read(self):
        self._publish_announcement('Mark Read Test Advisory')
        notif = Notification.objects.filter(
            recipient=self.farmer1,
            title__icontains='Mark Read Test Advisory',
        ).first()
        self.assertIsNotNone(notif)
        token = _jwt(self.client, 'notif_farmer1')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post(f'/api/v1/notifications/{notif.pk}/mark_read/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        notif.refresh_from_db()
        self.assertTrue(notif.is_read)

    def test_farmer_can_mark_all_notifications_read(self):
        self._publish_announcement('Mark All Read Test')
        token = _jwt(self.client, 'notif_farmer1')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post('/api/v1/notifications/mark_all_read/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        unread = Notification.objects.filter(
            recipient=self.farmer1, is_read=False
        ).count()
        self.assertEqual(unread, 0, 'All notifications should be marked read')

    def test_farmer_cannot_see_other_farmers_notifications(self):
        self._publish_announcement('Cross Notif Test')
        f2_notif = Notification.objects.filter(
            recipient=self.farmer2,
            title__icontains='Cross Notif Test',
        ).first()
        self.assertIsNotNone(f2_notif)
        # farmer1 tries to mark farmer2's notification as read
        token = _jwt(self.client, 'notif_farmer1')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post(f'/api/v1/notifications/{f2_notif.pk}/mark_read/')
        self.assertIn(
            response.status_code,
            [status.HTTP_404_NOT_FOUND, status.HTTP_403_FORBIDDEN],
            "farmer1 should not be able to mark farmer2's notification as read",
        )
