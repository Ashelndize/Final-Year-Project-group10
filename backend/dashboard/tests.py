from django.test import TestCase, Client
from django.urls import reverse
from accounts.models import CustomUser
from farms.models import Area
from reports.models import DiseaseReport
from announcements.models import OfficialAnnouncement


class DashboardAuthTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.authority = CustomUser.objects.create_user(
            username='auth_dash', password='Authority@1234', role='AUTHORITY'
        )
        self.farmer = CustomUser.objects.create_user(
            username='farmer_dash', password='Farmer@1234', role='FARMER'
        )

    def test_index_redirects_unauthenticated(self):
        resp = self.client.get('/authority/')
        self.assertRedirects(resp, '/authority/login/', fetch_redirect_response=False)

    def test_farmer_cannot_access_dashboard(self):
        self.client.force_login(self.farmer)
        resp = self.client.get('/authority/')
        self.assertRedirects(resp, '/authority/login/', fetch_redirect_response=False)

    def test_authority_can_login_and_access_dashboard(self):
        self.client.force_login(self.authority)
        resp = self.client.get('/authority/')
        self.assertEqual(resp.status_code, 200)

    def test_login_view_accessible(self):
        resp = self.client.get('/authority/login/')
        self.assertEqual(resp.status_code, 200)


class DashboardReportTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.authority = CustomUser.objects.create_user(
            username='auth_rep', password='Authority@1234', role='AUTHORITY'
        )
        self.farmer = CustomUser.objects.create_user(
            username='farmer_rep', password='Farmer@1234', role='FARMER'
        )
        self.area = Area.objects.create(name='Harare', province='Harare', country='Zimbabwe')
        self.report = DiseaseReport.objects.create(
            reporter=self.farmer,
            species='CATTLE',
            observation_date='2026-11-20',
            area_name='Harare',
            observed_signs='Fever and nasal discharge',
        )
        self.client.force_login(self.authority)

    def test_report_queue_accessible(self):
        resp = self.client.get('/authority/reports/')
        self.assertEqual(resp.status_code, 200)

    def test_authority_can_update_report_status(self):
        resp = self.client.post(
            f'/authority/reports/{self.report.pk}/',
            {'new_status': 'UNDER_REVIEW', 'notes': 'Looks serious'},
        )
        self.report.refresh_from_db()
        self.assertEqual(self.report.status, 'UNDER_REVIEW')

    def test_clarification_requested_status_available(self):
        resp = self.client.post(
            f'/authority/reports/{self.report.pk}/',
            {'new_status': 'CLARIFICATION_REQUESTED'},
        )
        self.report.refresh_from_db()
        self.assertEqual(self.report.status, 'CLARIFICATION_REQUESTED')


class DashboardAnnouncementTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.authority = CustomUser.objects.create_user(
            username='auth_pub', password='Authority@1234', role='AUTHORITY'
        )
        self.client.force_login(self.authority)

    def test_create_draft_announcement(self):
        resp = self.client.post('/authority/announcements/new/', {
            'title': 'FMD Alert',
            'announcement_type': 'OUTBREAK_ALERT',
            'content': 'FMD detected in Mashonaland East.',
            'prevention_guidance': 'Vaccinate all cattle immediately.',
            'affected_area_name': 'Mashonaland East',
            'affected_species': 'CATTLE',
        })
        self.assertEqual(OfficialAnnouncement.objects.count(), 1)
        ann = OfficialAnnouncement.objects.first()
        self.assertEqual(ann.status, 'DRAFT')

    def test_publish_announcement(self):
        ann = OfficialAnnouncement.objects.create(
            title='Test', announcement_type='ADVISORY', content='Test content',
            issuing_authority=self.authority,
        )
        resp = self.client.post(f'/authority/announcements/{ann.pk}/publish/')
        ann.refresh_from_db()
        self.assertEqual(ann.status, 'PUBLISHED')
        self.assertIsNotNone(ann.published_at)

    def test_withdraw_requires_reason(self):
        ann = OfficialAnnouncement.objects.create(
            title='Test', announcement_type='ADVISORY', content='Test content',
            issuing_authority=self.authority, status='PUBLISHED',
        )
        resp = self.client.post(f'/authority/announcements/{ann.pk}/withdraw/', {'reason': ''})
        ann.refresh_from_db()
        self.assertEqual(ann.status, 'PUBLISHED')  # unchanged

    def test_withdraw_with_reason(self):
        from django.utils import timezone
        ann = OfficialAnnouncement.objects.create(
            title='Test', announcement_type='ADVISORY', content='Test content',
            issuing_authority=self.authority, status='PUBLISHED',
            published_at=timezone.now(),
        )
        resp = self.client.post(
            f'/authority/announcements/{ann.pk}/withdraw/',
            {'reason': 'Situation resolved.'},
        )
        ann.refresh_from_db()
        self.assertEqual(ann.status, 'WITHDRAWN')
