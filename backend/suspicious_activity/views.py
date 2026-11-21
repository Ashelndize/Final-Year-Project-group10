from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import SuspiciousActivityFlag
from .serializers import SuspiciousActivityFlagSerializer
from accounts.permissions import IsAuthority


class SuspiciousActivityFlagViewSet(viewsets.ModelViewSet):
    """
    Read-only for AUTHORITY/ADMIN. Outcome updates via /resolve/ action.
    Flags are never created via API — only by rule checks.
    """
    serializer_class = SuspiciousActivityFlagSerializer
    permission_classes = [permissions.IsAuthenticated, IsAuthority]
    http_method_names = ['get', 'head', 'options', 'post']  # post only via /resolve/ action
    filterset_fields = ['rule_key', 'status', 'actor']

    def get_queryset(self):
        return SuspiciousActivityFlag.objects.select_related('actor').all()

    def create(self, request, *args, **kwargs):
        return Response({'detail': 'Flags are created by rule checks only.'}, status=405)

    def update(self, request, *args, **kwargs):
        return Response({'detail': 'Use /resolve/ to update a flag.'}, status=405)

    def partial_update(self, request, *args, **kwargs):
        return Response({'detail': 'Use /resolve/ to update a flag.'}, status=405)

    def destroy(self, request, *args, **kwargs):
        return Response({'detail': 'Flags cannot be deleted.'}, status=405)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Update the status and outcome note of a flag."""
        flag = self.get_object()
        new_status = request.data.get('status')
        note = request.data.get('outcome_note', '').strip()
        allowed = ['REVIEWED_OK', 'ESCALATED', 'FALSE_POSITIVE', 'ACTION_TAKEN']
        if new_status not in allowed:
            return Response({'detail': f'status must be one of: {allowed}'}, status=400)
        if new_status == 'FALSE_POSITIVE' and not note:
            return Response({'detail': 'outcome_note is required for FALSE_POSITIVE.'}, status=400)
        flag.status = new_status
        flag.outcome_note = note
        flag.resolved_at = timezone.now()
        flag.save()
        return Response(SuspiciousActivityFlagSerializer(flag).data)
