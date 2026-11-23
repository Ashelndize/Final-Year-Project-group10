"""
Custom authentication backend.

Allows users to sign in with either:
  - their username, OR
  - their registered phone number (e.g. "0788123456" or "0788 123 456").

Phone lookup normalises the input to digits only before comparing, so
formatting differences don't prevent login.
"""
import re

from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend

User = get_user_model()

# Strips everything except digits (removes spaces, dashes, +, etc.)
_DIGITS_RE = re.compile(r'\D')


def _digits_only(value: str) -> str:
    return _DIGITS_RE.sub('', value)


class PhoneOrUsernameBackend(ModelBackend):
    """
    Try username first; if that yields nothing, attempt a phone lookup.
    A phone match requires the normalised digit strings to be equal and
    the input to contain at least 9 digits (avoids accidental matches on
    very short strings).
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        if username is None or password is None:
            return None

        user = self._find_user(username)
        if user is None:
            # Run set_password to mitigate timing attacks even on miss.
            User().set_password(password)
            return None

        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None

    # ------------------------------------------------------------------
    # helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _find_user(identifier: str):
        """Return a user matched by username or phone, or None."""
        # 1. Try exact username match (fast path).
        try:
            return User.objects.get(username=identifier)
        except User.DoesNotExist:
            pass

        # 2. Try phone match – only if the identifier looks like a phone number.
        normalised = _digits_only(identifier)
        if len(normalised) < 9:
            return None

        # Compare against stored phones (also normalised).
        # We load only users that have a non-null phone to keep the query small.
        for user in User.objects.filter(phone__isnull=False).only('id', 'phone', 'password', 'is_active'):
            if _digits_only(user.phone or '') == normalised:
                return user

        return None
