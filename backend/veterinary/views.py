from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import VetAssistanceRequest
from .serializers import VetAssistanceRequestSerializer, VetAssistanceRequestUpdateSerializer
from accounts.permissions import IsFarmer, IsVet
from audit.models import AuditEvent


class VetAssistanceRequestViewSet(viewsets.ModelViewSet):
    """
    Farmers create assistance requests; vets respond.
    Farmers see only their own requests.
    Vets see requests assigned to them or unassigned pending requests.
    Admins see all.
    """
    serializer_class = VetAssistanceRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'ADMIN':
            return VetAssistanceRequest.objects.all()
        if user.role == 'VET':
            return VetAssistanceRequest.objects.filter(
                vet=user
            ) | VetAssistanceRequest.objects.filter(
                vet__isnull=True,
                status=VetAssistanceRequest.STATUS_PENDING,
            )
        # FARMER
        return VetAssistanceRequest.objects.filter(farmer=user)

    def get_serializer_class(self):
        if self.action == 'respond' or (
            self.action in ['update', 'partial_update']
            and self.request.user.role == 'VET'
        ):
            return VetAssistanceRequestUpdateSerializer
        return VetAssistanceRequestSerializer

    def perform_create(self, serializer):
        instance = serializer.save()
        AuditEvent.log(
            actor=self.request.user,
            action=AuditEvent.Action.CREATE,
            target_type='VetAssistanceRequest',
            target_id=instance.pk,
            description=f"Assistance request created for farm '{instance.farm.name}'",
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.farmer != request.user:
            return Response(
                {'detail': 'Only the requesting farmer can cancel this request.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if instance.status not in (
            VetAssistanceRequest.STATUS_PENDING,
            VetAssistanceRequest.STATUS_DECLINED,
        ):
            return Response(
                {'detail': 'Cannot delete an in-progress or completed request.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['patch'], permission_classes=[IsVet])
    def respond(self, request, pk=None):
        """Vets accept, decline, or complete a request."""
        instance = self.get_object()
        serializer = VetAssistanceRequestUpdateSerializer(
            instance, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        new_status = serializer.validated_data.get('status')
        if new_status in (
            VetAssistanceRequest.STATUS_ACCEPTED,
            VetAssistanceRequest.STATUS_DECLINED,
        ):
            serializer.validated_data['responded_at'] = timezone.now()
            if new_status == VetAssistanceRequest.STATUS_ACCEPTED:
                serializer.validated_data['vet'] = request.user
        serializer.save()
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='VetAssistanceRequest',
            target_id=instance.pk,
            description=f"Request #{instance.pk} status updated to {new_status}",
        )
        return Response(VetAssistanceRequestSerializer(instance, context={'request': request}).data)
