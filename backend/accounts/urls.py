from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, CustomTokenObtainPairView, LogoutView,
    MeView, FarmerProfileView, VetProfileView, VetDirectoryView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='token-obtain'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('me/', MeView.as_view(), name='me'),
    path('farmer-profile/', FarmerProfileView.as_view(), name='farmer-profile'),
    path('vet-profile/', VetProfileView.as_view(), name='vet-profile'),
    path('vets/', VetDirectoryView.as_view(), name='vet-directory'),
]
