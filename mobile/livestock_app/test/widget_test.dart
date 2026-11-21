import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_app/core/offline/offline_queue_exception.dart';
import 'package:livestock_app/core/offline/offline_queue_item.dart';
import 'package:livestock_app/features/auth/models/user.dart';
import 'package:livestock_app/features/farms/models/farm.dart';
import 'package:livestock_app/features/animals/models/animal.dart';
import 'package:livestock_app/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage has no native impl in unit-test environments.
  // Register a no-op mock so AuthProvider construction does not throw.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (_) async => null,
  );

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

  group('OfflineQueueItem', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final item = OfflineQueueItem(
        id: 'test-uuid-1234',
        operationType: OfflineOperationType.healthRecord,
        endpoint: '/api/v1/health-records/',
        payload: {'animal': 1, 'health_status': 'HEALTHY'},
        createdAt: DateTime(2026, 11, 21, 10, 0, 0),
      );
      final map = item.toMap();
      final restored = OfflineQueueItem.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.operationType, OfflineOperationType.healthRecord);
      expect(restored.endpoint, '/api/v1/health-records/');
      expect(restored.payload['health_status'], 'HEALTHY');
      expect(restored.status, OfflineQueueStatus.pending);
      expect(restored.retryCount, 0);
    });

    test('fromMap restores failed status and retry count', () {
      final item = OfflineQueueItem(
        id: 'test-uuid-5678',
        operationType: OfflineOperationType.diseaseReport,
        endpoint: '/api/v1/disease-reports/',
        payload: {'species': 'CATTLE'},
        createdAt: DateTime(2026, 11, 21),
        status: OfflineQueueStatus.failed,
        retryCount: 3,
        errorMessage: 'Server error',
      );
      final restored = OfflineQueueItem.fromMap(item.toMap());

      expect(restored.status, OfflineQueueStatus.failed);
      expect(restored.retryCount, 3);
      expect(restored.errorMessage, 'Server error');
    });

    test('all operation types survive round-trip', () {
      for (final type in OfflineOperationType.values) {
        final item = OfflineQueueItem(
          id: 'id-$type',
          operationType: type,
          endpoint: '/api/v1/test/',
          payload: {},
          createdAt: DateTime(2026, 1, 1),
        );
        final restored = OfflineQueueItem.fromMap(item.toMap());
        expect(restored.operationType, type);
      }
    });
  });

  group('OfflineQueueException', () {
    test('default message is user-friendly', () {
      const e = OfflineQueueException();
      expect(e.toString(), contains('offline'));
    });

    test('custom message is preserved', () {
      const e = OfflineQueueException('Custom offline message');
      expect(e.toString(), 'Custom offline message');
    });

    test('is catchable as Exception', () {
      expect(
        () => throw const OfflineQueueException(),
        throwsA(isA<OfflineQueueException>()),
      );
    });
  });
}
