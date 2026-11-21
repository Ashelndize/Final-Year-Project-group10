import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/app_widgets.dart';

class _VetProfile {
  final int id;
  final String username;
  final String fullName;
  final String specialisation;
  final double? latitude;
  final double? longitude;
  final String phone;
  final bool isVerified;

  const _VetProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.specialisation,
    this.latitude,
    this.longitude,
    required this.phone,
    required this.isVerified,
  });

  factory _VetProfile.fromJson(Map<String, dynamic> j) => _VetProfile(
        id: j['user'] as int? ?? 0,
        username: j['username'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        specialisation: j['specialisation'] as String? ?? '',
        latitude: j['latitude'] != null
            ? double.tryParse(j['latitude'].toString())
            : null,
        longitude: j['longitude'] != null
            ? double.tryParse(j['longitude'].toString())
            : null,
        phone: j['phone'] as String? ?? '',
        isVerified: j['is_verified'] as bool? ?? false,
      );

  bool get hasLocation => latitude != null && longitude != null;
}

class VetDirectoryScreen extends StatefulWidget {
  const VetDirectoryScreen({super.key});

  @override
  State<VetDirectoryScreen> createState() => _VetDirectoryScreenState();
}

class _VetDirectoryScreenState extends State<VetDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<_VetProfile> _vets = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadVets();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadVets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.getList(ApiEndpoints.vets);
      final results = data['results'] as List<dynamic>? ?? [];
      setState(() {
        _vets = results
            .map((e) => _VetProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<_VetProfile> get _filtered {
    if (_search.isEmpty) return _vets;
    final q = _search.toLowerCase();
    return _vets.where((v) =>
        v.fullName.toLowerCase().contains(q) ||
        v.username.toLowerCase().contains(q) ||
        v.specialisation.toLowerCase().contains(q),).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinary Directory'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'List'), Tab(text: 'Map')],
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _loadVets)
              : TabBarView(
                  controller: _tabs,
                  children: [_buildList(), _buildMap()],
                ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search vets…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const EmptyWidget(
                  message: 'No verified veterinarians found.',
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _VetTile(vet: _filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final vetsWithLocation = _vets.where((v) => v.hasLocation).toList();
    // Default centre: Zimbabwe
    const defaultCenter = LatLng(-19.0154, 29.1549);

    return FlutterMap(
      options: const MapOptions(
        initialCenter: defaultCenter,
        initialZoom: 6.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.group10.livestock_app',
        ),
        MarkerLayer(
          markers: vetsWithLocation
              .map(
                (v) => Marker(
                  point: LatLng(v.latitude!, v.longitude!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showVetInfo(context, v),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _showVetInfo(BuildContext context, _VetProfile vet) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified, color: Colors.green),
              const SizedBox(width: 8),
              Text(vet.fullName.isNotEmpty ? vet.fullName : vet.username,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,),),
            ],),
            if (vet.specialisation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(vet.specialisation,
                    style: TextStyle(color: Colors.grey[600]),),
              ),
            if (vet.phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Phone: ${vet.phone}'),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Request Assistance'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/assistance/new');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetTile extends StatelessWidget {
  final _VetProfile vet;
  const _VetTile({required this.vet});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Text(
          (vet.fullName.isNotEmpty ? vet.fullName[0] : vet.username[0])
              .toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(vet.fullName.isNotEmpty ? vet.fullName : vet.username),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vet.specialisation.isNotEmpty) Text(vet.specialisation),
          if (vet.isVerified)
            const Row(children: [
              Icon(Icons.verified, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('Verified', style: TextStyle(color: Colors.green),),
            ],),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, '/assistance/new'),
    );
  }
}
