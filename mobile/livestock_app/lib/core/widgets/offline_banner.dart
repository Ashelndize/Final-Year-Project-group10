import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../offline/connectivity_service.dart';
import '../offline/sync_service.dart';

/// Displays a dismissible amber bar when the device is offline.
/// Wraps [child] and overlays the banner at the top using a [Column].
class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final sync = context.watch<SyncService>();

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOnline
              ? (sync.pendingCount > 0
                  ? _SyncingBar(count: sync.pendingCount, syncing: sync.isSyncing)
                  : const SizedBox.shrink())
              : const _OfflineBar(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Changes will sync when you reconnect.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncingBar extends StatelessWidget {
  final int count;
  final bool syncing;
  const _SyncingBar({required this.count, required this.syncing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.green.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          if (syncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white,),
            )
          else
            const Icon(Icons.cloud_upload, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              syncing
                  ? 'Syncing $count offline record(s)...'
                  : '$count record(s) queued — tap to sync now.',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (!syncing)
            GestureDetector(
              onTap: () =>
                  context.read<SyncService>().processQueue(),
              child: const Text(
                'Sync',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,),
              ),
            ),
        ],
      ),
    );
  }
}
