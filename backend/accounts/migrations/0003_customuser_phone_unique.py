"""
Migration: make phone null=True, unique=True.

Steps:
1. Allow NULL (required before adding UNIQUE so blank strings can be cleared).
2. Convert existing blank strings to NULL (avoids unique-constraint collisions).
3. Add the UNIQUE constraint.
"""
from django.db import migrations, models


def blank_phones_to_null(apps, schema_editor):
    CustomUser = apps.get_model('accounts', 'CustomUser')
    CustomUser.objects.filter(phone='').update(phone=None)


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_password_reset_token'),
    ]

    operations = [
        # Step 1 – make nullable (no unique yet)
        migrations.AlterField(
            model_name='customuser',
            name='phone',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
        # Step 2 – convert '' → NULL
        migrations.RunPython(blank_phones_to_null, migrations.RunPython.noop),
        # Step 3 – add UNIQUE
        migrations.AlterField(
            model_name='customuser',
            name='phone',
            field=models.CharField(blank=True, max_length=20, null=True, unique=True),
        ),
    ]
