import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Official Announcements')),
      body: Consumer<AnnouncementProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: provider.loadAnnouncements,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.announcements.isEmpty) {
            return const Center(child: Text('No announcements available.'));
          }
          return RefreshIndicator(
            onRefresh: provider.loadAnnouncements,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.announcements.length,
              itemBuilder: (context, index) {
                final ann = provider.announcements[index];
                return _AnnouncementCard(
                  announcement: ann,
                  onTap: () => context.push('/announcements/${ann.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final OfficialAnnouncement announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,),
                    decoration: BoxDecoration(
                      color: announcement.typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: announcement.typeColor.withValues(alpha: 0.5),),
                    ),
                    child: Text(
                      announcement.announcementTypeDisplay.isNotEmpty
                          ? announcement.announcementTypeDisplay
                          : announcement.announcementType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: announcement.typeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,),
                    decoration: BoxDecoration(
                      color: announcement.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      announcement.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: announcement.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (announcement.affectedAreaName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      announcement.affectedAreaName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(announcement.audienceIcon,
                      size: 13, color: announcement.audienceColor,),
                  const SizedBox(width: 4),
                  Text(
                    announcement.targetAudienceDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: announcement.audienceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (announcement.publishedAt != null) ...[
                    const SizedBox(width: 10),
                    const Text('·', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 10),
                    Text(
                      'Published ${_formatDate(announcement.publishedAt!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
