import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../reports/providers/report_provider.dart';
import '../../reports/models/disease_report.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);

class VetReportsScreen extends StatefulWidget {
  const VetReportsScreen({super.key});

  @override
  State<VetReportsScreen> createState() => _VetReportsScreenState();
}

class _VetReportsScreenState extends State<VetReportsScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Needs reply', 'In review', 'Closed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  List<DiseaseReport> _filtered(List<DiseaseReport> all) {
    switch (_filter) {
      case 'Needs reply':
        return all
            .where((r) => r.status == 'CLARIFICATION_REQUESTED')
            .toList();
      case 'In review':
        return all
            .where((r) =>
                r.status == 'SUBMITTED' || r.status == 'UNDER_REVIEW',)
            .toList();
      case 'Closed':
        return all
            .where((r) => r.status == 'REJECTED' || r.status == 'CLOSED')
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final reports = _filtered(provider.reports);
    final needsReplyCount = provider.reports
        .where((r) => r.status == 'CLARIFICATION_REQUESTED')
        .length;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My disease reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.reports.length} report${provider.reports.length == 1 ? '' : 's'}'
                        '${needsReplyCount > 0 ? ' · $needsReplyCount needs your reply' : ''}',
                        style: const TextStyle(fontSize: 14, color: _kMuted),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/vet/reports/new'),
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
                            'New',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isActive = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isActive ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive ? _kPrimary : const Color(0xFFD5DBD2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive ? Colors.white : _kDark,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // List
            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? Center(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : reports.isEmpty
                          ? const Center(
                              child: Text(
                                'No reports in this category.',
                                style: TextStyle(
                                    fontSize: 15, color: _kMuted,),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: reports.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) =>
                                  _ReportCard(report: reports[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final DiseaseReport report;
  const _ReportCard({required this.report});

  _BadgeStyle _badgeFor(String status) {
    switch (status) {
      case 'CLARIFICATION_REQUESTED':
        return const _BadgeStyle(
          bg: Color(0xFFFFF3DC),
          text: Color(0xFF7A4A00),
          border: Color(0xFFE8C27A),
          label: 'Clarification requested',
        );
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return const _BadgeStyle(
          bg: Color(0xFFE8EEF7),
          text: Color(0xFF173F7A),
          label: 'Under review',
        );
      case 'ACCEPTED_FOR_ASSESSMENT':
        return const _BadgeStyle(
          bg: Color(0xFFE3F0E8),
          text: Color(0xFF1E6B45),
          label: 'Accepted for assessment',
        );
      case 'REJECTED':
        return const _BadgeStyle(
          bg: Color(0xFFFDECEA),
          text: Color(0xFFB42318),
          label: 'Rejected',
        );
      case 'CLOSED':
        return const _BadgeStyle(
          bg: Color(0xFFEEF0EB),
          text: Color(0xFF3E4A43),
          label: 'Closed',
        );
      default:
        return _BadgeStyle(
          bg: const Color(0xFFEEF0EB),
          text: const Color(0xFF3E4A43),
          label: report.statusDisplay,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(report.status);
    final isClarification = report.status == 'CLARIFICATION_REQUESTED';

    return Container(
      padding: EdgeInsets.all(isClarification ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isClarification
            ? Border.all(color: const Color(0xFFE8C27A))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RPT-${report.id.toString().padLeft(4, '0')} · ${report.speciesDisplay}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badge.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            report.status == 'REJECTED'
                ? 'Reason: ${report.notes.isNotEmpty ? report.notes : '—'}'
                : '${report.areaName.isNotEmpty ? report.areaName : report.areaDisplay ?? ''}'
                    ' · ${report.observedSigns.isNotEmpty ? report.observedSigns : '—'}'
                    ' · ${report.observationDate}',
            style: const TextStyle(fontSize: 13, color: _kMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isClarification) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Reviewer: Please add photos of the mouth and feet.',
                style: TextStyle(fontSize: 14, color: _kDark, height: 1.45),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6B45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Reply to reviewer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color text;
  final Color? border;
  final String label;

  const _BadgeStyle({
    required this.bg,
    required this.text,
    this.border,
    required this.label,
  });
}
