from django.contrib import admin
from .models import DiseaseReport


@admin.register(DiseaseReport)
class DiseaseReportAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'reporter', 'species', 'observation_date',
        'area_name', 'status', 'is_confirmed_outbreak', 'created_at',
    ]
    list_filter = ['status', 'species', 'is_confirmed_outbreak']
    search_fields = ['reporter__username', 'area_name', 'observed_signs']
    readonly_fields = ['created_at', 'updated_at']
    raw_id_fields = ['reporter', 'farm', 'area']

    def get_readonly_fields(self, request, obj=None):
        # is_confirmed_outbreak must only be set via the /confirm_outbreak/ action
        # Make it read-only in admin to prevent accidental direct editing
        base = list(super().get_readonly_fields(request, obj))
        if not request.user.is_superuser:
            base.append('is_confirmed_outbreak')
        return base
