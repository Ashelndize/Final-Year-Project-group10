import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';

class FarmDetailScreen extends StatelessWidget {
  final int farmId;
  const FarmDetailScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context) {
    final farm = context.watch<FarmProvider>().getFarmById(farmId);
    if (farm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm')),
        body: const Center(child: Text('Farm not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(farm.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow('Type', farm.farmTypeLabel),
          if (farm.areaName != null) _InfoRow('Area', farm.areaName!),
          if (farm.address.isNotEmpty) _InfoRow('Address', farm.address),
          _InfoRow('Status', farm.isActive ? 'Active' : 'Archived'),
          if (farm.notes.isNotEmpty) _InfoRow('Notes', farm.notes),
          const SizedBox(height: 24),
          const Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/farms/$farmId/animals'),
            icon: const Icon(Icons.pets),
            label: const Text('View Animals'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/farms/$farmId/animals/new'),
            icon: const Icon(Icons.add),
            label: const Text('Register Animal'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
