class VaccinationSchedule {
  final int id;
  final int animalId;
  final String animalTag;
  final int protocolId;
  final String protocolName;
  final String dueDate;
  final String status;
  final int? vaccinationRecordId;

  const VaccinationSchedule({
    required this.id,
    required this.animalId,
    required this.animalTag,
    required this.protocolId,
    required this.protocolName,
    required this.dueDate,
    required this.status,
    this.vaccinationRecordId,
  });

  factory VaccinationSchedule.fromJson(Map<String, dynamic> json) =>
      VaccinationSchedule(
        id: json['id'] as int,
        animalId: json['animal'] as int,
        animalTag: json['animal_tag'] as String? ?? '',
        protocolId: json['protocol'] as int,
        protocolName: json['protocol_name'] as String? ?? '',
        dueDate: json['due_date'] as String,
        status: json['status'] as String? ?? 'PENDING',
        vaccinationRecordId: json['vaccination_record'] as int?,
      );

  static const statusColors = {
    'PENDING': 0xFF2196F3,
    'COMPLETED': 0xFF4CAF50,
    'OVERDUE': 0xFFF44336,
    'SKIPPED': 0xFF9E9E9E,
  };

  int get statusColor => statusColors[status] ?? 0xFF9E9E9E;

  bool get isOverdue => status == 'OVERDUE';
  bool get isPending => status == 'PENDING';
}
