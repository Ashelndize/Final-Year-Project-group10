import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'connectivity_service.dart';
import 'offline_database.dart';
import 'offline_queue_item.dart';

/// Processes the offline sync queue whenever connectivity is restored.
///
/// Strategy:
///   - FIFO replay: items are processed oldest-first.
///   - 4xx response → mark FAILED (permanent; will not retry).
///   - 5xx / timeout → increment retryCount; leave as pending (retried on next sync).
///   - Server response wins on all conflicts (server-side records take precedence).
///   - Queue is cleared entirely on logout via [clearQueue].
class SyncService with ChangeNotifier {
  static const int _maxRetries = 3;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  final ConnectivityService _connectivity;

  SyncService(this._connectivity) {
    _connectivity.addListener(_onConnectivityChange);
    _refreshCount();
  }

  void _onConnectivityChange() {
    if (_connectivity.isOnline) {
      processQueue();
    }
  }

  Future<void> _refreshCount() async {
    _pendingCount = await OfflineDatabase.pendingCount();
    notifyListeners();
  }

  /// Enqueue a write operation for later sync.
  Future<void> enqueue(OfflineQueueItem item) async {
    await OfflineDatabase.enqueue(item);
    await _refreshCount();
  }

  /// Process all pending queue items in FIFO order.
  Future<void> processQueue() async {
    if (_syncing || !_connectivity.isOnline) return;
    _syncing = true;
    notifyListeners();

    try {
      final items = await OfflineDatabase.pendingItems();
      for (final item in items) {
        if (!_connectivity.isOnline) break; // stop if we go offline mid-sync
        await _processItem(item);
      }
    } finally {
      _syncing = false;
      await _refreshCount();
    }
  }

  Future<void> _processItem(OfflineQueueItem item) async {
    try {
      await ApiClient.post(item.endpoint, item.payload);
      // Success — remove from queue.
      await OfflineDatabase.remove(item.id);
    } on ApiException catch (e) {
      if (e.statusCode >= 400 && e.statusCode < 500) {
        // Client error (bad data) — permanent failure, do not retry.
        item.status = OfflineQueueStatus.failed;
        item.errorMessage = e.message;
        await OfflineDatabase.updateItem(item);
      } else {
        // Server error — schedule for retry.
        item.retryCount += 1;
        item.errorMessage = e.message;
        if (item.retryCount >= _maxRetries) {
          item.status = OfflineQueueStatus.failed;
        }
        await OfflineDatabase.updateItem(item);
      }
    } catch (e) {
      // Timeout or network error — schedule for retry.
      item.retryCount += 1;
      item.errorMessage = e.toString();
      if (item.retryCount >= _maxRetries) {
        item.status = OfflineQueueStatus.failed;
      }
      await OfflineDatabase.updateItem(item);
    }
  }

  /// Clear the entire queue — must be called on user logout to prevent
  /// another user from syncing a previous user's data.
  Future<void> clearQueue() async {
    await OfflineDatabase.clearAll();
    await _refreshCount();
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChange);
    super.dispose();
  }
}
