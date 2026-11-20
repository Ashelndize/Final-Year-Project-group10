import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class HealthFormScreen extends StatefulWidget {
  final int animalId;
  const HealthFormScreen({super.key, required this.animalId});

  @override
  State<HealthFormScreen> createState() => _HealthFormScreenState();
}

class _HealthFormScreenState extends State<HealthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _status = 'HEALTHY';
  DateTime _recordDate = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _tempCtrl.dispose();
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<HealthProvider>().createRecord(
          animalId: widget.animalId,
          recordDate: _formatDate(_recordDate),
          healthStatus: _status,
          weightKg: _weightCtrl.text.trim().isNotEmpty
              ? _weightCtrl.text.trim()
              : null,
          temperatureC: _tempCtrl.text.trim().isNotEmpty
              ? _tempCtrl.text.trim()
              : null,
          symptoms: _symptomsCtrl.text.trim(),
          diagnosis: _diagnosisCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      AppSnackBar.show(context, 'Health record saved!');
      context.go('/animals/${widget.animalId}/health');
    } else {
      final err = context.read<HealthProvider>().error;
      AppSnackBar.show(
        context,
        err ?? 'Failed to save record.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Record'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Record Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDate(_recordDate)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Health Status *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'HEALTHY', child: Text('Healthy')),
                  DropdownMenuItem(value: 'SICK', child: Text('Sick')),
                  DropdownMenuItem(
                    value: 'UNDER_TREATMENT',
                    child: Text('Under Treatment'),
                  ),
                  DropdownMenuItem(
                    value: 'RECOVERED',
                    child: Text('Recovered'),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symptomsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Symptoms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Record',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
