from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('animals', '0001_initial'),
        ('farms', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='VetAssistanceRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('description', models.TextField()),
                ('status', models.CharField(
                    choices=[
                        ('PENDING', 'Pending'),
                        ('ACCEPTED', 'Accepted'),
                        ('IN_PROGRESS', 'In Progress'),
                        ('COMPLETED', 'Completed'),
                        ('CANCELLED', 'Cancelled'),
                        ('DECLINED', 'Declined'),
                    ],
                    default='PENDING',
                    max_length=20,
                )),
                ('farmer_latitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('farmer_longitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('area_name', models.CharField(blank=True, max_length=100)),
                ('location_consent', models.BooleanField(default=False)),
                ('vet_notes', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('responded_at', models.DateTimeField(blank=True, null=True)),
                ('animal', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='assistance_requests',
                    to='animals.animal',
                )),
                ('farm', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='assistance_requests',
                    to='farms.farm',
                )),
                ('farmer', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='assistance_requests',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('vet', models.ForeignKey(
                    blank=True,
                    limit_choices_to={'role': 'VET'},
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='vet_requests',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
