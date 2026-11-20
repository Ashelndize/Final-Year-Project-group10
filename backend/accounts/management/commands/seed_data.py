from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from farms.models import Area, Farm
from animals.models import Animal
from health.models import VaccinationProtocol, VaccinationSchedule, VaccinationRecord
from notifications.models import Notification
import datetime

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed the database with synthetic development data.'

    def handle(self, *args, **options):
        self.stdout.write('Seeding database...')

        # Admin
        admin, _ = User.objects.get_or_create(
            username='admin',
            defaults={'email': 'admin@livestock.local', 'role': 'ADMIN',
                      'first_name': 'System', 'last_name': 'Admin', 'is_staff': True, 'is_superuser': True}
        )
        if _:
            admin.set_password('Admin@1234Dev')
            admin.save()
            self.stdout.write('  Created admin user')

        # Farmers
        farmer1, _ = User.objects.get_or_create(
            username='farmer1',
            defaults={'email': 'farmer1@livestock.local', 'role': 'FARMER',
                      'first_name': 'John', 'last_name': 'Moyo'}
        )
        if _:
            farmer1.set_password('Farmer@1234')
            farmer1.save()
            from accounts.models import FarmerProfile
            FarmerProfile.objects.get_or_create(user=farmer1, defaults={'location': 'Harare'})
            self.stdout.write('  Created farmer1')

        farmer2, _ = User.objects.get_or_create(
            username='farmer2',
            defaults={'email': 'farmer2@livestock.local', 'role': 'FARMER',
                      'first_name': 'Grace', 'last_name': 'Ndlovu'}
        )
        if _:
            farmer2.set_password('Farmer@1234')
            farmer2.save()
            from accounts.models import FarmerProfile
            FarmerProfile.objects.get_or_create(user=farmer2, defaults={'location': 'Bulawayo'})
            self.stdout.write('  Created farmer2')

        # Vet
        vet1, _ = User.objects.get_or_create(
            username='vet1',
            defaults={'email': 'vet1@livestock.local', 'role': 'VET',
                      'first_name': 'Dr. Sarah', 'last_name': 'Chikwanda'}
        )
        if _:
            vet1.set_password('Vet@12345Dev')
            vet1.save()
            from accounts.models import VetProfile
            VetProfile.objects.get_or_create(
                user=vet1,
                defaults={
                    'license_number': 'VET-ZW-001',
                    'specialization': 'Large Animals',
                    'clinic_name': 'Harare Animal Clinic',
                    'is_verified': True,
                }
            )
            self.stdout.write('  Created vet1')

        # Areas
        harare, _ = Area.objects.get_or_create(name='Harare', defaults={'province': 'Harare', 'country': 'Zimbabwe'})
        bulawayo, _ = Area.objects.get_or_create(name='Bulawayo', defaults={'province': 'Matabeleland', 'country': 'Zimbabwe'})

        # Farms
        farm1, _ = Farm.objects.get_or_create(
            owner=farmer1, name='Moyo Farm',
            defaults={'farm_type': 'MIXED', 'area': harare, 'address': 'Plot 12, Mazowe Road, Harare'}
        )
        farm2, _ = Farm.objects.get_or_create(
            owner=farmer2, name='Ndlovu Farm',
            defaults={'farm_type': 'DAIRY', 'area': bulawayo, 'address': 'Farm 7, Plumtree Road, Bulawayo'}
        )

        # Animals
        animal1, _ = Animal.objects.get_or_create(
            farm=farm1, tag_number='MF-001',
            defaults={'name': 'Bessie', 'species': 'CATTLE', 'breed': 'Hereford',
                      'sex': 'F', 'date_of_birth': datetime.date(2022, 3, 15)}
        )
        animal2, _ = Animal.objects.get_or_create(
            farm=farm1, tag_number='MF-002',
            defaults={'name': 'Rex', 'species': 'GOAT', 'breed': 'Boer',
                      'sex': 'M', 'date_of_birth': datetime.date(2023, 7, 1)}
        )
        animal3, _ = Animal.objects.get_or_create(
            farm=farm2, tag_number='NF-001',
            defaults={'name': 'Daisy', 'species': 'CATTLE', 'breed': 'Holstein',
                      'sex': 'F', 'date_of_birth': datetime.date(2021, 11, 20)}
        )

        # Vaccination protocols
        fmd_protocol, _ = VaccinationProtocol.objects.get_or_create(
            name='FMD Annual',
            defaults={'species': 'CATTLE', 'vaccine_name': 'FMD Vaccine Type SAT2',
                      'doses_required': 1, 'interval_days': 365,
                      'description': 'Annual foot-and-mouth disease vaccination for cattle.'}
        )
        brucellosis_protocol, _ = VaccinationProtocol.objects.get_or_create(
            name='Brucellosis S19',
            defaults={'species': 'CATTLE', 'vaccine_name': 'Brucella abortus S19',
                      'doses_required': 1, 'interval_days': 730,
                      'description': 'Brucellosis vaccination for female cattle under 8 months.'}
        )

        # Vaccination schedules
        today = datetime.date.today()
        VaccinationSchedule.objects.get_or_create(
            animal=animal1, protocol=fmd_protocol,
            defaults={'due_date': today + datetime.timedelta(days=30), 'status': 'PENDING'}
        )
        VaccinationSchedule.objects.get_or_create(
            animal=animal3, protocol=fmd_protocol,
            defaults={'due_date': today - datetime.timedelta(days=5), 'status': 'OVERDUE'}
        )

        # Notifications
        Notification.objects.get_or_create(
            recipient=farmer1,
            title='Vaccination Due Soon',
            defaults={
                'notification_type': 'VACCINATION_DUE',
                'body': f'Bessie (MF-001) is due for FMD Annual vaccination in 30 days.',
                'is_read': False,
            }
        )

        self.stdout.write(self.style.SUCCESS('Database seeded successfully.'))
        self.stdout.write('  Credentials: admin/Admin@1234Dev, farmer1/Farmer@1234, farmer2/Farmer@1234, vet1/Vet@12345Dev')
