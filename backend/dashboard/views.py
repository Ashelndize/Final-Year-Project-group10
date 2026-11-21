from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.db.models import Count, Q
from reports.models import DiseaseReport
from announcements.models import OfficialAnnouncement
from audit.models import AuditEvent
from .decorators import authority_required
from .forms import ReportReviewForm, AnnouncementForm, WithdrawForm


def dashboard_login(request):
    if request.user.is_authenticated and request.user.role in ('AUTHORITY', 'ADMIN'):
        return redirect('dashboard:index')
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')
        user = authenticate(request, username=username, password=password)
        if user is None:
            messages.error(request, 'Invalid username or password.')
        elif user.role not in ('AUTHORITY', 'ADMIN'):
            messages.error(request, 'Your account does not have authority dashboard access.')
        else:
            login(request, user)
            AuditEvent.log(
                actor=user,
                action=AuditEvent.Action.LOGIN_SUCCESS,
                description='Authority dashboard login',
            )
            return redirect('dashboard:index')
    return render(request, 'dashboard/login.html')


def dashboard_logout(request):
    if request.user.is_authenticated:
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.LOGOUT,
            description='Authority dashboard logout',
        )
    logout(request)
    return redirect('dashboard:login')


@authority_required
def dashboard_index(request):
    pending_reports = DiseaseReport.objects.filter(
        status=DiseaseReport.STATUS_SUBMITTED
    ).count()
    under_review = DiseaseReport.objects.filter(
        status=DiseaseReport.STATUS_UNDER_REVIEW
    ).count()
    published_announcements = OfficialAnnouncement.objects.filter(
        status=OfficialAnnouncement.STATUS_PUBLISHED
    ).count()
    recent_reports = DiseaseReport.objects.select_related('reporter', 'area').order_by('-created_at')[:5]
    recent_announcements = OfficialAnnouncement.objects.select_related('issuing_authority').order_by('-created_at')[:5]
    context = {
        'pending_reports': pending_reports,
        'under_review': under_review,
        'published_announcements': published_announcements,
        'recent_reports': recent_reports,
        'recent_announcements': recent_announcements,
    }
    return render(request, 'dashboard/index.html', context)


@authority_required
def report_queue(request):
    status_filter = request.GET.get('status', '')
    species_filter = request.GET.get('species', '')
    reports = DiseaseReport.objects.select_related('reporter', 'area').order_by('-created_at')
    if status_filter:
        reports = reports.filter(status=status_filter)
    if species_filter:
        reports = reports.filter(species=species_filter)
    context = {
        'reports': reports,
        'status_filter': status_filter,
        'species_filter': species_filter,
        'status_choices': DiseaseReport.STATUS_CHOICES,
        'species_choices': DiseaseReport.SPECIES_CHOICES,
    }
    return render(request, 'dashboard/report_queue.html', context)


@authority_required
def report_detail(request, report_id):
    report = get_object_or_404(DiseaseReport, pk=report_id)
    form = ReportReviewForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        new_status = form.cleaned_data['new_status']
        notes = form.cleaned_data.get('notes', '')
        report.status = new_status
        report.save(update_fields=['status', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='DiseaseReport',
            target_id=report.pk,
            description=f"Status set to {new_status} via dashboard. Notes: {notes}" if notes
                        else f"Status set to {new_status} via dashboard",
        )
        messages.success(request, f'Report #{report.pk} status updated to {new_status}.')
        return redirect('dashboard:report_detail', report_id=report.pk)
    audit_events = AuditEvent.objects.filter(
        target_type='DiseaseReport', target_id=str(report.pk)
    ).order_by('-timestamp')[:10]
    context = {'report': report, 'form': form, 'audit_events': audit_events}
    return render(request, 'dashboard/report_detail.html', context)


@authority_required
def announcement_list(request):
    announcements = OfficialAnnouncement.objects.select_related(
        'issuing_authority'
    ).order_by('-created_at')
    context = {'announcements': announcements}
    return render(request, 'dashboard/announcement_list.html', context)


@authority_required
def announcement_create(request):
    form = AnnouncementForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        announcement = form.save(commit=False)
        announcement.issuing_authority = request.user
        announcement.save()
        form.save_m2m()
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.CREATE,
            target_type='OfficialAnnouncement',
            target_id=announcement.pk,
            description=f"Draft announcement created: '{announcement.title}'",
        )
        messages.success(request, f"Draft announcement '{announcement.title}' created.")
        return redirect('dashboard:announcement_detail', ann_id=announcement.pk)
    return render(request, 'dashboard/announcement_form.html', {'form': form, 'action': 'Create'})


@authority_required
def announcement_edit(request, ann_id):
    announcement = get_object_or_404(OfficialAnnouncement, pk=ann_id)
    if announcement.status != OfficialAnnouncement.STATUS_DRAFT:
        messages.error(request, 'Only draft announcements can be edited.')
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    form = AnnouncementForm(request.POST or None, instance=announcement)
    if request.method == 'POST' and form.is_valid():
        form.save()
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
            target_id=announcement.pk,
            description=f"Draft announcement #{ann_id} edited",
        )
        messages.success(request, 'Announcement updated.')
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    return render(request, 'dashboard/announcement_form.html', {'form': form, 'action': 'Edit', 'announcement': announcement})


@authority_required
def announcement_detail(request, ann_id):
    announcement = get_object_or_404(
        OfficialAnnouncement.objects.select_related('issuing_authority', 'affected_area'),
        pk=ann_id,
    )
    audit_events = AuditEvent.objects.filter(
        target_type='OfficialAnnouncement', target_id=str(ann_id)
    ).order_by('-timestamp')[:10]
    context = {'announcement': announcement, 'audit_events': audit_events}
    return render(request, 'dashboard/announcement_detail.html', context)


@authority_required
def announcement_publish(request, ann_id):
    if request.method != 'POST':
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    announcement = get_object_or_404(OfficialAnnouncement, pk=ann_id)
    if announcement.status != OfficialAnnouncement.STATUS_DRAFT:
        messages.error(request, 'Only draft announcements can be published.')
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    from django.utils import timezone
    from notifications.models import Notification
    from accounts.models import CustomUser
    announcement.status = OfficialAnnouncement.STATUS_PUBLISHED
    announcement.published_at = timezone.now()
    announcement.save(update_fields=['status', 'published_at', 'updated_at'])
    AuditEvent.log(
        actor=request.user,
        action=AuditEvent.Action.UPDATE,
        target_type='OfficialAnnouncement',
        target_id=announcement.pk,
        description=f"Announcement #{ann_id} '{announcement.title}' published by {request.user.username}",
    )
    # Notify all farmers and vets
    recipients = CustomUser.objects.filter(role__in=['FARMER', 'VET'], is_active=True)
    Notification.objects.bulk_create([
        Notification(
            recipient=u,
            notification_type='ANNOUNCEMENT',
            title=f"Official: {announcement.title}",
            body=(
                f"A new official announcement has been published. "
                f"Type: {announcement.get_announcement_type_display()}."
            ),
        )
        for u in recipients
    ])
    messages.success(request, f"Announcement '{announcement.title}' has been published and users notified.")
    return redirect('dashboard:announcement_detail', ann_id=ann_id)


@authority_required
def announcement_withdraw(request, ann_id):
    announcement = get_object_or_404(OfficialAnnouncement, pk=ann_id)
    if announcement.status != OfficialAnnouncement.STATUS_PUBLISHED:
        messages.error(request, 'Only published announcements can be withdrawn.')
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    form = WithdrawForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        from django.utils import timezone
        reason = form.cleaned_data['reason']
        announcement.status = OfficialAnnouncement.STATUS_WITHDRAWN
        announcement.withdrawn_at = timezone.now()
        announcement.withdrawal_reason = reason
        announcement.save(update_fields=['status', 'withdrawn_at', 'withdrawal_reason', 'updated_at'])
        AuditEvent.log(
            actor=request.user,
            action=AuditEvent.Action.UPDATE,
            target_type='OfficialAnnouncement',
            target_id=announcement.pk,
            description=f"Announcement #{ann_id} withdrawn by {request.user.username}. Reason: {reason}",
        )
        messages.success(request, 'Announcement withdrawn.')
        return redirect('dashboard:announcement_detail', ann_id=ann_id)
    return render(request, 'dashboard/announcement_withdraw.html', {'form': form, 'announcement': announcement})
