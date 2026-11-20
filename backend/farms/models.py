from django.conf import settings
from django.db import models


class Area(models.Model):
    name = models.CharField(max_length=255, unique=True)
    province = models.CharField(max_length=255, blank=True)
    country = models.CharField(max_length=100, default='Zimbabwe')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farms_area'
        ordering = ['name']

    def __str__(self):
        return self.name


class Farm(models.Model):
    class FarmType(models.TextChoices):
        DAIRY = 'DAIRY', 'Dairy'
        BEEF = 'BEEF', 'Beef'
        POULTRY = 'POULTRY', 'Poultry'
        MIXED = 'MIXED', 'Mixed'
        OTHER = 'OTHER', 'Other'

    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        ARCHIVED = 'ARCHIVED', 'Archived'

    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='farms')
    name = models.CharField(max_length=255)
    farm_type = models.CharField(max_length=20, choices=FarmType.choices, default=FarmType.MIXED)
    area = models.ForeignKey(Area, on_delete=models.SET_NULL, null=True, blank=True, related_name='farms')
    address = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farms_farm'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.owner.username})"
