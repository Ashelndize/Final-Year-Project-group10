import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class AnimalListScreen extends StatefulWidget {
  final int? farmId;
  const AnimalListScreen({super.key, this.farmId});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalProvider>().loadAnimals(farmId: widget.farmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animals'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.farmId != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.go('/farms/${widget.farmId}/animals/new'),
              icon: const Icon(Icons.add),
              label: const Text('Register'),
              backgroundColor: Colors.green,
            )
          : null,
      body: Consumer<AnimalProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const LoadingWidget(message: 'Loading animals...');
          }
          if (provider.error != null) {
            return ErrorWidget2(
              message: provider.error!,
              onRetry: () =>
                  provider.loadAnimals(farmId: widget.farmId),
            );
          }
          final animals = widget.farmId != null
              ? provider.animalsForFarm(widget.farmId!)
              : provider.animals;
          if (animals.isEmpty) {
            return EmptyWidget(
              message: 'No animals registered yet.',
              actionLabel: widget.farmId != null ? 'Register Animal' : null,
              onAction: widget.farmId != null
                  ? () => context.go('/farms/${widget.farmId}/animals/new')
                  : null,
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAnimals(farmId: widget.farmId),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: animals.length,
              itemBuilder: (_, i) {
                final animal = animals[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.pets, color: Colors.blue),
                    ),
                    title: Text(
                      animal.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${animal.speciesLabel} · ${animal.tagNumber} · ${animal.sexLabel}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/animals/${animal.id}'),
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
