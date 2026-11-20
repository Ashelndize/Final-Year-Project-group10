from django.test import TestCase
from accounts.models import CustomUser
from .models import AuditEvent


class AuditEventTest(TestCase):
    def test_log_creates_event(self):
        user = CustomUser.objects.create_user(
            username='audit_user', password='Audit@1234', role='FARMER',
            email='audit_user@test.com'
        )
        event = AuditEvent.log(
            actor=user,
            action=AuditEvent.Action.LOGIN_SUCCESS,
            target_type='User',
            target_id=user.pk,
            description='Test login event',
        )
        self.assertEqual(event.action, AuditEvent.Action.LOGIN_SUCCESS)
        self.assertEqual(event.actor, user)

    def test_log_anonymous_event(self):
        event = AuditEvent.log(
            actor=None,
            action=AuditEvent.Action.LOGIN_FAIL,
            description='Anonymous login failure',
        )
        self.assertIsNone(event.actor)
        self.assertEqual(event.action, AuditEvent.Action.LOGIN_FAIL)
