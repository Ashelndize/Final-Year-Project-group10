from django.contrib import admin
from .models import KBSource, AssistantInteraction


@admin.register(KBSource)
class KBSourceAdmin(admin.ModelAdmin):
    list_display = ['title', 'publisher', 'is_active', 'review_due_at']


@admin.register(AssistantInteraction)
class AssistantInteractionAdmin(admin.ModelAdmin):
    list_display = ['user', 'answer_source', 'escalation', 'created_at']
    readonly_fields = [
        'user',
        'question',
        'answer',
        'answer_source',
        'kb_version',
        'escalation',
        'safety_flags',
        'created_at',
    ]
