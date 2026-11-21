from django import forms
from reports.models import DiseaseReport
from announcements.models import OfficialAnnouncement


class ReportReviewForm(forms.Form):
    STATUS_CHOICES = [
        (DiseaseReport.STATUS_UNDER_REVIEW, 'Under Review'),
        (DiseaseReport.STATUS_CLARIFICATION, 'Clarification Requested'),
        (DiseaseReport.STATUS_ACCEPTED, 'Accepted for Assessment'),
        (DiseaseReport.STATUS_REJECTED, 'Rejected'),
        (DiseaseReport.STATUS_CLOSED, 'Closed'),
    ]
    new_status = forms.ChoiceField(choices=STATUS_CHOICES, label='Set Status')
    notes = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 3}),
        required=False,
        label='Reviewer Notes (optional)',
    )


class AnnouncementForm(forms.ModelForm):
    class Meta:
        model = OfficialAnnouncement
        fields = [
            'title', 'announcement_type', 'content', 'prevention_guidance',
            'affected_area', 'affected_area_name', 'affected_species',
            'expires_at', 'related_reports',
        ]
        widgets = {
            'content': forms.Textarea(attrs={'rows': 6}),
            'prevention_guidance': forms.Textarea(attrs={'rows': 4}),
            'expires_at': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'related_reports': forms.CheckboxSelectMultiple(),
        }
        labels = {
            'expires_at': 'Expires at (optional)',
            'related_reports': 'Related disease reports (optional)',
        }


class WithdrawForm(forms.Form):
    reason = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 3}),
        label='Withdrawal Reason',
        help_text='Explain why this announcement is being withdrawn.',
    )
