from django.contrib import admin
from .models import AuditEvent


@admin.register(AuditEvent)
class AuditEventAdmin(admin.ModelAdmin):
    list_display = ('actor', 'action', 'target_type', 'target_id', 'timestamp')
    list_filter = ('action',)
    search_fields = ('actor__username', 'action', 'target_type')
    readonly_fields = ('actor', 'action', 'target_type', 'target_id', 'description', 'ip_address', 'timestamp')
