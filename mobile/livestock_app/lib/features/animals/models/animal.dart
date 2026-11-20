class Animal {
  final int id;
  final int farmId;
  final String farmName;
  final String tagNumber;
  final String name;
  final String species;
  final String breed;
  final String sex;
  final String? dateOfBirth;
  final String? weightKg;
  final String status;
  final String notes;
  final String createdAt;

  const Animal({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.tagNumber,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    this.dateOfBirth,
    this.weightKg,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: json['id'] as int,
        farmId: json['farm'] as int,
        farmName: json['farm_name'] as String? ?? '',
        tagNumber: json['tag_number'] as String,
        name: json['name'] as String? ?? '',
        species: json['species'] as String,
        breed: json['breed'] as String? ?? '',
        sex: json['sex'] as String? ?? 'U',
        dateOfBirth: json['date_of_birth'] as String?,
        weightKg: json['weight_kg'] as String?,
        status: json['status'] as String? ?? 'ACTIVE',
        notes: json['notes'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  static const speciesLabels = {
    'CATTLE': 'Cattle',
    'GOAT': 'Goat',
    'SHEEP': 'Sheep',
    'POULTRY': 'Poultry',
    'PIG': 'Pig',
    'OTHER': 'Other',
  };

  static const sexLabels = {'M': 'Male', 'F': 'Female', 'U': 'Unknown'};

  String get speciesLabel => speciesLabels[species] ?? species;
  String get sexLabel => sexLabels[sex] ?? sex;
  String get displayName => name.isNotEmpty ? name : tagNumber;
  bool get isActive => status == 'ACTIVE';
}
