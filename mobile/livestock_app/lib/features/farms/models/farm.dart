class Farm {
  final int id;
  final String name;
  final String farmType;
  final int? areaId;
  final String? areaName;
  final String address;
  final String status;
  final String notes;
  final int owner;
  final String ownerUsername;
  final String createdAt;

  const Farm({
    required this.id,
    required this.name,
    required this.farmType,
    this.areaId,
    this.areaName,
    required this.address,
    required this.status,
    required this.notes,
    required this.owner,
    required this.ownerUsername,
    required this.createdAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: json['id'] as int,
        name: json['name'] as String,
        farmType: json['farm_type'] as String? ?? 'MIXED',
        areaId: json['area'] as int?,
        areaName: json['area_name'] as String?,
        address: json['address'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        notes: json['notes'] as String? ?? '',
        owner: json['owner'] as int,
        ownerUsername: json['owner_username'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  static const farmTypeLabels = {
    'DAIRY': 'Dairy',
    'BEEF': 'Beef',
    'POULTRY': 'Poultry',
    'MIXED': 'Mixed',
    'OTHER': 'Other',
  };

  String get farmTypeLabel => farmTypeLabels[farmType] ?? farmType;
  bool get isActive => status == 'ACTIVE';
}
