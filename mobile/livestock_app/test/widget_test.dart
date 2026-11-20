import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_app/features/auth/models/user.dart';
import 'package:livestock_app/features/farms/models/farm.dart';
import 'package:livestock_app/features/animals/models/animal.dart';
import 'package:livestock_app/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User model', () {
    test('fromJson parses correctly', () {
      final user = User.fromJson({
        'id': 1,
        'username': 'farmer1',
        'email': 'farmer1@test.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'role': 'FARMER',
        'phone': '',
      });
      expect(user.username, 'farmer1');
      expect(user.isFarmer, true);
      expect(user.isVet, false);
      expect(user.fullName, 'John Doe');
    });
  });

  group('Farm model', () {
    test('fromJson parses correctly', () {
      final farm = Farm.fromJson({
        'id': 1,
        'name': 'My Farm',
        'farm_type': 'MIXED',
        'area': 1,
        'area_name': 'Harare',
        'address': '123 Farm Road',
        'status': 'ACTIVE',
        'notes': '',
        'owner': 1,
        'owner_username': 'farmer1',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(farm.name, 'My Farm');
      expect(farm.isActive, true);
      expect(farm.farmTypeLabel, 'Mixed');
    });
  });

  group('Animal model', () {
    test('fromJson parses correctly', () {
      final animal = Animal.fromJson({
        'id': 1,
        'farm': 1,
        'farm_name': 'My Farm',
        'tag_number': 'TAG001',
        'name': 'Bessie',
        'species': 'CATTLE',
        'breed': 'Hereford',
        'sex': 'F',
        'date_of_birth': '2022-01-01',
        'weight_kg': '250.00',
        'status': 'ACTIVE',
        'notes': '',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(animal.tagNumber, 'TAG001');
      expect(animal.displayName, 'Bessie');
      expect(animal.speciesLabel, 'Cattle');
      expect(animal.sexLabel, 'Female');
      expect(animal.isActive, true);
    });

    test('displayName falls back to tagNumber when name is empty', () {
      final animal = Animal.fromJson({
        'id': 2,
        'farm': 1,
        'farm_name': 'Farm',
        'tag_number': 'TAG002',
        'name': '',
        'species': 'GOAT',
        'breed': '',
        'sex': 'M',
        'status': 'ACTIVE',
        'notes': '',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(animal.displayName, 'TAG002');
    });
  });

  group('AuthProvider initial state', () {
    test('starts with loading false and no user', () {
      final provider = AuthProvider();
      expect(provider.loading, false);
      expect(provider.user, isNull);
    });
  });
}
