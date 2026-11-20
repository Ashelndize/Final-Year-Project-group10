from rest_framework import serializers
from .models import Area, Farm


class AreaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Area
        fields = ('id', 'name', 'province', 'country', 'created_at')
        read_only_fields = ('id', 'created_at')


class FarmSerializer(serializers.ModelSerializer):
    owner_username = serializers.CharField(source='owner.username', read_only=True)
    area_name = serializers.CharField(source='area.name', read_only=True)

    class Meta:
        model = Farm
        fields = ('id', 'name', 'farm_type', 'area', 'area_name', 'address',
                  'status', 'notes', 'owner', 'owner_username', 'created_at', 'updated_at')
        read_only_fields = ('id', 'owner', 'owner_username', 'created_at', 'updated_at')

    def create(self, validated_data):
        validated_data['owner'] = self.context['request'].user
        return super().create(validated_data)
