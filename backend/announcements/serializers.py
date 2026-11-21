from rest_framework import serializers
from .models import OfficialAnnouncement


class OfficialAnnouncementSerializer(serializers.ModelSerializer):
    issuing_authority_username = serializers.CharField(
        source='issuing_authority.username', read_only=True
    )
    issuing_authority_name = serializers.SerializerMethodField()
    announcement_type_display = serializers.CharField(
        source='get_announcement_type_display', read_only=True
    )
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    affected_area_display = serializers.CharField(
        source='affected_area.name', read_only=True, allow_null=True
    )
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = OfficialAnnouncement
        fields = [
            'id', 'title', 'announcement_type', 'announcement_type_display',
            'content', 'prevention_guidance',
            'issuing_authority', 'issuing_authority_username', 'issuing_authority_name',
            'affected_area', 'affected_area_display', 'affected_area_name',
            'affected_species',
            'status', 'status_display', 'is_active',
            'published_at', 'expires_at', 'withdrawn_at', 'withdrawal_reason',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'issuing_authority', 'issuing_authority_username', 'issuing_authority_name',
            'announcement_type_display', 'status_display', 'is_active',
            'published_at', 'withdrawn_at', 'created_at', 'updated_at',
        ]

    def get_issuing_authority_name(self, obj):
        u = obj.issuing_authority
        full = f"{u.first_name} {u.last_name}".strip()
        return full if full else u.username
