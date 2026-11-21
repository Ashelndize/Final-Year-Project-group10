import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final StreamSubscription<List<ConnectivityResult>> _sub;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Set initial state.
    final results = await Connectivity().checkConnectivity();
    _isOnline = _hasConnection(results);
    notifyListeners();

    // Monitor changes.
    _sub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
