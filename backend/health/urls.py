from rest_framework.routers import DefaultRouter
from .views import (
    HealthRecordViewSet, TreatmentRecordViewSet, VaccinationProtocolViewSet,
    VaccinationRecordViewSet, VaccinationScheduleViewSet,
)

router = DefaultRouter()
router.register(r'health-records', HealthRecordViewSet, basename='health-record')
router.register(r'treatment-records', TreatmentRecordViewSet, basename='treatment-record')
router.register(r'vaccination-protocols', VaccinationProtocolViewSet, basename='vaccination-protocol')
router.register(r'vaccination-records', VaccinationRecordViewSet, basename='vaccination-record')
router.register(r'vaccination-schedules', VaccinationScheduleViewSet, basename='vaccination-schedule')

urlpatterns = router.urls
