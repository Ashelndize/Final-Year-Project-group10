from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SuspiciousActivityFlagViewSet

router = DefaultRouter()
router.register('suspicious-flags', SuspiciousActivityFlagViewSet, basename='suspicious-flag')

urlpatterns = [
    path('', include(router.urls)),
]
