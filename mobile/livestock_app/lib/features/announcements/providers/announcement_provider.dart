import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AnnouncementProvider extends ChangeNotifier {
  List<OfficialAnnouncement> _announcements = [];
  bool _loading = false;
  String? _error;

  List<OfficialAnnouncement> get announcements => _announcements;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAnnouncements() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getList(ApiEndpoints.announcements);
      final list = data['results'] as List<dynamic>? ?? [];
      _announcements = list
          .map((e) => OfficialAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
