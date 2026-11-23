import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/assistance_provider.dart';
import '../models/vet_assistance_request.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kLightGreen = Color(0xFFE3F0E8);

class VetRequestsScreen extends StatefulWidget {
  const VetRequestsScreen({super.key});

  @override
  State<VetRequestsScreen> createState() => _VetRequestsScreenState();
}

class _VetRequestsScreenState extends State<VetRequestsScreen> {
  bool _available = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistanceProvider>().loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();
    final user = context.watch<AuthProvider>().user;

    final pending = provider.requests.where((r) => r.isPending).toList();
    final accepted = provider.requests.where((r) => r.isAccepted).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Dr. ${user?.lastName.isNotEmpty == true ? user!.lastName : (user?.username ?? '')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Veterinarian',
                          style: TextStyle(fontSize: 14, color: _kMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6,),
                      decoration: BoxDecoration(
                        color: _kLightGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: _kPrimary, size: 14),
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
              ),
            ),

            // Availability toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available for requests',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Farmers nearby can send you requests',
                              style: TextStyle(fontSize: 13, color: _kMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _available,
                        onChanged: (v) => setState(() => _available = v),
                        activeThumbColor: _kPrimary,
                        activeTrackColor: _kLightGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stat cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: pending.length.toString(),
                        label: 'New requests',
                        valueColor: const Color(0xFF9A5B00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: accepted.length.toString(),
                        label: 'Accepted',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: provider.requests
                            .where((r) => r.status == 'IN_PROGRESS')
                            .length
                            .toString(),
                        label: 'Follow-up today',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // New requests section
            if (pending.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'New requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _RequestCard(
                      request: pending[i],
                      onTap: () =>
                          context.go('/vet/requests/${pending[i].id}'),
                    ),
                  ),
                  childCount: pending.length,
                ),
              ),
            ],

            // Accepted / Today section
            if (accepted.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _FollowUpCard(request: accepted[i]),
                  ),
                  childCount: accepted.length,
                ),
              ),
            ],

            // Empty state
            if (!provider.loading &&
                provider.error == null &&
                provider.requests.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No requests at the moment.',
                      style: TextStyle(fontSize: 15, color: _kMuted),
                    ),
                  ),
                ),
              ),

            if (provider.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            if (provider.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? _kDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final VetAssistanceRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${request.farmerUsername} · ${request.farmName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                Text(
                  _timeAgo(request.createdAt),
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (request.animalName != null)
              Text(
                request.animalName!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF3E4A43)),
              ),
            const SizedBox(height: 4),
            Text(
              '"${request.description}"',
              style: const TextStyle(fontSize: 14, color: _kDark),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.areaName.isNotEmpty ? request.areaName : '—',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
                const Text(
                  'View request',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  final VetAssistanceRequest request;

  const _FollowUpCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: _kPrimary, size: 22,),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow-up · ${request.animalName ?? request.farmName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.farmName} · ${request.areaName}',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kMuted, size: 20),
        ],
      ),
    );
  }
}
