import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<FarmProvider>().loadFarms(),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/farms/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Farm'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<FarmProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const LoadingWidget(message: 'Loading farms...');
          }
          if (provider.error != null) {
            return ErrorWidget2(
              message: provider.error!,
              onRetry: provider.loadFarms,
            );
          }
          if (provider.farms.isEmpty) {
            return EmptyWidget(
              message: 'No farms yet.\nTap + to register your first farm.',
              actionLabel: 'Register Farm',
              onAction: () => context.go('/farms/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadFarms,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.farms.length,
              itemBuilder: (_, i) {
                final farm = provider.farms[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      child: const Icon(Icons.agriculture, color: Colors.green),
                    ),
                    title: Text(
                      farm.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${farm.farmTypeLabel}'
                      '${farm.areaName != null ? ' · ${farm.areaName}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!farm.isActive)
                          const Chip(
                            label: Text(
                              'Archived',
                              style: TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.go('/farms/${farm.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
