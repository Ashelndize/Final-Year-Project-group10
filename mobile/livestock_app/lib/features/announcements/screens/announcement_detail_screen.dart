import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final int announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    OfficialAnnouncement? ann;
    try {
      ann = provider.announcements
          .firstWhere((a) => a.id == announcementId);
    } catch (_) {
      ann = null;
    }

    if (ann == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcement')),
        body: const Center(child: Text('Announcement not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type + status + audience badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(
                  label: ann.announcementTypeDisplay.isNotEmpty
                      ? ann.announcementTypeDisplay
                      : ann.announcementType,
                  color: ann.typeColor,
                ),
                _Badge(label: ann.status, color: ann.statusColor),
                _Badge(
                  label: ann.targetAudienceDisplay,
                  color: ann.audienceColor,
                  icon: ann.audienceIcon,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              ann.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Meta info
            if (ann.issuingAuthorityName != null)
              _MetaRow(
                icon: Icons.person_outline,
                label: 'Issued by',
                value: ann.issuingAuthorityName!,
              ),
            if (ann.affectedAreaName.isNotEmpty)
              _MetaRow(
                icon: Icons.location_on_outlined,
                label: 'Affected area',
                value: ann.affectedAreaName,
              ),
            if (ann.affectedSpecies.isNotEmpty)
              _MetaRow(
                icon: Icons.pets,
                label: 'Affected species',
                value: ann.affectedSpecies,
              ),
            if (ann.publishedAt != null)
              _MetaRow(
                icon: Icons.calendar_today_outlined,
                label: 'Published',
                value: _formatDateTime(ann.publishedAt!),
              ),
            if (ann.expiresAt != null)
              _MetaRow(
                icon: Icons.timer_outlined,
                label: 'Expires',
                value: _formatDateTime(ann.expiresAt!),
              ),

            const Divider(height: 24),

            // Outbreak alert banner
            if (ann.isOutbreakAlert)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is an official outbreak alert issued by '
                        'veterinary authorities.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            const Text(
              'Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(ann.content, style: const TextStyle(fontSize: 14)),

            // Prevention guidance
            if (ann.preventionGuidance.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Prevention & Guidance',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  ann.preventionGuidance,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            // Withdrawal reason
            if (ann.isWithdrawn && ann.withdrawalReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawal reason',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(ann.withdrawalReason),
                    if (ann.withdrawnAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Withdrawn on ${_formatDateTime(ann.withdrawnAt!)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey,),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
