from django.contrib import admin
from .models import OfficialAnnouncement


@admin.register(OfficialAnnouncement)
class OfficialAnnouncementAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'title', 'announcement_type', 'status',
        'issuing_authority', 'published_at', 'expires_at', 'created_at',
    ]
    list_filter = ['status', 'announcement_type', 'affected_species']
    search_fields = ['title', 'content', 'affected_area_name']
    readonly_fields = ['created_at', 'updated_at', 'published_at', 'withdrawn_at']
    raw_id_fields = ['issuing_authority', 'affected_area']
    filter_horizontal = ['related_reports']
