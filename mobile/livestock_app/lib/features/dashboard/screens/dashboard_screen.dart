import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../farms/providers/farm_provider.dart';
import '../../animals/providers/animal_provider.dart';
import '../../vaccinations/providers/vaccination_provider.dart';
import '../../notifications/providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<FarmProvider>().loadFarms();
    context.read<AnimalProvider>().loadAnimals();
    context.read<VaccinationProvider>().loadSchedules();
    context.read<NotificationProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((a) => a.user);
    final farms = context.select<FarmProvider, int>((f) => f.farms.length);
    final animals = context.select<AnimalProvider, int>((a) => a.animals.length);
    final overdue = context
        .select<VaccinationProvider, int>((v) => v.overdueSchedules.length);
    final unread =
        context.select<NotificationProvider, int>((n) => n.unreadCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/notifications'),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome, ${user?.firstName.isNotEmpty == true ? user!.firstName : user?.username ?? 'User'}!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.isVet == true ? 'Veterinarian Portal' : 'Farmer Portal',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _SummaryCard(
                  icon: Icons.agriculture,
                  label: 'Farms',
                  value: '$farms',
                  color: Colors.green,
                  onTap: () => context.go('/farms'),
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  icon: Icons.pets,
                  label: 'Animals',
                  value: '$animals',
                  color: Colors.blue,
                  onTap: () => context.go('/farms'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryCard(
                  icon: Icons.vaccines,
                  label: 'Overdue',
                  value: '$overdue',
                  color: overdue > 0 ? Colors.red : Colors.grey,
                  onTap: () => context.go('/vaccinations'),
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  icon: Icons.notifications,
                  label: 'Unread',
                  value: '$unread',
                  color: unread > 0 ? Colors.orange : Colors.grey,
                  onTap: () => context.go('/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI Health Assistant banner
            InkWell(
              onTap: () => context.go('/assistant'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Health Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'General livestock health information',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (user?.isVet == true) ...[
              _QuickAction(
                icon: Icons.assignment_outlined,
                label: 'Submit Disease Report',
                onTap: () => context.go('/reports/new'),
              ),
              _QuickAction(
                icon: Icons.list_alt,
                label: 'My Disease Reports',
                onTap: () => context.go('/reports'),
              ),
              _QuickAction(
                icon: Icons.local_hospital_outlined,
                label: 'Assistance Requests',
                onTap: () => context.go('/assistance'),
              ),
              _QuickAction(
                icon: Icons.campaign_outlined,
                label: 'Official Announcements',
                onTap: () => context.go('/announcements'),
              ),
            ] else ...[
              _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Register New Farm',
                onTap: () => context.go('/farms/new'),
              ),
              _QuickAction(
                icon: Icons.list_alt,
                label: 'My Farms',
                onTap: () => context.go('/farms'),
              ),
              _QuickAction(
                icon: Icons.vaccines,
                label: 'Vaccination Schedule',
                onTap: () => context.go('/vaccinations'),
              ),
              _QuickAction(
                icon: Icons.local_hospital_outlined,
                label: 'Find a Veterinarian',
                onTap: () => context.go('/vets'),
              ),
              _QuickAction(
                icon: Icons.campaign_outlined,
                label: 'Disease Announcements',
                onTap: () => context.go('/announcements'),
              ),
            ],
            _QuickAction(
              icon: Icons.psychology,
              label: 'AI Health Assistant',
              onTap: () => context.go('/assistant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
