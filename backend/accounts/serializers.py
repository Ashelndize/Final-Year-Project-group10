from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import CustomUser, FarmerProfile, VetProfile, PasswordResetToken
from audit.models import AuditEvent


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ('username', 'email', 'first_name', 'last_name', 'phone', 'role', 'password', 'password2')
        extra_kwargs = {
            # Phone is the primary contact — required for registration.
            'phone': {'required': True},
            # Email is optional (users may not have one).
            'email': {'required': False, 'allow_blank': True, 'default': ''},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }

    def validate_phone(self, value):
        """Normalise and enforce minimum length."""
        import re
        digits = re.sub(r'\D', '', value)
        if len(digits) < 9:
            raise serializers.ValidationError('Enter a valid phone number (at least 9 digits).')
        # Check uniqueness manually (the model enforces it too, but a friendly
        # error here beats a database IntegrityError).
        if CustomUser.objects.filter(phone=value).exists():
            raise serializers.ValidationError('A user with this phone number already exists.')
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password2'):
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        role = attrs.get('role', CustomUser.Role.FARMER)
        if role not in (CustomUser.Role.FARMER, CustomUser.Role.VET):
            raise serializers.ValidationError(
                {'role': 'Self-registration is only allowed for Farmer or Veterinarian roles.'}
            )
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

    def validate(self, attrs):
        data = super().validate(attrs)
        # JWT login does not fire django.contrib.auth.signals.user_logged_in,
        # so we create the audit event explicitly here.
        AuditEvent.log(
            actor=self.user,
            action=AuditEvent.Action.LOGIN_SUCCESS,
            target_type='User',
            target_id=self.user.pk,
            description=f'User {self.user.username} logged in via JWT.',
        )
        return data


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


class PasswordResetRequestSerializer(serializers.Serializer):
    """
    Accepts either an email address or a phone number under the ``contact`` key.
    Returns silently if no matching account is found (avoids enumeration).
    """
    contact = serializers.CharField(max_length=255)

    def validate_contact(self, value):
        import re
        value = value.strip()
        user = None

        if '@' in value:
            # Looks like an email — validate format then look up.
            from django.core.validators import validate_email as _validate_email
            from django.core.exceptions import ValidationError as DjangoValidationError
            try:
                _validate_email(value)
            except DjangoValidationError:
                raise serializers.ValidationError('Enter a valid email address.')
            try:
                user = CustomUser.objects.get(email__iexact=value)
            except CustomUser.DoesNotExist:
                user = None
        else:
            # Treat as phone — normalise and look up.
            digits = re.sub(r'\D', '', value)
            if len(digits) < 9:
                raise serializers.ValidationError(
                    'Enter a valid phone number or email address.'
                )
            # Match stored phone numbers by digits only.
            for candidate in CustomUser.objects.filter(phone__isnull=False):
                if re.sub(r'\D', '', candidate.phone or '') == digits:
                    user = candidate
                    break

        # Silently store None if not found (no enumeration).
        self._user = user
        return value

    def save(self):
        if self._user is None:
            return None
        return PasswordResetToken.generate_for(self._user)


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=6, min_length=6)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password2 = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({'new_password': 'Passwords do not match.'})
        try:
            reset_token = PasswordResetToken.objects.select_related('user').get(
                token=attrs['token'], used=False
            )
        except PasswordResetToken.DoesNotExist:
            raise serializers.ValidationError({'token': 'Invalid or expired reset code.'})
        if not reset_token.is_valid:
            raise serializers.ValidationError({'token': 'Reset code has expired. Please request a new one.'})
        attrs['_reset_token'] = reset_token
        return attrs

    def save(self):
        reset_token = self.validated_data['_reset_token']
        user = reset_token.user
        user.set_password(self.validated_data['new_password'])
        user.save()
        reset_token.used = True
        reset_token.save()
        return user
