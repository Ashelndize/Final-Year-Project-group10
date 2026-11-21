from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import VetAssistanceRequestViewSet

router = DefaultRouter()
router.register('assistance-requests', VetAssistanceRequestViewSet, basename='assistance-request')

urlpatterns = [
    path('', include(router.urls)),
]
