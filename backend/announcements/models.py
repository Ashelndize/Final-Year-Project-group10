from django.db import models
from django.conf import settings
from django.utils import timezone


class OfficialAnnouncement(models.Model):
    TYPE_OUTBREAK_ALERT = 'OUTBREAK_ALERT'
    TYPE_ADVISORY = 'ADVISORY'
    TYPE_GENERAL = 'GENERAL'
    TYPE_WITHDRAWAL = 'WITHDRAWAL'

    ANNOUNCEMENT_TYPES = [
        (TYPE_OUTBREAK_ALERT, 'Outbreak Alert'),
        (TYPE_ADVISORY, 'Advisory'),
        (TYPE_GENERAL, 'General Information'),
        (TYPE_WITHDRAWAL, 'Withdrawal'),
    ]

    STATUS_DRAFT = 'DRAFT'
    STATUS_PUBLISHED = 'PUBLISHED'
    STATUS_EXPIRED = 'EXPIRED'
    STATUS_WITHDRAWN = 'WITHDRAWN'

    STATUS_CHOICES = [
        (STATUS_DRAFT, 'Draft'),
        (STATUS_PUBLISHED, 'Published'),
        (STATUS_EXPIRED, 'Expired'),
        (STATUS_WITHDRAWN, 'Withdrawn'),
    ]

    SPECIES_CHOICES = [
        ('', 'All Species'),
        ('CATTLE', 'Cattle'),
        ('GOAT', 'Goat'),
        ('SHEEP', 'Sheep'),
        ('PIG', 'Pig'),
        ('CHICKEN', 'Chicken'),
        ('OTHER', 'Other'),
    ]

    title = models.CharField(max_length=255)
    announcement_type = models.CharField(max_length=20, choices=ANNOUNCEMENT_TYPES, default=TYPE_ADVISORY)
    content = models.TextField()
    prevention_guidance = models.TextField(blank=True)
    issuing_authority = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='issued_announcements',
        limit_choices_to={'role__in': ['AUTHORITY', 'ADMIN']},
    )
    affected_area = models.ForeignKey(
        'farms.Area',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='announcements',
    )
    affected_area_name = models.CharField(max_length=100, blank=True)
    affected_species = models.CharField(max_length=20, choices=SPECIES_CHOICES, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    published_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    withdrawn_at = models.DateTimeField(null=True, blank=True)
    withdrawal_reason = models.TextField(blank=True)
    related_reports = models.ManyToManyField(
        'reports.DiseaseReport',
        blank=True,
        related_name='linked_announcements',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.get_announcement_type_display()}] {self.title} — {self.status}"

    @property
    def is_published(self):
        return self.status == self.STATUS_PUBLISHED

    @property
    def is_active(self):
        if self.status != self.STATUS_PUBLISHED:
            return False
        if self.expires_at and self.expires_at < timezone.now():
            return False
        return True
