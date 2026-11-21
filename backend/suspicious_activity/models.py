from django.db import models
from django.conf import settings
from django.utils import timezone


class SuspiciousActivityFlag(models.Model):
    RULE_KEY_CHOICES = [
        ('repeated_failed_logins', 'repeated_failed_logins'),
        ('bulk_health_edits', 'bulk_health_edits'),
        ('cross_owner_probing', 'cross_owner_probing'),
        ('report_burst', 'report_burst'),
        ('announcement_edits', 'announcement_edits'),
        ('sync_replay_mismatch', 'sync_replay_mismatch'),
        ('permission_denied_burst', 'permission_denied_burst'),
    ]

    STATUS_CHOICES = [
        ('OPEN', 'OPEN'),
        ('REVIEWED_OK', 'REVIEWED_OK'),
        ('ESCALATED', 'ESCALATED'),
        ('FALSE_POSITIVE', 'FALSE_POSITIVE'),
        ('ACTION_TAKEN', 'ACTION_TAKEN'),
    ]

    rule_key = models.CharField(max_length=50, choices=RULE_KEY_CHOICES)
    explanation = models.TextField()
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='suspicious_flags',
    )
    window_start = models.DateTimeField()
    window_end = models.DateTimeField()
    evidence = models.JSONField(default=dict)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='OPEN')
    outcome_note = models.TextField(blank=True)
    rule_version = models.CharField(max_length=10, default='1.0')
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"SuspiciousActivityFlag({self.rule_key}, {self.actor_id}, {self.status})"

    def save(self, *args, **kwargs):
        if self.pk is not None:
            original = SuspiciousActivityFlag.objects.filter(pk=self.pk).values('status').first()
            if original and original['status'] == 'OPEN' and self.status != 'OPEN':
                self.resolved_at = timezone.now()
        super().save(*args, **kwargs)
