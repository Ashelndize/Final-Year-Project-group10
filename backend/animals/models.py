from django.conf import settings
from django.db import models
from farms.models import Farm


class Animal(models.Model):
    class Species(models.TextChoices):
        CATTLE = 'CATTLE', 'Cattle'
        GOAT = 'GOAT', 'Goat'
        SHEEP = 'SHEEP', 'Sheep'
        POULTRY = 'POULTRY', 'Poultry'
        PIG = 'PIG', 'Pig'
        OTHER = 'OTHER', 'Other'

    class Sex(models.TextChoices):
        MALE = 'M', 'Male'
        FEMALE = 'F', 'Female'
        UNKNOWN = 'U', 'Unknown'

    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        SOLD = 'SOLD', 'Sold'
        DECEASED = 'DECEASED', 'Deceased'
        ARCHIVED = 'ARCHIVED', 'Archived'

    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='animals')
    tag_number = models.CharField(max_length=100)
    name = models.CharField(max_length=255, blank=True)
    species = models.CharField(max_length=20, choices=Species.choices)
    breed = models.CharField(max_length=100, blank=True)
    sex = models.CharField(max_length=1, choices=Sex.choices, default=Sex.UNKNOWN)
    date_of_birth = models.DateField(null=True, blank=True)
    weight_kg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'animals_animal'
        unique_together = ('farm', 'tag_number')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.tag_number} — {self.species} ({self.farm.name})"
