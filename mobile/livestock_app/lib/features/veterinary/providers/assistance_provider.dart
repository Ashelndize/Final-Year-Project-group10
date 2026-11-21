import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/offline/offline_database.dart';
import '../../../core/offline/offline_queue_exception.dart';
import '../../../core/offline/offline_queue_item.dart';
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
    // Offline check — queue if no connection.
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet,);
    if (!isOnline) {
      await OfflineDatabase.enqueue(OfflineQueueItem(
        id: const Uuid().v4(),
        operationType: OfflineOperationType.vetRequest,
        endpoint: ApiEndpoints.assistanceRequests,
        payload: body,
        createdAt: DateTime.now(),
      ),);
      throw const OfflineQueueException();
    }

    final data = await ApiClient.post(ApiEndpoints.assistanceRequests, body);
    final req = VetAssistanceRequest.fromJson(data);
    _requests.insert(0, req);
    notifyListeners();
    return req;
  }
}
