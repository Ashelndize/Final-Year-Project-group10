import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/offline/offline_database.dart';
import '../../../core/offline/offline_queue_item.dart';
import '../models/health_record.dart';

class HealthProvider extends ChangeNotifier {
  List<HealthRecord> _records = [];
  bool _loading = false;
  String? _error;

  List<HealthRecord> get records => _records;
  bool get loading => _loading;
  String? get error => _error;

  List<HealthRecord> recordsForAnimal(int animalId) =>
      _records.where((r) => r.animalId == animalId).toList();

  Future<void> loadRecords({int? animalId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params =
          animalId != null ? {'animal': animalId.toString()} : null;
      final data = await ApiClient.getList(
        ApiEndpoints.healthRecords,
        queryParams: params,
      );
      final results = data['results'] as List<dynamic>? ?? [];
      _records = results
          .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load health records.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createRecord({
    required int animalId,
    required String recordDate,
    required String healthStatus,
    String? weightKg,
    String? temperatureC,
    String symptoms = '',
    String diagnosis = '',
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      'animal': animalId,
      'record_date': recordDate,
      'health_status': healthStatus,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'notes': notes,
    };
    if (weightKg != null && weightKg.isNotEmpty) body['weight_kg'] = weightKg;
    if (temperatureC != null && temperatureC.isNotEmpty) {
      body['temperature_c'] = temperatureC;
    }

    // Offline check — queue if no connection.
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet,);
    if (!isOnline) {
      await OfflineDatabase.enqueue(OfflineQueueItem(
        id: const Uuid().v4(),
        operationType: OfflineOperationType.healthRecord,
        endpoint: ApiEndpoints.healthRecords,
        payload: body,
        createdAt: DateTime.now(),
      ),);
      return true; // treated as success; banner indicates pending sync
    }

    try {
      final data = await ApiClient.post(ApiEndpoints.healthRecords, body);
      _records.insert(0, HealthRecord.fromJson(data));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to save health record.';
      notifyListeners();
      return false;
    }
  }
}
