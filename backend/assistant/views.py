from datetime import date

from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import viewsets

from accounts.permissions import IsSystemAdmin
from .models import KBSource, AssistantInteraction
from .serializers import (
    AssistantQuestionSerializer,
    AssistantResponseSerializer,
    KBSourceSerializer,
)


ESCALATION_PATTERNS = [
    'sudden death', 'multiple deaths', 'dying fast', 'neurological', 'convulsion',
    'seizure', 'abortion storm', 'haemorrhage', 'hemorrhage', 'blood', 'rapid spread',
    'many animals', 'whole herd', 'notifiable',
]

INJECTION_PATTERNS = [
    'ignore', 'forget your instructions', 'you are now', 'pretend', 'roleplay',
    'bypass', 'reveal', 'your prompt', 'system prompt',
]

LIVESTOCK_KEYWORDS = [
    'cattle', 'cow', 'goat', 'sheep', 'pig', 'chicken', 'poultry', 'livestock',
    'animal', 'herd', 'flock', 'farm', 'disease', 'vaccine', 'vaccination',
    'symptom', 'feed', 'nutrition', 'parasite', 'worm', 'tick', 'mange',
    'diarrhoea', 'diarrhea', 'fever', 'cough', 'lame', 'weight loss', 'milk',
    'pregnancy', 'birth', 'calv', 'lamb', 'piglet', 'chick',
]


def _classify_question(question: str) -> str:
    lowered = question.lower()
    for pattern in INJECTION_PATTERNS:
        if pattern in lowered:
            return 'INSTRUCTION_INJECTION'
    for pattern in ESCALATION_PATTERNS:
        if pattern in lowered:
            return 'ESCALATION'
    for keyword in LIVESTOCK_KEYWORDS:
        if keyword in lowered:
            return 'IN_SCOPE'
    return 'OUT_OF_SCOPE'


class AssistantAskView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = AssistantQuestionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        question = serializer.validated_data['question']

        assistant_enabled = getattr(settings, 'ASSISTANT_ENABLED', False)

        if not assistant_enabled:
            interaction = AssistantInteraction.objects.create(
                user=request.user,
                question=question,
                answer=(
                    'The AI health assistant is currently unavailable. '
                    'For urgent health concerns, please request veterinary assistance.'
                    '\n\n[General information — not a diagnosis.]'
                ),
                answer_source='DISABLED',
                kb_version='none',
                escalation=False,
                safety_flags=[],
            )
            return Response(AssistantResponseSerializer(interaction).data, status=200)

        classification = _classify_question(question)

        answer = ''
        answer_source = 'FALLBACK_NONE'
        escalation = False
        safety_flags = []
        kb_version = 'none'

        if classification == 'INSTRUCTION_INJECTION':
            answer = 'I can only answer general livestock-health questions.'
            answer_source = 'REFUSED'
            safety_flags = ['instruction_injection']
            escalation = False

        elif classification == 'OUT_OF_SCOPE':
            answer = (
                'I can only provide general livestock-health information. '
                'For this question, please consult a qualified professional.'
            )
            answer_source = 'REFUSED'
            safety_flags = ['out_of_scope']

        elif classification == 'ESCALATION':
            answer = (
                'This sounds urgent. Please contact a veterinarian immediately '
                'or submit an assistance request through the app. '
                'Do not attempt to treat without professional guidance.'
            )
            answer_source = 'REFUSED'
            escalation = True
            safety_flags = ['escalation_trigger']

        else:  # IN_SCOPE
            today = date.today()
            active_sources = KBSource.objects.filter(
                is_active=True,
                review_due_at__gte=today,
            )
            count = active_sources.count()
            kb_version = str(count)

            if count == 0:
                answer = (
                    'No information is available on this topic in our knowledge base. '
                    'Please consult a veterinarian.'
                )
                answer_source = 'FALLBACK_NONE'
            else:
                lowered_q = question.lower()
                q_words = [w for w in lowered_q.split() if len(w) > 2]
                matched_source = None
                for source in active_sources:
                    haystack = (source.title + ' ' + source.content).lower()
                    if any(word in haystack for word in q_words):
                        matched_source = source
                        break

                if matched_source is None:
                    matched_source = active_sources.first()

                answer = matched_source.content
                answer_source = 'KB'

        answer = answer + '\n\n[General information — not a diagnosis.]'

        interaction = AssistantInteraction.objects.create(
            user=request.user,
            question=question,
            answer=answer,
            answer_source=answer_source,
            kb_version=kb_version,
            escalation=escalation,
            safety_flags=safety_flags,
        )

        return Response(AssistantResponseSerializer(interaction).data, status=200)


class KBSourceViewSet(viewsets.ModelViewSet):
    serializer_class = KBSourceSerializer
    permission_classes = [IsAuthenticated, IsSystemAdmin]
    queryset = KBSource.objects.all()
