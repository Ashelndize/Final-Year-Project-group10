import 'dart:convert';

enum OfflineOperationType { healthRecord, diseaseReport, vetRequest }

enum OfflineQueueStatus { pending, failed }

class OfflineQueueItem {
  final String id; // UUID idempotency key
  final OfflineOperationType operationType;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  OfflineQueueStatus status;
  int retryCount;
  String? errorMessage;

  OfflineQueueItem({
    required this.id,
    required this.operationType,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.status = OfflineQueueStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'operation_type': operationType.name,
        'endpoint': endpoint,
        'payload': jsonEncode(payload),
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'retry_count': retryCount,
        'error_message': errorMessage,
      };

  factory OfflineQueueItem.fromMap(Map<String, dynamic> map) =>
      OfflineQueueItem(
        id: map['id'] as String,
        operationType: OfflineOperationType.values
            .firstWhere((e) => e.name == map['operation_type']),
        endpoint: map['endpoint'] as String,
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: OfflineQueueStatus.values
            .firstWhere((e) => e.name == map['status']),
        retryCount: map['retry_count'] as int? ?? 0,
        errorMessage: map['error_message'] as String?,
      );
}
