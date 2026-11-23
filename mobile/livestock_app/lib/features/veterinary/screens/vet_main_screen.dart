import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'vet_requests_screen.dart';
import 'vet_reports_screen.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);
const _kLightGreen = Color(0xFFE3F0E8);
const _kRed = Color(0xFFB42318);

class VetMainScreen extends StatefulWidget {
  const VetMainScreen({super.key});

  @override
  State<VetMainScreen> createState() => _VetMainScreenState();
}

class _VetMainScreenState extends State<VetMainScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _NavItem(label: 'Requests', icon: Icons.inbox_outlined),
    _NavItem(label: 'Reports', icon: Icons.description_outlined),
    _NavItem(label: 'Alerts', icon: Icons.notifications_outlined),
    _NavItem(label: 'Profile', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          VetRequestsScreen(),
          VetReportsScreen(),
          _VetAlertsTab(),
          _VetProfileTab(),
        ],
      ),

      bottomNavigationBar: _VetBottomNav(
        currentIndex: _currentIndex,
        items: _tabs,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _VetBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _VetBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 28,
                    decoration: isActive
                        ? BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: BorderRadius.circular(14),
                          )
                        : null,
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: isActive ? _kPrimary : _kMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? _kPrimary : _kMuted,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _VetAlertsTab extends StatelessWidget {
  const _VetAlertsTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  'No alerts at this time.',
                  style: TextStyle(fontSize: 15, color: _kMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VetProfileTab extends StatelessWidget {
  const _VetProfileTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          backgroundColor: _kLightGreen,
                          child: Text(
                            (user?.firstName.isNotEmpty == true
                                    ? user!.firstName[0]
                                    : user?.username.isNotEmpty == true
                                        ? user!.username[0]
                                        : 'V')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName.isNotEmpty == true
                                    ? 'Dr. ${user!.fullName}'
                                    : user?.username ?? 'Veterinarian',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _kDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Veterinarian',
                                style: TextStyle(fontSize: 13, color: _kMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5,),
                          decoration: BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: _kPrimary, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user?.email.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      const Divider(color: _kBorder),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 16, color: _kMuted,),
                          const SizedBox(width: 8),
                          Text(
                            user!.email,
                            style:
                                const TextStyle(fontSize: 14, color: _kMuted),
                          ),
                        ],
                      ),
                    ],
                    if (user?.phone.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 16, color: _kMuted,),
                          const SizedBox(width: 8),
                          Text(
                            user!.phone,
                            style:
                                const TextStyle(fontSize: 14, color: _kMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout, color: _kRed),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: _kRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
