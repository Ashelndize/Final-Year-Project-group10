class VetAssistanceRequest {
  final int id;
  final int farmer;
  final String farmerUsername;
  final int? vet;
  final String? vetUsername;
  final int farm;
  final String farmName;
  final int? animal;
  final String? animalName;
  final String description;
  final String status;
  final String statusDisplay;
  final double? farmerLatitude;
  final double? farmerLongitude;
  final String areaName;
  final bool locationConsent;
  final String vetNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  const VetAssistanceRequest({
    required this.id,
    required this.farmer,
    required this.farmerUsername,
    this.vet,
    this.vetUsername,
    required this.farm,
    required this.farmName,
    this.animal,
    this.animalName,
    required this.description,
    required this.status,
    required this.statusDisplay,
    this.farmerLatitude,
    this.farmerLongitude,
    required this.areaName,
    required this.locationConsent,
    required this.vetNotes,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
  });

  factory VetAssistanceRequest.fromJson(Map<String, dynamic> json) {
    return VetAssistanceRequest(
      id: json['id'] as int,
      farmer: json['farmer'] as int,
      farmerUsername: json['farmer_username'] as String? ?? '',
      vet: json['vet'] as int?,
      vetUsername: json['vet_username'] as String?,
      farm: json['farm'] as int,
      farmName: json['farm_name'] as String? ?? '',
      animal: json['animal'] as int?,
      animalName: json['animal_name'] as String?,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      statusDisplay: json['status_display'] as String? ?? 'Pending',
      farmerLatitude: json['farmer_latitude'] != null
          ? double.tryParse(json['farmer_latitude'].toString())
          : null,
      farmerLongitude: json['farmer_longitude'] != null
          ? double.tryParse(json['farmer_longitude'].toString())
          : null,
      areaName: json['area_name'] as String? ?? '',
      locationConsent: json['location_consent'] as bool? ?? false,
      vetNotes: json['vet_notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isOpen =>
      status == 'PENDING' || status == 'ACCEPTED' || status == 'IN_PROGRESS';
}
