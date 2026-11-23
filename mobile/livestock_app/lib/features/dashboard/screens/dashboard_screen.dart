import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../farms/providers/farm_provider.dart';
import '../../animals/models/animal.dart';
import '../../animals/providers/animal_provider.dart';
import '../../vaccinations/providers/vaccination_provider.dart';
import '../../vaccinations/models/vaccination.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../announcements/models/announcement.dart';
import '../../veterinary/providers/assistance_provider.dart';

// Color palette
const kBg = Color(0xFFF5F6F1);
const kPrimary = Color(0xFF1E6B45);
const kDark = Color(0xFF1B2620);
const kMuted = Color(0xFF5B675F);
const kBorder = Color(0xFFE2E6DF);
const kLightGreen = Color(0xFFE3F0E8);
const kBlueBanner = Color(0xFF173F7A);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOffline = false;
  final int _pendingSync = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet,);
    if (mounted) {
      setState(() => _isOffline = !online);
    }
  }

  void _loadData() {
    context.read<FarmProvider>().loadFarms();
    context.read<AnimalProvider>().loadAnimals();
    context.read<VaccinationProvider>().loadSchedules();
    context.read<NotificationProvider>().loadNotifications();
    context.read<AnnouncementProvider>().loadAnnouncements();
    context.read<AssistanceProvider>().loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((a) => a.user);
    final farms = context.watch<FarmProvider>().farms;
    final animals = context.watch<AnimalProvider>().animals;
    final vaccSchedules = context.watch<VaccinationProvider>().schedules;
    final overdueSchedules = context.watch<VaccinationProvider>().overdueSchedules;
    final unread = context.select<NotificationProvider, int>((n) => n.unreadCount);
    final announcements = context.watch<AnnouncementProvider>().announcements;
    final requests = context.watch<AssistanceProvider>().requests;

    final published = announcements.where((a) => a.isPublished).toList();
    final latestAnnouncement = published.isNotEmpty ? published.first : null;
    final openRequests = requests.where((r) => r.isOpen).length;

    final firstName = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : user?.username ?? 'User';

    final farmName = farms.isNotEmpty ? farms.first.name : null;
    final farmArea = farms.isNotEmpty ? farms.first.areaName : null;

    // Build upcoming vaccination list: overdue first, then by date, max 3
    final upcoming = _buildUpcomingSchedules(vaccSchedules, animals);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await _checkConnectivity();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Muraho, $firstName!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              farmName != null
                                  ? '$farmName${farmArea != null ? ' · $farmArea' : ''}'
                                  : 'No farm yet',
                              style: const TextStyle(
                                fontSize: 14,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/notifications'),
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: kBorder),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 22,
                                color: kDark,
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Offline banner
                if (_isOffline || _pendingSync > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7A4A00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _pendingSync > 0
                                ? 'Offline · $_pendingSync changes waiting to sync'
                                : 'Offline',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A4A00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Announcement banner
                if (latestAnnouncement != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _AnnouncementBanner(announcement: latestAnnouncement),
                  ),

                // 4. 3-stat mini cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          value: '${animals.length}',
                          label: 'Animals',
                          valueColor: kDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStatCard(
                          value: '${overdueSchedules.length}',
                          label: 'Vaccines due',
                          valueColor: overdueSchedules.isNotEmpty
                              ? const Color(0xFFB25E00)
                              : kDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStatCard(
                          value: '$openRequests',
                          label: 'Vet requests',
                          valueColor: kDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Upcoming vaccinations
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming vaccinations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/vaccinations'),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: upcoming.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No upcoming vaccinations',
                                style: TextStyle(color: kMuted, fontSize: 14),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(upcoming.length, (i) {
                              final item = upcoming[i];
                              final isLast = i == upcoming.length - 1;
                              return Column(
                                children: [
                                  _VaccineRow(
                                    schedule: item.$1,
                                    animal: item.$2,
                                  ),
                                  if (!isLast)
                                    const Divider(
                                      height: 1,
                                      indent: 60,
                                      color: kBorder,
                                    ),
                                ],
                              );
                            }),
                          ),
                  ),
                ),

                // 6. Quick action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionBtn(
                          label: 'Register animal',
                          filled: true,
                          icon: Icons.add,
                          onTap: () {
                            if (farms.isNotEmpty) {
                              context.go(
                                  '/farms/${farms.first.id}/animals/new',);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Create a farm first'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionBtn(
                          label: 'Health event',
                          filled: false,
                          icon: Icons.favorite_border,
                          onTap: () {
                            if (animals.isNotEmpty) {
                              context.go(
                                  '/animals/${animals.first.id}/health/new',);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Register an animal first'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionBtn(
                          label: 'Find a vet',
                          filled: false,
                          icon: Icons.location_on_outlined,
                          onTap: () => context.go('/vets'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<(VaccinationSchedule, Animal?)> _buildUpcomingSchedules(
    List<VaccinationSchedule> schedules,
    List<Animal> animals,
  ) {
    final now = DateTime.now();
    final relevant = schedules.where((s) {
      if (s.status == 'COMPLETED' || s.status == 'SKIPPED') return false;
      final due = DateTime.tryParse(s.dueDate);
      if (due == null) return false;
      // Show overdue and upcoming within 30 days
      return s.isOverdue || due.difference(now).inDays <= 30;
    }).toList();

    relevant.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    final top3 = relevant.take(3).toList();
    return top3.map((s) {
      Animal? animal;
      try {
        animal = animals.firstWhere((a) => a.id == s.animalId);
      } catch (_) {
        animal = null;
      }
      return (s, animal);
    }).toList();
  }
}

class _AnnouncementBanner extends StatelessWidget {
  final OfficialAnnouncement announcement;
  const _AnnouncementBanner({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final dateStr = announcement.publishedAt != null
        ? '${announcement.publishedAt!.day}/${announcement.publishedAt!.month}/${announcement.publishedAt!.year}'
        : '';
    return GestureDetector(
      onTap: () => context.go('/announcements'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBlueBanner,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFD6E2F5),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'OFFICIAL ANNOUNCEMENT',
                  style: TextStyle(
                    color: Color(0xFFD6E2F5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${announcement.issuingAuthorityName ?? 'Authority'}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
              style: const TextStyle(
                color: Color(0xFFD6E2F5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Read prevention guidance →',
              style: TextStyle(
                color: Color(0xFFD6E2F5),
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFD6E2F5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineRow extends StatelessWidget {
  final VaccinationSchedule schedule;
  final Animal? animal;

  const _VaccineRow({required this.schedule, required this.animal});

  @override
  Widget build(BuildContext context) {
    final species = animal?.species ?? '';
    final initials = _speciesInitials(species);
    final avatarColor = _speciesColor(species);

    final dueDate = DateTime.tryParse(schedule.dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Widget badge;
    if (schedule.isOverdue && dueDate != null) {
      final days = today.difference(DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ),).inDays;
      badge = _Badge(
        text: 'Overdue $days day${days == 1 ? '' : 's'}',
        bg: const Color(0xFFFDECEA),
        textColor: const Color(0xFFB42318),
      );
    } else if (dueDate != null) {
      final diff = DateTime(dueDate.year, dueDate.month, dueDate.day)
          .difference(today)
          .inDays;
      if (diff == 0) {
        badge = const _Badge(
          text: 'Today',
          bg: Color(0xFFFFF3DC),
          textColor: Color(0xFF7A4A00),
        );
      } else if (diff == 1) {
        badge = const _Badge(
          text: 'Tomorrow',
          bg: Color(0xFFFFF3DC),
          textColor: Color(0xFF7A4A00),
        );
      } else {
        badge = _Badge(
          text: schedule.dueDate,
          bg: const Color(0xFFEEF0EB),
          textColor: const Color(0xFF3E4A43),
        );
      }
    } else {
      badge = const _Badge(
        text: 'Pending',
        bg: Color(0xFFEEF0EB),
        textColor: Color(0xFF3E4A43),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
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
                  animal?.displayName ?? schedule.animalTag,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                Text(
                  schedule.protocolName,
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          badge,
        ],
      ),
    );
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
        return kPrimary;
      case 'GOAT':
        return const Color(0xFF2563EB);
      case 'SHEEP':
        return const Color(0xFF7C3AED);
      case 'PIG':
        return const Color(0xFFDB2777);
      case 'POULTRY':
        return const Color(0xFFD97706);
      default:
        return kMuted;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _Badge({
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

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? kPrimary : kBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: filled ? Colors.white : kDark,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : kDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
