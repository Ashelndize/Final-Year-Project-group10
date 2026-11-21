from django.db import models
from django.conf import settings


class KBSource(models.Model):
    title = models.CharField(max_length=255)
    content = models.TextField()
    citation = models.CharField(max_length=255)
    publisher = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    review_due_at = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"KBSource({self.title[:60]})"


class AssistantInteraction(models.Model):
    ANSWER_SOURCE_CHOICES = [
        ('KB', 'KB'),
        ('LLM_RETRIEVAL', 'LLM_RETRIEVAL'),
        ('FALLBACK_KB', 'FALLBACK_KB'),
        ('FALLBACK_NONE', 'FALLBACK_NONE'),
        ('REFUSED', 'REFUSED'),
        ('DISABLED', 'DISABLED'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    question = models.TextField()
    answer = models.TextField()
    answer_source = models.CharField(
        max_length=20,
        choices=ANSWER_SOURCE_CHOICES,
        default='FALLBACK_NONE',
    )
    kb_version = models.CharField(max_length=20, default='none')
    escalation = models.BooleanField(default=False)
    safety_flags = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Interaction(user={self.user_id}, source={self.answer_source})"

    def save(self, *args, **kwargs):
        if self.pk is not None:
            raise PermissionError("AssistantInteraction is append-only")
        super().save(*args, **kwargs)
