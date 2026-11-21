from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DiseaseReportViewSet

router = DefaultRouter()
router.register('disease-reports', DiseaseReportViewSet, basename='disease-report')

urlpatterns = [
    path('', include(router.urls)),
]
