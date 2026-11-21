from rest_framework import serializers
from .models import SuspiciousActivityFlag


class SuspiciousActivityFlagSerializer(serializers.ModelSerializer):
    actor_username = serializers.SerializerMethodField()

    class Meta:
        model = SuspiciousActivityFlag
        fields = '__all__'
        read_only_fields = [
            'rule_key', 'explanation', 'actor', 'window_start', 'window_end',
            'evidence', 'rule_version', 'created_at', 'resolved_at',
        ]

    def get_actor_username(self, obj):
        return obj.actor.username if obj.actor else None
