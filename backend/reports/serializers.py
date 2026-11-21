from rest_framework import serializers
from .models import DiseaseReport


class DiseaseReportSerializer(serializers.ModelSerializer):
    reporter_username = serializers.CharField(source='reporter.username', read_only=True)
    farm_name = serializers.CharField(source='farm.name', read_only=True, allow_null=True)
    area_display = serializers.CharField(source='area.name', read_only=True, allow_null=True)
    species_display = serializers.CharField(source='get_species_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DiseaseReport
        fields = [
            'id', 'reporter', 'reporter_username',
            'farm', 'farm_name',
            'species', 'species_display',
            'observation_date',
            'area', 'area_display', 'area_name',
            'observed_signs', 'notes',
            'status', 'status_display',
            'is_confirmed_outbreak',
            'report_latitude', 'report_longitude', 'location_consent',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'reporter', 'reporter_username',
            'farm_name', 'area_display',
            'species_display', 'status_display',
            'is_confirmed_outbreak',  # only AUTHORITY can change via separate action
            'created_at', 'updated_at',
        ]

    def validate(self, attrs):
        # Strip location coordinates if no consent given
        if not attrs.get('location_consent', False):
            attrs['report_latitude'] = None
            attrs['report_longitude'] = None
        # Ensure at least area_name or area FK is provided
        if not attrs.get('area') and not attrs.get('area_name', '').strip():
            raise serializers.ValidationError(
                "Provide either an area selection or a free-text area name."
            )
        return attrs

    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        return super().create(validated_data)
