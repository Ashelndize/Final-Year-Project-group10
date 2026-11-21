from django.contrib import admin
from .models import SuspiciousActivityFlag


@admin.register(SuspiciousActivityFlag)
class SuspiciousActivityFlagAdmin(admin.ModelAdmin):
    list_display = ['rule_key', 'actor', 'status', 'created_at', 'resolved_at']
    list_filter = ['rule_key', 'status']
