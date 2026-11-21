import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/disease_report.dart';

class ReportProvider extends ChangeNotifier {
  List<DiseaseReport> _reports = [];
  bool _loading = false;
  String? _error;

  List<DiseaseReport> get reports => List.unmodifiable(_reports);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadReports() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getList(ApiEndpoints.diseaseReports);
      final results = data['results'] as List<dynamic>? ?? [];
      _reports = results
          .map((e) => DiseaseReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load reports. Check your connection.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<DiseaseReport> submitReport(Map<String, dynamic> body) async {
    final data = await ApiClient.post(ApiEndpoints.diseaseReports, body);
    final report = DiseaseReport.fromJson(data);
    _reports.insert(0, report);
    notifyListeners();
    return report;
  }
}
