from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import OfficialAnnouncement
from .serializers import OfficialAnnouncementSerializer
from accounts.permissions import IsAuthority
from audit.models import AuditEvent
from notifications.models import Notification
from accounts.models import CustomUser


class OfficialAnnouncementViewSet(viewsets.ModelViewSet):
    """
    Public can read published announcements.
    AUTHORITY/ADMIN can create, edit, publish, and withdraw.
    Only AUTHORITY/ADMIN can publish — never automated.
    """
    serializer_class = OfficialAnnouncementSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.IsAuthenticated()]
        return [permissions.IsAuthenticated(), IsAuthority()]

    def get_queryset(self):
        user = self.request.user
        if user.role in ('AUTHORITY', 'ADMIN'):
            return OfficialAnnouncement.objects.all()
        # Farmers and vets only see published announcements meant for them
        base = OfficialAnnouncement.objects.filter(status=OfficialAnnouncement.STATUS_PUBLISHED)
        if user.role == 'VET':
            return base.filter(
                target_audience__in=[
                    OfficialAnnouncement.AUDIENCE_ALL,
                    OfficialAnnouncement.AUDIENCE_VETS,
                ]
            )
        # FARMER (and any other authenticated role)
        return base.filter(
            target_audience__in=[
                OfficialAnnouncement.AUDIENCE_ALL,
                OfficialAnnouncement.AUDIENCE_FARMERS,
            ]
        )

    def perform_create(self, serializer):
        instance = serializer.save(issuing_authority=self.request.user)
        AuditEvent.log(
            actor=self.request.user,
            action=AuditEvent.Action.CREATE,
            target_type='OfficialAnnouncement',
            target_id=instance.pk,
            description=f"Announcement draft created: '{instance.title}'",
        )

    @action(detail=True, methods=['post'], permission_classes=[IsAuthority])
    def publish(self, request, pk=None):
        """
        Publishes the announcement. This action requires a deliberate human request
        from an AUTHORITY user — it is never triggered automatically.
        """
        instance = self.get_object()
        if instance.status == OfficialAnnouncement.STATUS_PUBLISHED:
            return Response({'detail': 'Already published.'}, status=status.HTTP_400_BAD_REQUEST)
        if instance.status == OfficialAnnouncement.STATUS_WITHDRAWN:
            return Response(
                {'detail': 'Withdrawn announcements cannot be re-published.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        instance.status = OfficialAnnouncement.STATUS_PUBLISHED
        instance.published_at = timezone.now()
        instance.save(update_fields=['status', 'published_at', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
            target_id=instance.pk,
            description=f"Announcement #{instance.pk} '{instance.title}' published by {request.user.username}",
        )
        # Notify all farmers and vets
        self._notify_users(instance)
        return Response(OfficialAnnouncementSerializer(instance, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthority])
    def withdraw(self, request, pk=None):
        """Withdraws a published announcement. Requires a reason."""
        instance = self.get_object()
        if instance.status != OfficialAnnouncement.STATUS_PUBLISHED:
            return Response(
                {'detail': 'Only published announcements can be withdrawn.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        reason = request.data.get('reason', '').strip()
        if not reason:
            return Response(
                {'detail': 'A withdrawal reason is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        instance.status = OfficialAnnouncement.STATUS_WITHDRAWN
        instance.withdrawn_at = timezone.now()
        instance.withdrawal_reason = reason
        instance.save(update_fields=['status', 'withdrawn_at', 'withdrawal_reason', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
            target_id=instance.pk,
            description=f"Announcement #{instance.pk} withdrawn by {request.user.username}. Reason: {reason}",
        )
        return Response(OfficialAnnouncementSerializer(instance, context={'request': request}).data)

    def _notify_users(self, announcement):
        """Creates in-app notifications filtered by the announcement's target_audience."""
        audience = announcement.target_audience
        if audience == OfficialAnnouncement.AUDIENCE_FARMERS:
            role_filter = ['FARMER']
        elif audience == OfficialAnnouncement.AUDIENCE_VETS:
            role_filter = ['VET']
        else:
            role_filter = ['FARMER', 'VET']
        recipients = CustomUser.objects.filter(role__in=role_filter, is_active=True)
        notifications = [
            Notification(
                recipient=user,
                notification_type='ANNOUNCEMENT',
                title=f"Official: {announcement.title}",
                body=(
                    f"A new official announcement has been published by "
                    f"{announcement.issuing_authority.username}. "
                    f"Type: {announcement.get_announcement_type_display()}."
                ),
            )
            for user in recipients
        ]
        Notification.objects.bulk_create(notifications)
