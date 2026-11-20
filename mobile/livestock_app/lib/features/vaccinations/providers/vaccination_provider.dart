import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/vaccination.dart';

class VaccinationProvider extends ChangeNotifier {
  List<VaccinationSchedule> _schedules = [];
  bool _loading = false;
  String? _error;

  List<VaccinationSchedule> get schedules => _schedules;
  bool get loading => _loading;
  String? get error => _error;

  List<VaccinationSchedule> get overdueSchedules =>
      _schedules.where((s) => s.isOverdue).toList();

  List<VaccinationSchedule> schedulesForAnimal(int animalId) =>
      _schedules.where((s) => s.animalId == animalId).toList();

  Future<void> loadSchedules() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getList(ApiEndpoints.vaccinationSchedules);
      final results = data['results'] as List<dynamic>? ?? [];
      _schedules = results
          .map((e) => VaccinationSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load vaccination schedules.';
    }
    _loading = false;
    notifyListeners();
  }
}
