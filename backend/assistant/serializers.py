from rest_framework import serializers
from .models import AssistantInteraction, KBSource


class AssistantQuestionSerializer(serializers.Serializer):
    question = serializers.CharField(max_length=1000)

    def validate_question(self, value):
        if not value.strip():
            raise serializers.ValidationError("Question must not be empty.")
        return value


class AssistantResponseSerializer(serializers.ModelSerializer):
    disclaimer = serializers.SerializerMethodField()

    class Meta:
        model = AssistantInteraction
        fields = [
            'id',
            'answer',
            'answer_source',
            'kb_version',
            'escalation',
            'safety_flags',
            'created_at',
            'disclaimer',
        ]

    def get_disclaimer(self, obj):
        return "General information — not a diagnosis."


class KBSourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = KBSource
        fields = '__all__'
