from django.conf import settings
from django.db import models
from animals.models import Animal


class HealthRecord(models.Model):
    class Status(models.TextChoices):
        HEALTHY = 'HEALTHY', 'Healthy'
        SICK = 'SICK', 'Sick'
        UNDER_TREATMENT = 'UNDER_TREATMENT', 'Under Treatment'
        RECOVERED = 'RECOVERED', 'Recovered'
        DECEASED = 'DECEASED', 'Deceased'

    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='health_records')
    recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                    null=True, related_name='health_records_recorded')
    record_date = models.DateField()
    weight_kg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    temperature_c = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    health_status = models.CharField(max_length=20, choices=Status.choices, default=Status.HEALTHY)
    symptoms = models.TextField(blank=True)
    diagnosis = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'health_record'
        ordering = ['-record_date', '-created_at']

    def __str__(self):
        return f"HealthRecord({self.animal.tag_number}, {self.record_date})"


class TreatmentRecord(models.Model):
    health_record = models.ForeignKey(HealthRecord, on_delete=models.CASCADE, related_name='treatments')
    drug_name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=255, blank=True)
    route = models.CharField(max_length=100, blank=True)
    duration_days = models.PositiveIntegerField(null=True, blank=True)
    administered_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                        null=True, related_name='treatments_administered')
    treatment_date = models.DateField()
    outcome = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'health_treatment_record'
        ordering = ['-treatment_date']

    def __str__(self):
        return f"Treatment({self.drug_name}, {self.health_record.animal.tag_number})"


class VaccinationProtocol(models.Model):
    name = models.CharField(max_length=255, unique=True)
    species = models.CharField(max_length=20, choices=[
        ('CATTLE', 'Cattle'), ('GOAT', 'Goat'), ('SHEEP', 'Sheep'),
        ('POULTRY', 'Poultry'), ('PIG', 'Pig'), ('ALL', 'All Species'),
    ])
    vaccine_name = models.CharField(max_length=255)
    doses_required = models.PositiveIntegerField(default=1)
    interval_days = models.PositiveIntegerField(default=365)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'health_vaccination_protocol'

    def __str__(self):
        return f"{self.name} ({self.species})"


class VaccinationRecord(models.Model):
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='vaccination_records')
    protocol = models.ForeignKey(VaccinationProtocol, on_delete=models.SET_NULL,
                                 null=True, related_name='vaccination_records')
    administered_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                        null=True, related_name='vaccinations_administered')
    vaccination_date = models.DateField()
    lot_number = models.CharField(max_length=100, blank=True)
    next_due_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'health_vaccination_record'
        ordering = ['-vaccination_date']

    def __str__(self):
        return f"Vaccination({self.animal.tag_number}, {self.vaccination_date})"


class VaccinationSchedule(models.Model):
    class ScheduleStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        COMPLETED = 'COMPLETED', 'Completed'
        OVERDUE = 'OVERDUE', 'Overdue'
        SKIPPED = 'SKIPPED', 'Skipped'

    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='vaccination_schedules')
    protocol = models.ForeignKey(VaccinationProtocol, on_delete=models.CASCADE,
                                 related_name='schedules')
    due_date = models.DateField()
    status = models.CharField(max_length=20, choices=ScheduleStatus.choices,
                              default=ScheduleStatus.PENDING)
    vaccination_record = models.OneToOneField(VaccinationRecord, on_delete=models.SET_NULL,
                                              null=True, blank=True, related_name='schedule')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'health_vaccination_schedule'
        ordering = ['due_date']

    def __str__(self):
        return f"Schedule({self.animal.tag_number}, {self.protocol.name}, {self.due_date})"
