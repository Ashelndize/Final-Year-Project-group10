from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from .models import HealthRecord, TreatmentRecord, VaccinationProtocol, VaccinationRecord, VaccinationSchedule
from .serializers import (
    HealthRecordSerializer, TreatmentRecordSerializer,
    VaccinationProtocolSerializer, VaccinationRecordSerializer, VaccinationScheduleSerializer,
)


class HealthRecordViewSet(viewsets.ModelViewSet):
    serializer_class = HealthRecordSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['animal__tag_number', 'health_status', 'symptoms']
    ordering_fields = ['record_date', 'created_at']

    def get_queryset(self):
        user = self.request.user
        if user.is_system_admin:
            return HealthRecord.objects.all().select_related('animal', 'recorded_by')
        if user.is_vet:
            return (
                HealthRecord.objects.filter(animal__farm__owner=user).select_related('animal', 'recorded_by') |
                HealthRecord.objects.filter(recorded_by=user).select_related('animal', 'recorded_by')
            )
        return HealthRecord.objects.filter(
            animal__farm__owner=user
        ).select_related('animal', 'recorded_by')


class TreatmentRecordViewSet(viewsets.ModelViewSet):
    serializer_class = TreatmentRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_system_admin:
            return TreatmentRecord.objects.all().select_related('health_record__animal')
        return TreatmentRecord.objects.filter(
            health_record__animal__farm__owner=user
        ).select_related('health_record__animal')


class VaccinationProtocolViewSet(viewsets.ModelViewSet):
    queryset = VaccinationProtocol.objects.filter(is_active=True)
    serializer_class = VaccinationProtocolSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'species', 'vaccine_name']

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            from accounts.permissions import IsSystemAdmin
            return [IsAuthenticated(), IsSystemAdmin()]
        return [IsAuthenticated()]


class VaccinationRecordViewSet(viewsets.ModelViewSet):
    serializer_class = VaccinationRecordSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['animal__tag_number', 'lot_number']
    ordering_fields = ['vaccination_date']

    def get_queryset(self):
        user = self.request.user
        if user.is_system_admin:
            return VaccinationRecord.objects.all().select_related('animal', 'protocol')
        return VaccinationRecord.objects.filter(
            animal__farm__owner=user
        ).select_related('animal', 'protocol')


class VaccinationScheduleViewSet(viewsets.ModelViewSet):
    serializer_class = VaccinationScheduleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['animal__tag_number', 'status']
    ordering_fields = ['due_date', 'status']

    def get_queryset(self):
        user = self.request.user
        if user.is_system_admin:
            return VaccinationSchedule.objects.all().select_related('animal', 'protocol')
        return VaccinationSchedule.objects.filter(
            animal__farm__owner=user
        ).select_related('animal', 'protocol')
