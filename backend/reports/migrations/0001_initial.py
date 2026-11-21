from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('farms', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='DiseaseReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('species', models.CharField(
                    choices=[
                        ('CATTLE', 'Cattle'),
                        ('GOAT', 'Goat'),
                        ('SHEEP', 'Sheep'),
                        ('PIG', 'Pig'),
                        ('CHICKEN', 'Chicken'),
                        ('OTHER', 'Other'),
                    ],
                    max_length=20,
                )),
                ('observation_date', models.DateField()),
                ('area_name', models.CharField(blank=True, max_length=100)),
                ('observed_signs', models.TextField()),
                ('notes', models.TextField(blank=True)),
                ('status', models.CharField(
                    choices=[
                        ('SUBMITTED', 'Submitted'),
                        ('UNDER_REVIEW', 'Under Review'),
                        ('ACCEPTED_FOR_ASSESSMENT', 'Accepted for Assessment'),
                        ('REJECTED', 'Rejected'),
                        ('CLOSED', 'Closed'),
                    ],
                    default='SUBMITTED',
                    max_length=30,
                )),
                ('is_confirmed_outbreak', models.BooleanField(default=False)),
                ('report_latitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('report_longitude', models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
                ('location_consent', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('area', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='disease_reports',
                    to='farms.area',
                )),
                ('farm', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='disease_reports',
                    to='farms.farm',
                )),
                ('reporter', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='disease_reports',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
