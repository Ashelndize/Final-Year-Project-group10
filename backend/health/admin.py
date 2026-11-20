from django.contrib import admin
from .models import HealthRecord, TreatmentRecord, VaccinationProtocol, VaccinationRecord, VaccinationSchedule


@admin.register(HealthRecord)
class HealthRecordAdmin(admin.ModelAdmin):
    list_display = ('animal', 'record_date', 'health_status', 'recorded_by')
    list_filter = ('health_status',)


@admin.register(TreatmentRecord)
class TreatmentRecordAdmin(admin.ModelAdmin):
    list_display = ('health_record', 'drug_name', 'treatment_date', 'administered_by')


@admin.register(VaccinationProtocol)
class VaccinationProtocolAdmin(admin.ModelAdmin):
    list_display = ('name', 'species', 'vaccine_name', 'interval_days', 'is_active')


@admin.register(VaccinationRecord)
class VaccinationRecordAdmin(admin.ModelAdmin):
    list_display = ('animal', 'protocol', 'vaccination_date', 'next_due_date')


@admin.register(VaccinationSchedule)
class VaccinationScheduleAdmin(admin.ModelAdmin):
    list_display = ('animal', 'protocol', 'due_date', 'status')
    list_filter = ('status',)
