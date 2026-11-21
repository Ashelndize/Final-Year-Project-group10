import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_app/core/offline/offline_queue_exception.dart';
import 'package:livestock_app/core/offline/offline_queue_item.dart';
import 'package:livestock_app/features/assistant/models/assistant_response.dart';
import 'package:livestock_app/features/auth/models/user.dart';
import 'package:livestock_app/features/farms/models/farm.dart';
import 'package:livestock_app/features/animals/models/animal.dart';
import 'package:livestock_app/features/auth/providers/auth_provider.dart';
import 'package:livestock_app/features/health/models/health_record.dart';
import 'package:livestock_app/features/reports/models/disease_report.dart';

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

  group('HealthRecord model', () {
    final baseJson = {
      'id': 10,
      'animal': 5,
      'animal_tag': 'TAG-005',
      'recorded_by': 2,
      'recorded_by_username': 'vet1',
      'record_date': '2026-11-21',
      'weight_kg': '320.50',
      'temperature_c': '38.6',
      'health_status': 'HEALTHY',
      'symptoms': '',
      'diagnosis': '',
      'notes': 'Routine check',
      'created_at': '2026-11-21T08:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final record = HealthRecord.fromJson(baseJson);
      expect(record.id, 10);
      expect(record.animalId, 5);
      expect(record.animalTag, 'TAG-005');
      expect(record.recordedById, 2);
      expect(record.recordedByUsername, 'vet1');
      expect(record.recordDate, '2026-11-21');
      expect(record.weightKg, '320.50');
      expect(record.temperatureC, '38.6');
      expect(record.healthStatus, 'HEALTHY');
      expect(record.notes, 'Routine check');
    });

    test('statusLabel maps all known statuses', () {
      for (final entry in HealthRecord.statusLabels.entries) {
        final record = HealthRecord.fromJson({...baseJson, 'health_status': entry.key});
        expect(record.statusLabel, entry.value);
      }
    });

    test('statusLabel falls back to raw value for unknown status', () {
      final record = HealthRecord.fromJson({...baseJson, 'health_status': 'UNKNOWN_STATUS'});
      expect(record.statusLabel, 'UNKNOWN_STATUS');
    });

    test('statusColor returns expected color int for HEALTHY', () {
      final record = HealthRecord.fromJson(baseJson);
      expect(record.statusColor, 0xFF4CAF50);
    });

    test('statusColor returns grey for unknown status', () {
      final record = HealthRecord.fromJson({...baseJson, 'health_status': 'UNKNOWN'});
      expect(record.statusColor, 0xFF9E9E9E);
    });

    test('optional fields accept null', () {
      final record = HealthRecord.fromJson({
        ...baseJson,
        'weight_kg': null,
        'temperature_c': null,
        'recorded_by': null,
      });
      expect(record.weightKg, isNull);
      expect(record.temperatureC, isNull);
      expect(record.recordedById, isNull);
    });
  });

  group('DiseaseReport model', () {
    final baseJson = {
      'id': 7,
      'reporter': 3,
      'reporter_username': 'farmer2',
      'farm': 2,
      'farm_name': 'Green Pastures',
      'species': 'CATTLE',
      'species_display': 'Cattle',
      'observation_date': '2026-11-21',
      'area': 1,
      'area_display': 'Harare',
      'area_name': 'Harare',
      'observed_signs': 'Fever and lethargy',
      'notes': '',
      'status': 'SUBMITTED',
      'status_display': 'Submitted',
      'is_confirmed_outbreak': false,
      'report_latitude': null,
      'report_longitude': null,
      'location_consent': false,
      'created_at': '2026-11-21T09:00:00Z',
      'updated_at': '2026-11-21T09:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final report = DiseaseReport.fromJson(baseJson);
      expect(report.id, 7);
      expect(report.reporter, 3);
      expect(report.reporterUsername, 'farmer2');
      expect(report.species, 'CATTLE');
      expect(report.observedSigns, 'Fever and lethargy');
      expect(report.status, 'SUBMITTED');
      expect(report.isConfirmedOutbreak, false);
      expect(report.reportLatitude, isNull);
      expect(report.locationConsent, false);
    });

    test('fromJson parses GPS coordinates when present', () {
      final report = DiseaseReport.fromJson({
        ...baseJson,
        'report_latitude': '17.8292',
        'report_longitude': '31.0522',
        'location_consent': true,
      });
      expect(report.reportLatitude, closeTo(17.8292, 0.0001));
      expect(report.reportLongitude, closeTo(31.0522, 0.0001));
      expect(report.locationConsent, true);
    });

    test('statusColor returns correct colour for each status', () {
      final cases = {
        'SUBMITTED': Colors.blue,
        'UNDER_REVIEW': Colors.orange,
        'ACCEPTED_FOR_ASSESSMENT': Colors.purple,
        'REJECTED': Colors.red,
        'CLOSED': Colors.grey,
      };
      for (final entry in cases.entries) {
        final report = DiseaseReport.fromJson({...baseJson, 'status': entry.key});
        expect(report.statusColor, entry.value,
            reason: 'status ${entry.key} should map to ${entry.value}',);
      }
    });

    test('statusColor defaults to grey for unknown status', () {
      final report = DiseaseReport.fromJson({...baseJson, 'status': 'MYSTERY'});
      expect(report.statusColor, Colors.grey);
    });
  });

  group('AssistantResponse model', () {
    final baseJson = {
      'id': 1,
      'answer': 'The animal may have FMD. Consult a vet.',
      'answer_source': 'KB',
      'kb_version': '1.0.0',
      'escalation': false,
      'safety_flags': <dynamic>[],
      'disclaimer': 'General information — not a diagnosis.',
      'created_at': '2026-11-21T10:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final response = AssistantResponse.fromJson(baseJson);
      expect(response.id, 1);
      expect(response.answer, 'The animal may have FMD. Consult a vet.');
      expect(response.answerSource, 'KB');
      expect(response.kbVersion, '1.0.0');
      expect(response.escalation, false);
      expect(response.safetyFlags, isEmpty);
      expect(response.disclaimer, contains('not a diagnosis'));
    });

    test('isFromKB is true when source is KB', () {
      final response = AssistantResponse.fromJson(baseJson);
      expect(response.isFromKB, true);
      expect(response.isDisabled, false);
      expect(response.isRefused, false);
    });

    test('isDisabled is true when source is DISABLED', () {
      final response = AssistantResponse.fromJson({...baseJson, 'answer_source': 'DISABLED'});
      expect(response.isDisabled, true);
      expect(response.isFromKB, false);
    });

    test('isRefused is true when source is REFUSED', () {
      final response = AssistantResponse.fromJson({...baseJson, 'answer_source': 'REFUSED'});
      expect(response.isRefused, true);
    });

    test('safety_flags list is parsed correctly', () {
      final response = AssistantResponse.fromJson({
        ...baseJson,
        'safety_flags': ['DRUG_DOSAGE', 'SURGERY'],
      });
      expect(response.safetyFlags, ['DRUG_DOSAGE', 'SURGERY']);
    });

    test('escalation flag is parsed', () {
      final response = AssistantResponse.fromJson({...baseJson, 'escalation': true});
      expect(response.escalation, true);
    });
  });
}
