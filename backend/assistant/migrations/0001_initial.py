import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='KBSource',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('content', models.TextField()),
                ('citation', models.CharField(max_length=255)),
                ('publisher', models.CharField(blank=True, max_length=100)),
                ('is_active', models.BooleanField(default=True)),
                ('review_due_at', models.DateField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='AssistantInteraction',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('question', models.TextField()),
                ('answer', models.TextField()),
                ('answer_source', models.CharField(
                    choices=[
                        ('KB', 'KB'),
                        ('LLM_RETRIEVAL', 'LLM_RETRIEVAL'),
                        ('FALLBACK_KB', 'FALLBACK_KB'),
                        ('FALLBACK_NONE', 'FALLBACK_NONE'),
                        ('REFUSED', 'REFUSED'),
                        ('DISABLED', 'DISABLED'),
                    ],
                    default='FALLBACK_NONE',
                    max_length=20,
                )),
                ('kb_version', models.CharField(default='none', max_length=20)),
                ('escalation', models.BooleanField(default=False)),
                ('safety_flags', models.JSONField(blank=True, default=list)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
