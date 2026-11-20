from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import CustomUser, FarmerProfile, VetProfile


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ('username', 'email', 'first_name', 'last_name', 'phone', 'role', 'password', 'password2')
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password2'):
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        role = attrs.get('role', CustomUser.Role.FARMER)
        if role not in (CustomUser.Role.FARMER, CustomUser.Role.VET):
            raise serializers.ValidationError({'role': 'Self-registration is only allowed for Farmer or Veterinarian roles.'})
        return attrs

    def create(self, validated_data):
        user = CustomUser.objects.create_user(**validated_data)
        if user.role == CustomUser.Role.FARMER:
            FarmerProfile.objects.create(user=user)
        elif user.role == CustomUser.Role.VET:
            VetProfile.objects.create(user=user)
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        token['username'] = user.username
        return token


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone', 'role', 'created_at')
        read_only_fields = ('id', 'username', 'role', 'created_at')


class FarmerProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = FarmerProfile
        fields = ('id', 'user', 'location', 'bio', 'created_at', 'updated_at')
        read_only_fields = ('id', 'user', 'created_at', 'updated_at')


class VetProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = VetProfile
        fields = ('id', 'user', 'license_number', 'specialization', 'clinic_name',
                  'clinic_address', 'is_verified', 'latitude', 'longitude', 'created_at', 'updated_at')
        read_only_fields = ('id', 'user', 'is_verified', 'created_at', 'updated_at')
