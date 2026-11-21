from django.db import models
from django.conf import settings


class DiseaseReport(models.Model):
    STATUS_SUBMITTED = 'SUBMITTED'
    STATUS_UNDER_REVIEW = 'UNDER_REVIEW'
    STATUS_CLARIFICATION = 'CLARIFICATION_REQUESTED'
    STATUS_ACCEPTED = 'ACCEPTED_FOR_ASSESSMENT'
    STATUS_REJECTED = 'REJECTED'
    STATUS_CLOSED = 'CLOSED'

    STATUS_CHOICES = [
        (STATUS_SUBMITTED, 'Submitted'),
        (STATUS_UNDER_REVIEW, 'Under Review'),
        (STATUS_CLARIFICATION, 'Clarification Requested'),
        (STATUS_ACCEPTED, 'Accepted for Assessment'),
        (STATUS_REJECTED, 'Rejected'),
        (STATUS_CLOSED, 'Closed'),
    ]

    SPECIES_CATTLE = 'CATTLE'
    SPECIES_GOAT = 'GOAT'
    SPECIES_SHEEP = 'SHEEP'
    SPECIES_PIG = 'PIG'
    SPECIES_CHICKEN = 'CHICKEN'
    SPECIES_OTHER = 'OTHER'

    SPECIES_CHOICES = [
        (SPECIES_CATTLE, 'Cattle'),
        (SPECIES_GOAT, 'Goat'),
        (SPECIES_SHEEP, 'Sheep'),
        (SPECIES_PIG, 'Pig'),
        (SPECIES_CHICKEN, 'Chicken'),
        (SPECIES_OTHER, 'Other'),
    ]

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='disease_reports',
    )
    farm = models.ForeignKey(
        'farms.Farm',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='disease_reports',
    )
    species = models.CharField(max_length=20, choices=SPECIES_CHOICES)
    observation_date = models.DateField()
    area = models.ForeignKey(
        'farms.Area',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='disease_reports',
    )
    area_name = models.CharField(max_length=100, blank=True)
    observed_signs = models.TextField()
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default=STATUS_SUBMITTED)
    # Only an AUTHORITY user can set this — never set it automatically
    is_confirmed_outbreak = models.BooleanField(default=False)
    report_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    report_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    location_consent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Report #{self.pk} — {self.species} — {self.status}"
