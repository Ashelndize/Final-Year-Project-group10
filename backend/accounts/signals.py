from django.contrib.auth.signals import user_logged_in, user_logged_out, user_login_failed
from django.dispatch import receiver
from audit.models import AuditEvent


def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0]
    return request.META.get('REMOTE_ADDR')


@receiver(user_logged_in)
def on_login(sender, request, user, **kwargs):
    AuditEvent.log(
        actor=user,
        action=AuditEvent.Action.LOGIN_SUCCESS,
        target_type='User',
        target_id=user.pk,
        description=f'User {user.username} logged in.',
        ip_address=get_client_ip(request),
    )


@receiver(user_logged_out)
def on_logout(sender, request, user, **kwargs):
    if user:
        AuditEvent.log(
            actor=user,
            action=AuditEvent.Action.LOGOUT,
            target_type='User',
            target_id=user.pk,
            description=f'User {user.username} logged out.',
            ip_address=get_client_ip(request),
        )


@receiver(user_login_failed)
def on_login_failed(sender, credentials, request, **kwargs):
    AuditEvent.log(
        actor=None,
        action=AuditEvent.Action.LOGIN_FAIL,
        description=f'Failed login attempt for username: {credentials.get("username", "unknown")}',
        ip_address=get_client_ip(request),
    )
