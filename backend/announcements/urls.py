from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OfficialAnnouncementViewSet

router = DefaultRouter()
router.register('announcements', OfficialAnnouncementViewSet, basename='announcement')

urlpatterns = [
    path('', include(router.urls)),
]
