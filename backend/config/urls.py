"""
URL configuration for Smart Livestock Health and Farm Management System.
"""

from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include('health_check.urls')),
    path('api/v1/auth/', include('accounts.urls')),
    path('api/v1/', include('farms.urls')),
    path('api/v1/', include('animals.urls')),
    path('api/v1/', include('health.urls')),
    path('api/v1/', include('notifications.urls')),
    path('api/v1/', include('audit.urls')),
    path('api/v1/', include('veterinary.urls')),
    path('api/v1/', include('reports.urls')),
    path('api/v1/', include('announcements.urls')),
    path('api/v1/', include('assistant.urls')),
    path('api/v1/', include('suspicious_activity.urls')),
    path('authority/', include('dashboard.urls', namespace='dashboard')),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
