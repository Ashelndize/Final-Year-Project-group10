import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/offline/offline_queue_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/assistance_provider.dart';
import '../../farms/providers/farm_provider.dart';

class AssistanceRequestFormScreen extends StatefulWidget {
  const AssistanceRequestFormScreen({super.key});

  @override
  State<AssistanceRequestFormScreen> createState() =>
      _AssistanceRequestFormScreenState();
}

class _AssistanceRequestFormScreenState
    extends State<AssistanceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  int? _selectedFarmId;
  bool _locationConsent = false;
  double? _lat;
  double? _lng;
  bool _fetchingLocation = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmProvider>().loadFarms();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
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
    if (_selectedFarmId == null) {
      AppSnackBar.show(context, 'Please select a farm.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'farm': _selectedFarmId,
        'description': _descCtrl.text.trim(),
        'area_name': _areaCtrl.text.trim(),
        'location_consent': _locationConsent,
        if (_locationConsent && _lat != null) 'farmer_latitude': _lat,
        if (_locationConsent && _lng != null) 'farmer_longitude': _lng,
      };
      await context.read<AssistanceProvider>().createRequest(body);
      if (mounted) {
        AppSnackBar.show(context, 'Assistance request submitted.');
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
    final farmProvider = context.watch<FarmProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Assistance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Farm', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _selectedFarmId,
                hint: const Text('Select farm'),
                items: farmProvider.farms
                    .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFarmId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description of the problem *',
                  border: OutlineInputBorder(),
                  helperText: 'Describe the symptoms or issue you are observing.',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area / Location name',
                  border: OutlineInputBorder(),
                  helperText: 'Enter your area if not sharing GPS location.',
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
                        'Sharing your GPS location helps veterinarians find you '
                        'faster. This is entirely optional — your location is '
                        'never shared without your consent.',
                        style: TextStyle(fontSize: 12),
                      ),
                      SwitchListTile(
                        title: const Text('Share my current location'),
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
                                child: CircularProgressIndicator(strokeWidth: 2),),
                            SizedBox(width: 8),
                            Text('Getting location…'),
                          ],),
                        ),
                      if (_lat != null && _lng != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            'Location captured: ${_lat!.toStringAsFixed(5)}, '
                            '${_lng!.toStringAsFixed(5)}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12,),
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
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
