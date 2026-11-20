from django.conf import settings
from django.db import models


class Notification(models.Model):
    class NotificationType(models.TextChoices):
        VACCINATION_DUE = 'VACCINATION_DUE', 'Vaccination Due'
        HEALTH_ALERT = 'HEALTH_ALERT', 'Health Alert'
        SYSTEM = 'SYSTEM', 'System'
        GENERAL = 'GENERAL', 'General'

    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                  related_name='notifications')
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices,
                                         default=NotificationType.GENERAL)
    title = models.CharField(max_length=255)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications_notification'
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification({self.recipient.username}, {self.title[:40]})"
