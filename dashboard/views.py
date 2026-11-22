from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.utils import timezone
from django.db.models import Count, Q

from reports.models import DiseaseReport
from announcements.models import OfficialAnnouncement
from accounts.models import CustomUser
from farms.models import Area
from audit.models import AuditEvent


def _authority_required(view_func):
    """Decorator: must be logged in AND have role AUTHORITY or ADMIN."""
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect('dashboard:login')
        if request.user.role not in ('AUTHORITY', 'ADMIN'):
            messages.error(request, 'Access denied. Authority accounts only.')
            return redirect('dashboard:login')
        return view_func(request, *args, **kwargs)
    wrapper.__name__ = view_func.__name__
    return wrapper


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

def dashboard_login(request):
    if request.user.is_authenticated and request.user.role in ('AUTHORITY', 'ADMIN'):
        return redirect('dashboard:home')

    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')
        user = authenticate(request, username=username, password=password)
        if user is None:
            messages.error(request, 'Invalid username or password.')
            return render(request, 'dashboard/login.html')
        if user.role not in ('AUTHORITY', 'ADMIN'):
            messages.error(request, 'This portal is for authorized veterinary authorities only.')
            return render(request, 'dashboard/login.html')
        login(request, user)
        AuditEvent.log(
            actor=user,
            action=AuditEvent.Action.LOGIN_SUCCESS,
            target_type='User',
            target_id=user.pk,
            description=f'{user.username} logged in to authority dashboard.',
        )
        return redirect('dashboard:home')

    return render(request, 'dashboard/login.html')


def dashboard_logout(request):
    if request.method == 'POST':
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='User',
            target_id=request.user.pk,
            description=f'{request.user.username} logged out of authority dashboard.',
        )
        logout(request)
    return redirect('dashboard:login')


# ---------------------------------------------------------------------------
# Home / overview
# ---------------------------------------------------------------------------

@_authority_required
def home(request):
    report_stats = DiseaseReport.objects.aggregate(
        total=Count('id'),
        submitted=Count('id', filter=Q(status='SUBMITTED')),
        under_review=Count('id', filter=Q(status='UNDER_REVIEW')),
        accepted=Count('id', filter=Q(status='ACCEPTED_FOR_ASSESSMENT')),
        confirmed=Count('id', filter=Q(is_confirmed_outbreak=True)),
    )
    ann_stats = OfficialAnnouncement.objects.aggregate(
        total=Count('id'),
        published=Count('id', filter=Q(status='PUBLISHED')),
        draft=Count('id', filter=Q(status='DRAFT')),
    )
    recent_reports = DiseaseReport.objects.select_related('reporter').order_by('-created_at')[:5]
    recent_announcements = OfficialAnnouncement.objects.order_by('-created_at')[:5]

    return render(request, 'dashboard/home.html', {
        'report_stats': report_stats,
        'ann_stats': ann_stats,
        'recent_reports': recent_reports,
        'recent_announcements': recent_announcements,
    })


# ---------------------------------------------------------------------------
# Disease reports
# ---------------------------------------------------------------------------

@_authority_required
def reports_list(request):
    qs = DiseaseReport.objects.select_related('reporter', 'area').order_by('-created_at')
    status_filter = request.GET.get('status', '')
    species_filter = request.GET.get('species', '')
    if status_filter:
        qs = qs.filter(status=status_filter)
    if species_filter:
        qs = qs.filter(species=species_filter)

    return render(request, 'dashboard/reports_list.html', {
        'reports': qs,
        'status_filter': status_filter,
        'species_filter': species_filter,
        'status_choices': DiseaseReport.STATUS_CHOICES,
        'species_choices': DiseaseReport.SPECIES_CHOICES,
    })


@_authority_required
def report_detail(request, pk):
    report = get_object_or_404(DiseaseReport, pk=pk)
    return render(request, 'dashboard/report_detail.html', {
        'report': report,
        'status_choices': DiseaseReport.STATUS_CHOICES,
    })


@_authority_required
def report_review(request, pk):
    if request.method != 'POST':
        return redirect('dashboard:report_detail', pk=pk)
    report = get_object_or_404(DiseaseReport, pk=pk)
    new_status = request.POST.get('status', '').strip()
    allowed = [
        DiseaseReport.STATUS_UNDER_REVIEW,
        DiseaseReport.STATUS_CLARIFICATION,
        DiseaseReport.STATUS_ACCEPTED,
        DiseaseReport.STATUS_REJECTED,
        DiseaseReport.STATUS_CLOSED,
    ]
    if new_status not in allowed:
        messages.error(request, 'Invalid status selected.')
        return redirect('dashboard:report_detail', pk=pk)
    report.status = new_status
    report.save(update_fields=['status', 'updated_at'])
    AuditEvent.log(
        actor=request.user,
        action=AuditEvent.Action.UPDATE,
        target_type='DiseaseReport',
        target_id=report.pk,
        description=f'Report #{report.pk} status set to {new_status} by {request.user.username}',
    )
    messages.success(request, f'Report status updated to {report.get_status_display()}.')
    return redirect('dashboard:report_detail', pk=pk)


@_authority_required
def report_confirm_outbreak(request, pk):
    if request.method != 'POST':
        return redirect('dashboard:report_detail', pk=pk)
    report = get_object_or_404(DiseaseReport, pk=pk)
    if report.status != DiseaseReport.STATUS_ACCEPTED:
        messages.error(request, 'Report must be in Accepted for Assessment status before confirming an outbreak.')
        return redirect('dashboard:report_detail', pk=pk)
    report.is_confirmed_outbreak = True
    report.status = DiseaseReport.STATUS_CLOSED
    report.save(update_fields=['is_confirmed_outbreak', 'status', 'updated_at'])
    AuditEvent.log(
        actor=request.user,
        action=AuditEvent.Action.UPDATE,
        target_type='DiseaseReport',
        target_id=report.pk,
        description=f'Report #{report.pk} confirmed as outbreak by {request.user.username}',
    )
    messages.success(request, 'Outbreak confirmed. Report is now closed.')
    return redirect('dashboard:report_detail', pk=pk)


# ---------------------------------------------------------------------------
# Announcements
# ---------------------------------------------------------------------------

@_authority_required
def announcements_list(request):
    qs = OfficialAnnouncement.objects.order_by('-created_at')
    status_filter = request.GET.get('status', '')
    if status_filter:
        qs = qs.filter(status=status_filter)
    return render(request, 'dashboard/announcements_list.html', {
        'announcements': qs,
        'status_filter': status_filter,
        'status_choices': OfficialAnnouncement.STATUS_CHOICES,
    })


@_authority_required
def announcement_create(request):
    areas = Area.objects.all().order_by('name')
    if request.method == 'POST':
        title = request.POST.get('title', '').strip()
        ann_type = request.POST.get('announcement_type', '')
        content = request.POST.get('content', '').strip()
        prevention = request.POST.get('prevention_guidance', '').strip()
        area_id = request.POST.get('affected_area', '')
        area_name = request.POST.get('affected_area_name', '').strip()
        species = request.POST.get('affected_species', '')
        audience = request.POST.get('target_audience', OfficialAnnouncement.AUDIENCE_ALL)

        if not title or not content:
            messages.error(request, 'Title and content are required.')
            return render(request, 'dashboard/announcement_form.html', {
                'areas': areas,
                'type_choices': OfficialAnnouncement.ANNOUNCEMENT_TYPES,
                'species_choices': OfficialAnnouncement.SPECIES_CHOICES,
                'audience_choices': OfficialAnnouncement.AUDIENCE_CHOICES,
                'form_data': request.POST,
            })

        area = None
        if area_id:
            try:
                area = Area.objects.get(pk=area_id)
            except Area.DoesNotExist:
                pass

        ann = OfficialAnnouncement.objects.create(
            title=title,
            announcement_type=ann_type,
            content=content,
            prevention_guidance=prevention,
            issuing_authority=request.user,
            affected_area=area,
            affected_area_name=area_name or (area.name if area else ''),
            affected_species=species,
            target_audience=audience,
            status=OfficialAnnouncement.STATUS_DRAFT,
        )
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.CREATE,
            target_type='OfficialAnnouncement',
            target_id=ann.pk,
            description=f"Announcement draft created: '{ann.title}'",
        )
        messages.success(request, f'Announcement "{ann.title}" saved as draft.')
        return redirect('dashboard:announcement_detail', pk=ann.pk)

    return render(request, 'dashboard/announcement_form.html', {
        'areas': areas,
        'type_choices': OfficialAnnouncement.ANNOUNCEMENT_TYPES,
        'species_choices': OfficialAnnouncement.SPECIES_CHOICES,
        'audience_choices': OfficialAnnouncement.AUDIENCE_CHOICES,
        'form_data': {},
    })


@_authority_required
def announcement_detail(request, pk):
    ann = get_object_or_404(OfficialAnnouncement, pk=pk)
    return render(request, 'dashboard/announcement_detail.html', {'ann': ann})


@_authority_required
def announcement_publish(request, pk):
    if request.method != 'POST':
        return redirect('dashboard:announcement_detail', pk=pk)
    ann = get_object_or_404(OfficialAnnouncement, pk=pk)
    if ann.status == OfficialAnnouncement.STATUS_PUBLISHED:
        messages.warning(request, 'Already published.')
        return redirect('dashboard:announcement_detail', pk=pk)
    if ann.status == OfficialAnnouncement.STATUS_WITHDRAWN:
        messages.error(request, 'Withdrawn announcements cannot be re-published.')
        return redirect('dashboard:announcement_detail', pk=pk)

    ann.status = OfficialAnnouncement.STATUS_PUBLISHED
    ann.published_at = timezone.now()
    ann.save(update_fields=['status', 'published_at', 'updated_at'])

    # Send in-app notifications
    from notifications.models import Notification
    audience = ann.target_audience
    if audience == OfficialAnnouncement.AUDIENCE_FARMERS:
        role_filter = ['FARMER']
    elif audience == OfficialAnnouncement.AUDIENCE_VETS:
        role_filter = ['VET']
    else:
        role_filter = ['FARMER', 'VET']
    recipients = CustomUser.objects.filter(role__in=role_filter, is_active=True)
    Notification.objects.bulk_create([
        Notification(
            recipient=u,
            notification_type='ANNOUNCEMENT',
            title=f'Official: {ann.title}',
            body=(
                f'A new official announcement has been published. '
                f'Type: {ann.get_announcement_type_display()}. '
                f'Audience: {ann.get_target_audience_display()}.'
            ),
        )
        for u in recipients
    ])

    AuditEvent.log(
        actor=request.user,
        action=AuditEvent.Action.UPDATE,
        target_type='OfficialAnnouncement',
        target_id=ann.pk,
        description=f"Announcement #{ann.pk} '{ann.title}' published by {request.user.username}",
    )
    messages.success(request, f'Announcement published and {recipients.count()} notification(s) sent.')
    return redirect('dashboard:announcement_detail', pk=pk)


@_authority_required
def announcement_withdraw(request, pk):
    if request.method != 'POST':
        return redirect('dashboard:announcement_detail', pk=pk)
    ann = get_object_or_404(OfficialAnnouncement, pk=pk)
    if ann.status != OfficialAnnouncement.STATUS_PUBLISHED:
        messages.error(request, 'Only published announcements can be withdrawn.')
        return redirect('dashboard:announcement_detail', pk=pk)
    reason = request.POST.get('reason', '').strip()
    if not reason:
        messages.error(request, 'A withdrawal reason is required.')
        return redirect('dashboard:announcement_detail', pk=pk)

    ann.status = OfficialAnnouncement.STATUS_WITHDRAWN
    ann.withdrawn_at = timezone.now()
    ann.withdrawal_reason = reason
    ann.save(update_fields=['status', 'withdrawn_at', 'withdrawal_reason', 'updated_at'])
    AuditEvent.log(
        actor=request.user,
        action=AuditEvent.Action.UPDATE,
        target_type='OfficialAnnouncement',
        target_id=ann.pk,
        description=f"Announcement #{ann.pk} withdrawn by {request.user.username}. Reason: {reason}",
    )
    messages.success(request, 'Announcement withdrawn.')
    return redirect('dashboard:announcement_detail', pk=pk)
