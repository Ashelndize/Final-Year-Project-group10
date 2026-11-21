from rest_framework import serializers
from .models import VetAssistanceRequest


class VetAssistanceRequestSerializer(serializers.ModelSerializer):
    farmer_username = serializers.CharField(source='farmer.username', read_only=True)
    vet_username = serializers.CharField(source='vet.username', read_only=True, allow_null=True)
    farm_name = serializers.CharField(source='farm.name', read_only=True)
    animal_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = VetAssistanceRequest
        fields = [
            'id', 'farmer', 'farmer_username',
            'vet', 'vet_username',
            'farm', 'farm_name',
            'animal', 'animal_name',
            'description', 'status', 'status_display',
            'farmer_latitude', 'farmer_longitude',
            'area_name', 'location_consent',
            'vet_notes', 'created_at', 'updated_at', 'responded_at',
        ]
        read_only_fields = [
            'id', 'farmer', 'farmer_username', 'vet_username',
            'farm_name', 'animal_name', 'status_display',
            'created_at', 'updated_at',
        ]

    def get_animal_name(self, obj):
        if obj.animal:
            return obj.animal.name or obj.animal.tag_number
        return None

    def validate(self, attrs):
        request = self.context['request']
        user = request.user
        # Only farmers can create requests
        if self.instance is None and user.role != 'FARMER':
            raise serializers.ValidationError("Only farmers can create assistance requests.")
        # Validate farm ownership
        farm = attrs.get('farm')
        if farm and farm.owner != user:
            raise serializers.ValidationError("You can only request assistance for your own farms.")
        # Strip location if no consent
        if not attrs.get('location_consent', False):
            attrs['farmer_latitude'] = None
            attrs['farmer_longitude'] = None
        return attrs

    def create(self, validated_data):
        validated_data['farmer'] = self.context['request'].user
        return super().create(validated_data)


class VetAssistanceRequestUpdateSerializer(serializers.ModelSerializer):
    """Used by vets to update status and add notes."""

    class Meta:
        model = VetAssistanceRequest
        fields = ['status', 'vet_notes', 'responded_at']

    def validate_status(self, value):
        allowed = [
            VetAssistanceRequest.STATUS_ACCEPTED,
            VetAssistanceRequest.STATUS_IN_PROGRESS,
            VetAssistanceRequest.STATUS_COMPLETED,
            VetAssistanceRequest.STATUS_DECLINED,
        ]
        if value not in allowed:
            raise serializers.ValidationError(
                f"Vets can only set status to: {', '.join(allowed)}"
            )
        return value
