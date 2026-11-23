import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../../farms/providers/farm_provider.dart';
import '../../vaccinations/providers/vaccination_provider.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);

class AnimalListScreen extends StatefulWidget {
  final int? farmId;
  const AnimalListScreen({super.key, this.farmId});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  String _search = '';
  String? _selectedSpecies;

  static const _speciesFilters = [
    null,
    'CATTLE',
    'GOAT',
    'SHEEP',
    'PIG',
    'POULTRY',
    'OTHER',
  ];

  static const _speciesLabels = {
    null: 'All',
    'CATTLE': 'Cattle',
    'GOAT': 'Goat',
    'SHEEP': 'Sheep',
    'PIG': 'Pig',
    'POULTRY': 'Poultry',
    'OTHER': 'Other',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalProvider>().loadAnimals(farmId: widget.farmId);
    });
  }

  List<Animal> _filtered(List<Animal> all) {
    var list = widget.farmId != null
        ? all.where((a) => a.farmId == widget.farmId).toList()
        : all;
    if (_selectedSpecies != null) {
      list = list.where((a) => a.species == _selectedSpecies).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((a) =>
              a.displayName.toLowerCase().contains(q) ||
              a.tagNumber.toLowerCase().contains(q),)
          .toList();
    }
    return list;
  }

  String _speciesInitials(String species) {
    switch (species) {
      case 'CATTLE':
        return 'CT';
      case 'GOAT':
        return 'GT';
      case 'SHEEP':
        return 'SH';
      case 'PIG':
        return 'PG';
      case 'POULTRY':
        return 'PT';
      default:
        return 'AN';
    }
  }

  Color _speciesColor(String species) {
    switch (species) {
      case 'CATTLE':
        return _kPrimary;
      case 'GOAT':
        return const Color(0xFF2563EB);
      case 'SHEEP':
        return const Color(0xFF7C3AED);
      case 'PIG':
        return const Color(0xFFDB2777);
      case 'POULTRY':
        return const Color(0xFFD97706);
      default:
        return _kMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAnimals = context.watch<AnimalProvider>().animals;
    final loading = context.watch<AnimalProvider>().loading;
    final farms = context.watch<FarmProvider>().farms;
    final overdueIds = context
        .watch<VaccinationProvider>()
        .overdueSchedules
        .map((s) => s.animalId)
        .toSet();

    final filtered = _filtered(allAnimals);
    final firstFarmId =
        widget.farmId ?? (farms.isNotEmpty ? farms.first.id : null);

    final farmName = farms.isNotEmpty ? farms.first.name : null;
    final subtitle = widget.farmId == null
        ? '${allAnimals.length} animal${allAnimals.length == 1 ? '' : 's'}${farmName != null ? ' · $farmName' : ''}'
        : '${filtered.length} animal${filtered.length == 1 ? '' : 's'}';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My animals',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (firstFarmId != null) {
                        context.go('/farms/$firstFarmId/animals/new');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Create a farm first'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Add animal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                height: 44,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or tag number',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: _kMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: _kMuted, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5DBD2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5DBD2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                  ),
                ),
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _speciesFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sp = _speciesFilters[i];
                  final isSelected = _selectedSpecies == sp;
                  final count = sp == null
                      ? allAnimals.length
                      : allAnimals.where((a) => a.species == sp).length;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSpecies = sp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? _kPrimary : _kBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${_speciesLabels[sp]} ($count)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? Colors.white : _kDark,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Animal list
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pets,
                                size: 48,
                                color: _kMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _search.isNotEmpty
                                    ? 'No animals match your search'
                                    : 'No animals registered yet',
                                style: const TextStyle(
                                  color: _kMuted,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context
                              .read<AnimalProvider>()
                              .loadAnimals(farmId: widget.farmId),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final animal = filtered[i];
                              final isOverdue =
                                  overdueIds.contains(animal.id);
                              return _AnimalCard(
                                animal: animal,
                                isOverdue: isOverdue,
                                initials: _speciesInitials(animal.species),
                                avatarColor: _speciesColor(animal.species),
                                onTap: () =>
                                    context.go('/animals/${animal.id}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final Animal animal;
  final bool isOverdue;
  final String initials;
  final Color avatarColor;
  final VoidCallback onTap;

  const _AnimalCard({
    required this.animal,
    required this.isOverdue,
    required this.initials,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge;
    if (isOverdue) {
      badge = const _StatusBadge(
        text: 'Vaccine overdue',
        bg: Color(0xFFFDECEA),
        textColor: Color(0xFFB42318),
      );
    } else if (animal.status == 'UNDER_TREATMENT') {
      badge = const _StatusBadge(
        text: 'Under treatment',
        bg: Color(0xFFFFF3DC),
        textColor: Color(0xFF7A4A00),
      );
    } else if (animal.isActive) {
      badge = const _StatusBadge(
        text: 'Healthy',
        bg: Color(0xFFE3F0E8),
        textColor: Color(0xFF1E6B45),
      );
    } else {
      badge = _StatusBadge(
        text: animal.status,
        bg: const Color(0xFFEEF0EB),
        textColor: const Color(0xFF3E4A43),
      );
    }

    final meta = [
      animal.speciesLabel,
      if (animal.breed.isNotEmpty) animal.breed,
      animal.sexLabel,
      if (animal.dateOfBirth != null) _age(animal.dateOfBirth!),
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }

  String _age(String dob) {
    final birth = DateTime.tryParse(dob);
    if (birth == null) return '';
    final months = DateTime.now().difference(birth).inDays ~/ 30;
    if (months < 12) return '${months}mo';
    return '${months ~/ 12}yr';
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _StatusBadge({
    required this.text,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
