import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/offline/offline_queue_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/report_provider.dart';

class DiseaseReportFormScreen extends StatefulWidget {
  const DiseaseReportFormScreen({super.key});

  @override
  State<DiseaseReportFormScreen> createState() =>
      _DiseaseReportFormScreenState();
}

class _DiseaseReportFormScreenState extends State<DiseaseReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _signsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String _species = 'CATTLE';
  DateTime _observationDate = DateTime.now();
  bool _locationConsent = false;
  double? _lat;
  double? _lng;
  bool _fetchingLocation = false;
  bool _submitting = false;

  static const _speciesOptions = [
    ('CATTLE', 'Cattle'),
    ('GOAT', 'Goat'),
    ('SHEEP', 'Sheep'),
    ('PIG', 'Pig'),
    ('CHICKEN', 'Chicken'),
    ('OTHER', 'Other'),
  ];

  @override
  void dispose() {
    _signsCtrl.dispose();
    _notesCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _observationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _observationDate = picked);
  }

  Future<void> _handleLocationConsent(bool value) async {
    setState(() => _locationConsent = value);
    if (!value) {
      setState(() {
        _lat = null;
        _lng = null;
      });
      return;
    }
    setState(() => _fetchingLocation = true);
    final result = await LocationService.requestAndGetLocation();
    setState(() {
      _fetchingLocation = false;
      if (result.hasLocation) {
        _lat = result.latitude;
        _lng = result.longitude;
      } else {
        _locationConsent = false;
        if (result.errorMessage != null) {
          AppSnackBar.show(context, result.errorMessage!, error: true);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_areaCtrl.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        'Please enter an area name or select your area.',
        error: true,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'species': _species,
        'observation_date':
            '${_observationDate.year}-${_observationDate.month.toString().padLeft(2, '0')}-${_observationDate.day.toString().padLeft(2, '0')}',
        'area_name': _areaCtrl.text.trim(),
        'observed_signs': _signsCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'location_consent': _locationConsent,
        if (_locationConsent && _lat != null) 'report_latitude': _lat,
        if (_locationConsent && _lng != null) 'report_longitude': _lng,
      };
      await context.read<ReportProvider>().submitReport(body);
      if (mounted) {
        AppSnackBar.show(
            context, 'Report submitted. It is under review by authorities.',);
        Navigator.pop(context);
      }
    } on OfflineQueueException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.toString());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Disease Observation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.amber.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This report is an observation only. It is not a '
                          'confirmed disease diagnosis. Authorized veterinary '
                          'authorities will review all reports before any '
                          'official announcement is made.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Species *',
                  style: TextStyle(fontWeight: FontWeight.bold,),),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _species,
                items: _speciesOptions
                    .map((s) =>
                        DropdownMenuItem(value: s.$1, child: Text(s.$2),),)
                    .toList(),
                onChanged: (v) => setState(() => _species = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Date of Observation *',
                  style: TextStyle(fontWeight: FontWeight.bold,),),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_observationDate.year}-'
                    '${_observationDate.month.toString().padLeft(2, '0')}-'
                    '${_observationDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area / Location *',
                  border: OutlineInputBorder(),
                  helperText: 'Enter district, town, or farm area.',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observed signs and symptoms *',
                  border: OutlineInputBorder(),
                  helperText:
                      'Describe what you observed: symptoms, behaviour, number of animals affected.',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location sharing (optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sharing your GPS coordinates helps authorities identify '
                        'affected areas more accurately. This is entirely optional.',
                        style: TextStyle(fontSize: 12),
                      ),
                      SwitchListTile(
                        title: const Text('Share my current GPS coordinates'),
                        value: _locationConsent,
                        onChanged:
                            _fetchingLocation ? null : _handleLocationConsent,
                      ),
                      if (_fetchingLocation)
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Row(children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Getting location…'),
                          ],),
                        ),
                      if (_lat != null && _lng != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            'Captured: ${_lat!.toStringAsFixed(5)}, '
                            '${_lng!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
