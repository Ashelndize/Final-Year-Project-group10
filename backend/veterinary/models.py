from django.db import models
from django.conf import settings


class VetAssistanceRequest(models.Model):
    STATUS_PENDING = 'PENDING'
    STATUS_ACCEPTED = 'ACCEPTED'
    STATUS_IN_PROGRESS = 'IN_PROGRESS'
    STATUS_COMPLETED = 'COMPLETED'
    STATUS_CANCELLED = 'CANCELLED'
    STATUS_DECLINED = 'DECLINED'

    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_ACCEPTED, 'Accepted'),
        (STATUS_IN_PROGRESS, 'In Progress'),
        (STATUS_COMPLETED, 'Completed'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_DECLINED, 'Declined'),
    ]

    farmer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='assistance_requests',
    )
    vet = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='vet_requests',
        limit_choices_to={'role': 'VET'},
    )
    farm = models.ForeignKey(
        'farms.Farm',
        on_delete=models.CASCADE,
        related_name='assistance_requests',
    )
    animal = models.ForeignKey(
        'animals.Animal',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assistance_requests',
    )
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    farmer_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    farmer_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    area_name = models.CharField(max_length=100, blank=True)
    location_consent = models.BooleanField(default=False)
    vet_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Request #{self.pk} from {self.farmer.username} — {self.status}"

    @property
    def is_open(self):
        return self.status in (self.STATUS_PENDING, self.STATUS_ACCEPTED, self.STATUS_IN_PROGRESS)
