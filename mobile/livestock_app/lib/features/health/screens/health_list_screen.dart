import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class HealthListScreen extends StatefulWidget {
  final int animalId;
  const HealthListScreen({super.key, required this.animalId});

  @override
  State<HealthListScreen> createState() => _HealthListScreenState();
}

class _HealthListScreenState extends State<HealthListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().loadRecords(animalId: widget.animalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/animals/${widget.animalId}/health/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<HealthProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const LoadingWidget(message: 'Loading health records...');
          }
          if (provider.error != null) {
            return ErrorWidget2(
              message: provider.error!,
              onRetry: () =>
                  provider.loadRecords(animalId: widget.animalId),
            );
          }
          final records = provider.recordsForAnimal(widget.animalId);
          if (records.isEmpty) {
            return EmptyWidget(
              message: 'No health records yet.',
              actionLabel: 'Add Record',
              onAction: () =>
                  context.go('/animals/${widget.animalId}/health/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                provider.loadRecords(animalId: widget.animalId),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (_, i) {
                final r = records[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Color(r.statusColor).withValues(alpha: 0.15),
                      child: Icon(
                        Icons.medical_services,
                        color: Color(r.statusColor),
                      ),
                    ),
                    title: Text(
                      r.statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      r.recordDate +
                          (r.symptoms.isNotEmpty ? ' · ${r.symptoms}' : ''),
                    ),
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
