from django.conf import settings
from django.db import models


class AuditEvent(models.Model):
    class Action(models.TextChoices):
        LOGIN_SUCCESS = 'LOGIN_SUCCESS', 'Login Success'
        LOGIN_FAIL = 'LOGIN_FAIL', 'Login Failure'
        LOGOUT = 'LOGOUT', 'Logout'
        REGISTER = 'REGISTER', 'Register'
        CREATE = 'CREATE', 'Create'
        UPDATE = 'UPDATE', 'Update'
        DELETE = 'DELETE', 'Delete'
        VIEW = 'VIEW', 'View'
        PERMISSION_DENIED = 'PERMISSION_DENIED', 'Permission Denied'
        PASSWORD_CHANGE = 'PASSWORD_CHANGE', 'Password Change'
        ROLE_CHANGE = 'ROLE_CHANGE', 'Role Change'

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                              null=True, blank=True, related_name='audit_events')
    action = models.CharField(max_length=30, choices=Action.choices)
    target_type = models.CharField(max_length=100, blank=True)
    target_id = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'audit_event'
        ordering = ['-timestamp']

    def __str__(self):
        actor = self.actor.username if self.actor else 'Anonymous'
        return f"AuditEvent({actor}, {self.action}, {self.timestamp})"

    @classmethod
    def log(cls, actor, action, target_type='', target_id='', description='', ip_address=None):
        """Convenience method to create an audit event."""
        return cls.objects.create(
            actor=actor,
            action=action,
            target_type=target_type,
            target_id=str(target_id),
            description=description,
            ip_address=ip_address,
        )
