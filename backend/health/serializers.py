from rest_framework import serializers
from .models import HealthRecord, TreatmentRecord, VaccinationProtocol, VaccinationRecord, VaccinationSchedule


class TreatmentRecordSerializer(serializers.ModelSerializer):
    administered_by_username = serializers.CharField(source='administered_by.username', read_only=True)

    class Meta:
        model = TreatmentRecord
        fields = ('id', 'health_record', 'drug_name', 'dosage', 'route', 'duration_days',
                  'administered_by', 'administered_by_username', 'treatment_date', 'outcome', 'created_at')
        read_only_fields = ('id', 'administered_by', 'created_at')

    def create(self, validated_data):
        validated_data['administered_by'] = self.context['request'].user
        return super().create(validated_data)


class HealthRecordSerializer(serializers.ModelSerializer):
    recorded_by_username = serializers.CharField(source='recorded_by.username', read_only=True)
    animal_tag = serializers.CharField(source='animal.tag_number', read_only=True)
    treatments = TreatmentRecordSerializer(many=True, read_only=True)

    class Meta:
        model = HealthRecord
        fields = ('id', 'animal', 'animal_tag', 'recorded_by', 'recorded_by_username',
                  'record_date', 'weight_kg', 'temperature_c', 'health_status',
                  'symptoms', 'diagnosis', 'notes', 'treatments', 'created_at', 'updated_at')
        read_only_fields = ('id', 'recorded_by', 'recorded_by_username', 'created_at', 'updated_at')

    def validate_animal(self, animal):
        user = self.context['request'].user
        if not user.is_system_admin and not user.is_vet and animal.farm.owner != user:
            raise serializers.ValidationError('You do not have access to this animal.')
        return animal

    def create(self, validated_data):
        validated_data['recorded_by'] = self.context['request'].user
        return super().create(validated_data)


class VaccinationProtocolSerializer(serializers.ModelSerializer):
    class Meta:
        model = VaccinationProtocol
        fields = ('id', 'name', 'species', 'vaccine_name', 'doses_required',
                  'interval_days', 'description', 'is_active', 'created_at')
        read_only_fields = ('id', 'created_at')


class VaccinationRecordSerializer(serializers.ModelSerializer):
    administered_by_username = serializers.CharField(source='administered_by.username', read_only=True)
    animal_tag = serializers.CharField(source='animal.tag_number', read_only=True)
    protocol_name = serializers.CharField(source='protocol.name', read_only=True)

    class Meta:
        model = VaccinationRecord
        fields = ('id', 'animal', 'animal_tag', 'protocol', 'protocol_name',
                  'administered_by', 'administered_by_username', 'vaccination_date',
                  'lot_number', 'next_due_date', 'notes', 'created_at')
        read_only_fields = ('id', 'administered_by', 'created_at')

    def create(self, validated_data):
        validated_data['administered_by'] = self.context['request'].user
        return super().create(validated_data)


class VaccinationScheduleSerializer(serializers.ModelSerializer):
    animal_tag = serializers.CharField(source='animal.tag_number', read_only=True)
    protocol_name = serializers.CharField(source='protocol.name', read_only=True)

    class Meta:
        model = VaccinationSchedule
        fields = ('id', 'animal', 'animal_tag', 'protocol', 'protocol_name',
                  'due_date', 'status', 'vaccination_record', 'created_at', 'updated_at')
        read_only_fields = ('id', 'created_at', 'updated_at')
