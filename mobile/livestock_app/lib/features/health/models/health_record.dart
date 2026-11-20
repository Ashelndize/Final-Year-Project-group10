class HealthRecord {
  final int id;
  final int animalId;
  final String animalTag;
  final int? recordedById;
  final String recordedByUsername;
  final String recordDate;
  final String? weightKg;
  final String? temperatureC;
  final String healthStatus;
  final String symptoms;
  final String diagnosis;
  final String notes;
  final String createdAt;

  const HealthRecord({
    required this.id,
    required this.animalId,
    required this.animalTag,
    this.recordedById,
    required this.recordedByUsername,
    required this.recordDate,
    this.weightKg,
    this.temperatureC,
    required this.healthStatus,
    required this.symptoms,
    required this.diagnosis,
    required this.notes,
    required this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id: json['id'] as int,
        animalId: json['animal'] as int,
        animalTag: json['animal_tag'] as String? ?? '',
        recordedById: json['recorded_by'] as int?,
        recordedByUsername: json['recorded_by_username'] as String? ?? '',
        recordDate: json['record_date'] as String,
        weightKg: json['weight_kg'] as String?,
        temperatureC: json['temperature_c'] as String?,
        healthStatus: json['health_status'] as String? ?? 'HEALTHY',
        symptoms: json['symptoms'] as String? ?? '',
        diagnosis: json['diagnosis'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  static const statusLabels = {
    'HEALTHY': 'Healthy',
    'SICK': 'Sick',
    'UNDER_TREATMENT': 'Under Treatment',
    'RECOVERED': 'Recovered',
    'DECEASED': 'Deceased',
  };

  String get statusLabel => statusLabels[healthStatus] ?? healthStatus;

  static const statusColors = {
    'HEALTHY': 0xFF4CAF50,
    'SICK': 0xFFF44336,
    'UNDER_TREATMENT': 0xFFFF9800,
    'RECOVERED': 0xFF2196F3,
    'DECEASED': 0xFF9E9E9E,
  };

  int get statusColor => statusColors[healthStatus] ?? 0xFF9E9E9E;
}
