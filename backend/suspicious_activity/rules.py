from django.utils import timezone
from datetime import timedelta
from .models import SuspiciousActivityFlag
from audit.models import AuditEvent
from reports.models import DiseaseReport
from announcements.models import OfficialAnnouncement


RULE_VERSION = '1.0'


def _already_flagged(rule_key, actor, window_minutes):
    """Return True if an OPEN flag for this rule and actor was created in the last window."""
    since = timezone.now() - timedelta(minutes=window_minutes)
    return SuspiciousActivityFlag.objects.filter(
        rule_key=rule_key, actor=actor, status='OPEN', created_at__gte=since
    ).exists()


def check_report_burst(user):
    """report_burst: >5 disease reports by one author in 24 hours."""
    since = timezone.now() - timedelta(hours=24)
    count = DiseaseReport.objects.filter(reporter=user, created_at__gte=since).count()
    if count <= 5:
        return None
    if _already_flagged('report_burst', user, 24 * 60):
        return None
    return SuspiciousActivityFlag.objects.create(
        rule_key='report_burst',
        explanation=f'{user.username} submitted {count} disease reports within 24 hours (threshold: 5).',
        actor=user,
        window_start=since,
        window_end=timezone.now(),
        evidence={'count': count, 'window_hours': 24},
        rule_version=RULE_VERSION,
    )


def check_bulk_health_edits(user):
    """bulk_health_edits: >25 health-record UPDATE audit events by one actor in 10 minutes."""
    since = timezone.now() - timedelta(minutes=10)
    count = AuditEvent.objects.filter(
        actor=user,
        action=AuditEvent.Action.UPDATE,
        target_type='HealthRecord',
        timestamp__gte=since,
    ).count()
    if count <= 25:
        return None
    if _already_flagged('bulk_health_edits', user, 10):
        return None
    return SuspiciousActivityFlag.objects.create(
        rule_key='bulk_health_edits',
        explanation=f'{user.username} made {count} health-record updates within 10 minutes (threshold: 25).',
        actor=user,
        window_start=since,
        window_end=timezone.now(),
        evidence={'count': count, 'window_minutes': 10},
        rule_version=RULE_VERSION,
    )


def check_announcement_edits(user):
    """announcement_edits: >3 published-version updates by one officer in 1 hour."""
    since = timezone.now() - timedelta(hours=1)
    count = AuditEvent.objects.filter(
        actor=user,
        action=AuditEvent.Action.UPDATE,
        target_type='OfficialAnnouncement',
        timestamp__gte=since,
    ).count()
    if count <= 3:
        return None
    if _already_flagged('announcement_edits', user, 60):
        return None
    return SuspiciousActivityFlag.objects.create(
        rule_key='announcement_edits',
        explanation=f'{user.username} made {count} announcement updates within 1 hour (threshold: 3).',
        actor=user,
        window_start=since,
        window_end=timezone.now(),
        evidence={'count': count, 'window_hours': 1},
        rule_version=RULE_VERSION,
    )
