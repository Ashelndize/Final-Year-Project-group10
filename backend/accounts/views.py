from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import FarmerProfile, VetProfile
from .serializers import (
    RegisterSerializer, CustomTokenObtainPairSerializer,
    UserSerializer, FarmerProfileSerializer, VetProfileSerializer,
    PasswordResetRequestSerializer, PasswordResetConfirmSerializer,
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if not refresh_token:
                return Response({'detail': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'detail': 'Successfully logged out.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'detail': 'Invalid or expired token.'}, status=status.HTTP_400_BAD_REQUEST)


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class FarmerProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = FarmerProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        profile, _ = FarmerProfile.objects.get_or_create(user=self.request.user)
        return profile


class VetProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = VetProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        profile, _ = VetProfile.objects.get_or_create(user=self.request.user)
        return profile


class VetDirectoryView(generics.ListAPIView):
    """Public list of verified veterinarians."""
    serializer_class = VetProfileSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return VetProfile.objects.filter(is_verified=True).select_related('user')


class PasswordResetRequestView(APIView):
    """
    POST { "contact": "<phone_or_email>" }

    Always returns 200 (to avoid enumeration).
    In development (EMAIL_BACKEND=console), the OTP is also included in the
    response under "dev_token" so the app can be tested without a mail server.
    In production remove dev_token from the response and configure SMTP.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reset_token = serializer.save()

        response_data = {
            'detail': 'If an account matches that phone number or email, a reset code has been sent.',
        }

        # Include token in response when email backend is console (dev only).
        using_console_email = getattr(settings, 'EMAIL_BACKEND', '') == \
            'django.core.mail.backends.console.EmailBackend'
        if reset_token is not None and using_console_email:
            response_data['dev_token'] = reset_token.token
            response_data['dev_note'] = (
                'Email delivery is not configured. '
                'Use this code to reset your password (expires in 15 minutes).'
            )

        return Response(response_data, status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    """
    POST { "token": "123456", "new_password": "...", "new_password2": "..." }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'detail': 'Password has been reset successfully.'}, status=status.HTTP_200_OK)
