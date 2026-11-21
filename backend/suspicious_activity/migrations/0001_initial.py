import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='SuspiciousActivityFlag',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rule_key', models.CharField(
                    choices=[
                        ('repeated_failed_logins', 'repeated_failed_logins'),
                        ('bulk_health_edits', 'bulk_health_edits'),
                        ('cross_owner_probing', 'cross_owner_probing'),
                        ('report_burst', 'report_burst'),
                        ('announcement_edits', 'announcement_edits'),
                        ('sync_replay_mismatch', 'sync_replay_mismatch'),
                        ('permission_denied_burst', 'permission_denied_burst'),
                    ],
                    max_length=50,
                )),
                ('explanation', models.TextField()),
                ('window_start', models.DateTimeField()),
                ('window_end', models.DateTimeField()),
                ('evidence', models.JSONField(default=dict)),
                ('status', models.CharField(
                    choices=[
                        ('OPEN', 'OPEN'),
                        ('REVIEWED_OK', 'REVIEWED_OK'),
                        ('ESCALATED', 'ESCALATED'),
                        ('FALSE_POSITIVE', 'FALSE_POSITIVE'),
                        ('ACTION_TAKEN', 'ACTION_TAKEN'),
                    ],
                    default='OPEN',
                    max_length=20,
                )),
                ('outcome_note', models.TextField(blank=True)),
                ('rule_version', models.CharField(default='1.0', max_length=10)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('resolved_at', models.DateTimeField(blank=True, null=True)),
                ('actor', models.ForeignKey(
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='suspicious_flags',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
