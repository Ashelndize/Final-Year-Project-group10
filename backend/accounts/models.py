from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    class Role(models.TextChoices):
        FARMER = 'FARMER', 'Farmer'
        VET = 'VET', 'Veterinarian'
        AUTHORITY = 'AUTHORITY', 'Veterinary Authority'
        ADMIN = 'ADMIN', 'System Administrator'

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.FARMER)
    phone = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_user'

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def is_farmer(self):
        return self.role == self.Role.FARMER

    @property
    def is_vet(self):
        return self.role == self.Role.VET

    @property
    def is_authority(self):
        return self.role == self.Role.AUTHORITY

    @property
    def is_system_admin(self):
        return self.role == self.Role.ADMIN


class FarmerProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='farmer_profile')
    location = models.CharField(max_length=255, blank=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_farmer_profile'

    def __str__(self):
        return f"FarmerProfile({self.user.username})"


class VetProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='vet_profile')
    license_number = models.CharField(max_length=100, blank=True)
    specialization = models.CharField(max_length=255, blank=True)
    clinic_name = models.CharField(max_length=255, blank=True)
    clinic_address = models.CharField(max_length=500, blank=True)
    is_verified = models.BooleanField(default=False)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_vet_profile'

    def __str__(self):
        return f"VetProfile({self.user.username})"
