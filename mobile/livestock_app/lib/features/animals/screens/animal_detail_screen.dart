import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';

class AnimalDetailScreen extends StatelessWidget {
  final int animalId;
  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context) {
    final animal = context.watch<AnimalProvider>().getById(animalId);
    if (animal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Animal')),
        body: const Center(child: Text('Animal not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(animal.displayName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Row('Tag Number', animal.tagNumber),
          if (animal.name.isNotEmpty) _Row('Name', animal.name),
          _Row('Species', animal.speciesLabel),
          if (animal.breed.isNotEmpty) _Row('Breed', animal.breed),
          _Row('Sex', animal.sexLabel),
          if (animal.dateOfBirth != null)
            _Row('Date of Birth', animal.dateOfBirth!),
          if (animal.weightKg != null)
            _Row('Weight', '${animal.weightKg} kg'),
          _Row('Status', animal.isActive ? 'Active' : animal.status),
          _Row('Farm', animal.farmName),
          if (animal.notes.isNotEmpty) _Row('Notes', animal.notes),
          const SizedBox(height: 24),
          const Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/animals/$animalId/health'),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Health Records'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/animals/$animalId/health/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Health Record'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
