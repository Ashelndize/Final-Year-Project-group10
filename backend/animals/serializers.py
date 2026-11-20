from rest_framework import serializers
from .models import Animal


class AnimalSerializer(serializers.ModelSerializer):
    farm_name = serializers.CharField(source='farm.name', read_only=True)

    class Meta:
        model = Animal
        fields = ('id', 'farm', 'farm_name', 'tag_number', 'name', 'species', 'breed',
                  'sex', 'date_of_birth', 'weight_kg', 'status', 'notes', 'created_at', 'updated_at')
        read_only_fields = ('id', 'created_at', 'updated_at')

    def validate_farm(self, farm):
        user = self.context['request'].user
        if not user.is_system_admin and farm.owner != user:
            raise serializers.ValidationError('You do not own this farm.')
        return farm
