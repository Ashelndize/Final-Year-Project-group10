from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from accounts.permissions import IsSystemAdmin
from .models import AuditEvent
from .serializers import AuditEventSerializer


class AuditEventViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AuditEventSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['action', 'actor__username', 'target_type']
    ordering_fields = ['timestamp']

    def get_permissions(self):
        return [IsAuthenticated(), IsSystemAdmin()]

    def get_queryset(self):
        return AuditEvent.objects.all().select_related('actor')
