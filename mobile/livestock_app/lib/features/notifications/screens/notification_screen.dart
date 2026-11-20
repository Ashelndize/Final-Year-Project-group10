import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () =>
                context.read<NotificationProvider>().markAllRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const LoadingWidget(message: 'Loading notifications...');
          }
          if (provider.error != null) {
            return ErrorWidget2(
              message: provider.error!,
              onRetry: provider.loadNotifications,
            );
          }
          if (provider.notifications.isEmpty) {
            return const EmptyWidget(message: 'No notifications.');
          }
          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (_, i) {
              final n = provider.notifications[i];
              return ListTile(
                leading: Icon(
                  n.isRead ? Icons.notifications_none : Icons.notifications,
                  color: n.isRead ? Colors.grey : Colors.green,
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight:
                        n.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                tileColor: n.isRead
                    ? null
                    : Colors.green.withValues(alpha: 0.04),
              );
            },
          );
        },
      ),
    );
  }
}
