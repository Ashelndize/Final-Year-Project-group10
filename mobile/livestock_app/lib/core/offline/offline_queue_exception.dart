/// Thrown when a write operation is queued for offline sync instead of
/// being sent immediately. The UI should treat this as a soft-success —
/// show the user that their data is saved and will sync when back online.
class OfflineQueueException implements Exception {
  final String message;
  const OfflineQueueException([
    this.message = 'Saved offline. Will sync when you reconnect.',
  ]);

  @override
  String toString() => message;
}
