from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import DiseaseReport
from .serializers import DiseaseReportSerializer
from accounts.permissions import IsAuthority
from audit.models import AuditEvent


class DiseaseReportViewSet(viewsets.ModelViewSet):
    """
    Farmers and vets can submit disease reports.
    AUTHORITY users can review and update status.
    is_confirmed_outbreak can only be set by AUTHORITY via /confirm_outbreak/ action.
    """
    serializer_class = DiseaseReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'species']
    search_fields = ['area_name', 'observed_signs', 'notes']

    def get_queryset(self):
        user = self.request.user
        if user.role in ('ADMIN', 'AUTHORITY'):
            return DiseaseReport.objects.all()
        return DiseaseReport.objects.filter(reporter=user)

    def perform_create(self, serializer):
        instance = serializer.save()
        AuditEvent.log(
            actor=self.request.user,
            action=AuditEvent.Action.CREATE,
            target_type='DiseaseReport',
            target_id=instance.pk,
            description=f"Disease report #{instance.pk} submitted for species {instance.species}",
        )

    def perform_update(self, serializer):
        instance = serializer.save()
        AuditEvent.log(
            actor=self.request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
            target_id=instance.pk,
            description=f"Disease report #{instance.pk} updated — status: {instance.status}",
        )

    def update(self, request, *args, **kwargs):
        # Reporters can only edit their own SUBMITTED reports
        instance = self.get_object()
        if request.user.role not in ('ADMIN', 'AUTHORITY'):
            if instance.reporter != request.user:
                return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
            if instance.status != DiseaseReport.STATUS_SUBMITTED:
                return Response(
                    {'detail': 'You can only edit a report while it is in SUBMITTED status.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        return super().update(request, *args, **kwargs)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthority])
    def review(self, request, pk=None):
        """AUTHORITY sets report status (but NOT is_confirmed_outbreak here)."""
        instance = self.get_object()
        new_status = request.data.get('status')
        allowed_statuses = [
            DiseaseReport.STATUS_UNDER_REVIEW,
            DiseaseReport.STATUS_ACCEPTED,
            DiseaseReport.STATUS_REJECTED,
            DiseaseReport.STATUS_CLOSED,
        ]
        if new_status not in allowed_statuses:
            return Response(
                {'detail': f"Status must be one of: {', '.join(allowed_statuses)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        instance.status = new_status
        instance.save(update_fields=['status', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
            target_id=instance.pk,
            description=f"Report #{instance.pk} status set to {new_status} by authority reviewer",
        )
        return Response(DiseaseReportSerializer(instance, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthority])
    def confirm_outbreak(self, request, pk=None):
        """
        AUTHORITY only — explicitly confirms this report as a confirmed outbreak.
        This must always be a deliberate human decision — never automated.
        """
        instance = self.get_object()
        if instance.status != DiseaseReport.STATUS_ACCEPTED:
            return Response(
                {'detail': 'Report must be in ACCEPTED_FOR_ASSESSMENT status before confirming an outbreak.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        instance.is_confirmed_outbreak = True
        instance.status = DiseaseReport.STATUS_CLOSED
        instance.save(update_fields=['is_confirmed_outbreak', 'status', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
            target_id=instance.pk,
            description=f"Report #{instance.pk} confirmed as outbreak by {request.user.username}",
        )
        return Response(DiseaseReportSerializer(instance, context={'request': request}).data)
