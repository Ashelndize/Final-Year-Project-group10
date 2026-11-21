from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('farms', '0001_initial'),
        ('reports', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='OfficialAnnouncement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('announcement_type', models.CharField(
                    choices=[
                        ('OUTBREAK_ALERT', 'Outbreak Alert'),
                        ('ADVISORY', 'Advisory'),
                        ('GENERAL', 'General Information'),
                        ('WITHDRAWAL', 'Withdrawal'),
                    ],
                    default='ADVISORY',
                    max_length=20,
                )),
                ('content', models.TextField()),
                ('prevention_guidance', models.TextField(blank=True)),
                ('affected_area_name', models.CharField(blank=True, max_length=100)),
                ('affected_species', models.CharField(
                    blank=True,
                    choices=[
                        ('', 'All Species'),
                        ('CATTLE', 'Cattle'),
                        ('GOAT', 'Goat'),
                        ('SHEEP', 'Sheep'),
                        ('PIG', 'Pig'),
                        ('CHICKEN', 'Chicken'),
                        ('OTHER', 'Other'),
                    ],
                    max_length=20,
                )),
                ('status', models.CharField(
                    choices=[
                        ('DRAFT', 'Draft'),
                        ('PUBLISHED', 'Published'),
                        ('EXPIRED', 'Expired'),
                        ('WITHDRAWN', 'Withdrawn'),
                    ],
                    default='DRAFT',
                    max_length=20,
                )),
                ('published_at', models.DateTimeField(blank=True, null=True)),
                ('expires_at', models.DateTimeField(blank=True, null=True)),
                ('withdrawn_at', models.DateTimeField(blank=True, null=True)),
                ('withdrawal_reason', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('affected_area', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='announcements',
                    to='farms.area',
                )),
                ('issuing_authority', models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name='issued_announcements',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('related_reports', models.ManyToManyField(
                    blank=True,
                    related_name='linked_announcements',
                    to='reports.diseasereport',
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
