import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../../vaccinations/providers/vaccination_provider.dart';
import '../../vaccinations/models/vaccination.dart';
import '../../health/providers/health_provider.dart';
import '../../health/models/health_record.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);

class AnimalDetailScreen extends StatefulWidget {
  final int animalId;
  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<HealthProvider>()
          .loadRecords(animalId: widget.animalId);
      context.read<VaccinationProvider>().loadSchedules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final animal =
        context.watch<AnimalProvider>().getById(widget.animalId);

    if (animal == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, null),
              const Expanded(
                child: Center(
                  child: Text(
                    'Animal not found.',
                    style: TextStyle(color: _kMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final schedules = context
        .watch<VaccinationProvider>()
        .schedulesForAnimal(widget.animalId);
    final overdueSchedules = schedules.where((s) => s.isOverdue).toList();
    final healthRecords = context
        .watch<HealthProvider>()
        .recordsForAnimal(widget.animalId);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, animal),
                _buildInfoCard(animal),
                if (overdueSchedules.isNotEmpty)
                  _buildOverdueAlert(context, overdueSchedules.first),
                _buildSegmentedTabs(),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HealthTab(records: healthRecords),
                _VaccinesTab(schedules: schedules),
                _TreatmentsTab(records: healthRecords),
              ],
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Animal? animal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: _kDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Animal profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
          ),
          if (animal != null)
            GestureDetector(
              onTap: () {
                // Edit navigation placeholder
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kBorder),
                ),
                child: const Center(
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kDark,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Animal animal) {
    final initials = _speciesInitials(animal.species);
    final color = _speciesColor(animal.species);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${animal.tagNumber} · ${animal.farmName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3,
              children: [
                _InfoTile(label: 'Species', value: animal.speciesLabel),
                _InfoTile(
                  label: 'Breed',
                  value: animal.breed.isNotEmpty ? animal.breed : 'Unknown',
                ),
                _InfoTile(label: 'Sex', value: animal.sexLabel),
                _InfoTile(
                  label: 'Born',
                  value: animal.dateOfBirth ?? 'Unknown',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueAlert(
    BuildContext context,
    VaccinationSchedule schedule,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFB42318),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${schedule.protocolName} overdue',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB42318),
                    ),
                  ),
                  Text(
                    'Was due ${schedule.dueDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon')),
                );
              },
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB42318)),
                ),
                child: const Center(
                  child: Text(
                    'Mark done',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9ECE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _kDark,
          unselectedLabelColor: _kMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Health'),
            Tab(text: 'Vaccines'),
            Tab(text: 'Treatments'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  context.go('/animals/${widget.animalId}/health/new'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Add record',
                style: TextStyle(
                  color: _kDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.go('/assistance/new'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Request a vet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  final List<HealthRecord> records;
  const _HealthTab({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No health records yet',
          style: TextStyle(color: _kMuted, fontSize: 15),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HealthRecordCard(record: records[i]),
    );
  }
}

class _HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  const _HealthRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isVet = record.recordedByUsername.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.recordDate,
                style: const TextStyle(fontSize: 13, color: _kMuted),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVet
                      ? const Color(0xFFE3F0E8)
                      : const Color(0xFFEEF0EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVet ? 'Recorded by vet' : 'Farmer observation',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isVet
                        ? _kPrimary
                        : const Color(0xFF3E4A43),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.statusLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          if (record.symptoms.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              record.symptoms,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Recorded by ${record.recordedByUsername.isNotEmpty ? record.recordedByUsername : 'unknown'}',
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _VaccinesTab extends StatelessWidget {
  final List<VaccinationSchedule> schedules;
  const _VaccinesTab({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const Center(
        child: Text(
          'No vaccination schedules',
          style: TextStyle(color: _kMuted, fontSize: 15),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VaccineCard(schedule: schedules[i]),
    );
  }
}

class _VaccineCard extends StatelessWidget {
  final VaccinationSchedule schedule;
  const _VaccineCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (schedule.isOverdue) {
      badgeBg = const Color(0xFFFDECEA);
      badgeText = const Color(0xFFB42318);
      badgeLabel = 'Overdue';
    } else if (schedule.status == 'COMPLETED') {
      badgeBg = const Color(0xFFE3F0E8);
      badgeText = _kPrimary;
      badgeLabel = 'Completed';
    } else {
      badgeBg = const Color(0xFFFFF3DC);
      badgeText = const Color(0xFF7A4A00);
      badgeLabel = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.protocolName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${schedule.dueDate}',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentsTab extends StatelessWidget {
  final List<HealthRecord> records;
  const _TreatmentsTab({required this.records});

  @override
  Widget build(BuildContext context) {
    final treatments =
        records.where((r) => r.healthStatus != 'HEALTHY').toList();
    if (treatments.isEmpty) {
      return const Center(
        child: Text(
          'No treatment records',
          style: TextStyle(color: _kMuted, fontSize: 15),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: treatments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HealthRecordCard(record: treatments[i]),
    );
  }
}
