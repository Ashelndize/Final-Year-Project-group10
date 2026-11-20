import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/farm.dart';

class FarmProvider extends ChangeNotifier {
  List<Farm> _farms = [];
  bool _loading = false;
  String? _error;

  List<Farm> get farms => _farms;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFarms() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getList(ApiEndpoints.farms);
      final results = data['results'] as List<dynamic>? ?? [];
      _farms = results
          .map((e) => Farm.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load farms. Check your connection.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createFarm({
    required String name,
    required String farmType,
    required String address,
    String notes = '',
    int? areaId,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'farm_type': farmType,
        'address': address,
        'notes': notes,
      };
      if (areaId != null) body['area'] = areaId;
      final data = await ApiClient.post(ApiEndpoints.farms, body);
      _farms.insert(0, Farm.fromJson(data));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to create farm.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFarm(int id, Map<String, dynamic> data) async {
    try {
      final updated = await ApiClient.patch(ApiEndpoints.farmDetail(id), data);
      final index = _farms.indexWhere((f) => f.id == id);
      if (index != -1) _farms[index] = Farm.fromJson(updated);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to update farm.';
      notifyListeners();
      return false;
    }
  }

  Farm? getFarmById(int id) {
    try {
      return _farms.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
