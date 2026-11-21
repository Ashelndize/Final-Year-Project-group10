from django.contrib import admin
from .models import VetAssistanceRequest


@admin.register(VetAssistanceRequest)
class VetAssistanceRequestAdmin(admin.ModelAdmin):
    list_display = ['id', 'farmer', 'vet', 'farm', 'status', 'location_consent', 'created_at']
    list_filter = ['status', 'location_consent']
    search_fields = ['farmer__username', 'vet__username', 'farm__name', 'description']
    readonly_fields = ['created_at', 'updated_at']
    raw_id_fields = ['farmer', 'vet', 'farm', 'animal']
