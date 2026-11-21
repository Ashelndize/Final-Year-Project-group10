import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/vet_assistance_request.dart';

class AssistanceProvider extends ChangeNotifier {
  List<VetAssistanceRequest> _requests = [];
  bool _loading = false;
  String? _error;

  List<VetAssistanceRequest> get requests => List.unmodifiable(_requests);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRequests() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getList(ApiEndpoints.assistanceRequests);
      final results = data['results'] as List<dynamic>? ?? [];
      _requests = results
          .map((e) => VetAssistanceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load requests. Check your connection.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<VetAssistanceRequest> createRequest(Map<String, dynamic> body) async {
    final data = await ApiClient.post(ApiEndpoints.assistanceRequests, body);
    final req = VetAssistanceRequest.fromJson(data);
    _requests.insert(0, req);
    notifyListeners();
    return req;
  }
}
