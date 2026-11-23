import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/app_widgets.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);
const _kLightGreen = Color(0xFFE3F0E8);

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

  String get displayName => fullName.isNotEmpty ? fullName : username;

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class VetDirectoryScreen extends StatefulWidget {
  const VetDirectoryScreen({super.key});

  @override
  State<VetDirectoryScreen> createState() => _VetDirectoryScreenState();
}

class _VetDirectoryScreenState extends State<VetDirectoryScreen> {
  List<_VetProfile> _vets = [];
  bool _loading = true;
  String? _error;
  final String _search = '';
  String _selectedArea = 'Zimbabwe';
  bool _useLocation = false;

  @override
  void initState() {
    super.initState();
    _loadVets();
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
    return _vets
        .where((v) =>
            v.fullName.toLowerCase().contains(q) ||
            v.username.toLowerCase().contains(q) ||
            v.specialisation.toLowerCase().contains(q),)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _loading
            ? const LoadingWidget()
            : _error != null
                ? ErrorWidget2(message: _error!, onRetry: _loadVets)
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadVets,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a veterinarian',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verified vets only',
                        style: TextStyle(fontSize: 14, color: _kMuted),
                      ),
                    ],
                  ),
                ),

                // Location card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: _kPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Area (chosen manually)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _kMuted,
                                    ),
                                  ),
                                  Text(
                                    _selectedArea,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showAreaPicker(context);
                              },
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _kBorder),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _kDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your location is not shared automatically.',
                          style: TextStyle(fontSize: 13, color: _kMuted),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _useLocation = !_useLocation),
                          child: Container(
                            height: 36,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _kLightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: _kPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Use my location instead',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Map placeholder
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 150,
                      child: _buildMap(),
                    ),
                  ),
                ),

                // Count heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} vet${filtered.length == 1 ? '' : 's'} near $_selectedArea',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                      const Text(
                        'Nearest first',
                        style: TextStyle(fontSize: 13, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vet list
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No verified veterinarians found.',
                    style: TextStyle(color: _kMuted, fontSize: 15),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: i == 0
                        ? _VetCardFull(
                            vet: filtered[i],
                            onRequest: () => context.go('/assistance/new'),
                          )
                        : _VetCardCompact(vet: filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final vetsWithLocation = _vets.where((v) => v.hasLocation).toList();
    const defaultCenter = LatLng(-19.0154, 29.1549);

    if (vetsWithLocation.isEmpty) {
      return Container(
        color: const Color(0xFFE2E6DF),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 32, color: _kMuted),
              SizedBox(height: 6),
              Text(
                'No location data available',
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

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

  void _showAreaPicker(BuildContext context) {
    final areas = [
      'Zimbabwe',
      'Harare',
      'Bulawayo',
      'Mutare',
      'Gweru',
      'Masvingo',
      'Chinhoyi',
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select area',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
          ),
          ...areas.map(
            (a) => ListTile(
              title: Text(a),
              trailing: a == _selectedArea
                  ? const Icon(Icons.check, color: _kPrimary)
                  : null,
              onTap: () {
                setState(() => _selectedArea = a);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showVetInfo(BuildContext context, _VetProfile vet) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: _kPrimary),
                const SizedBox(width: 8),
                Text(
                  vet.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (vet.specialisation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  vet.specialisation,
                  style: const TextStyle(color: _kMuted),
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/assistance/new');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetCardFull extends StatelessWidget {
  final _VetProfile vet;
  final VoidCallback onRequest;

  const _VetCardFull({required this.vet, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8EEF7),
                child: Text(
                  vet.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173F7A),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vet.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kDark,
                            ),
                          ),
                        ),
                        if (vet.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kLightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (vet.specialisation.isNotEmpty)
                      Text(
                        vet.specialisation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Available today',
            style: TextStyle(
              fontSize: 13,
              color: _kPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (vet.phone.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: vet.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Phone number copied: ${vet.phone}',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: _kDark,
                  ),
                  label: const Text(
                    'Call',
                    style: TextStyle(color: _kDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Request help',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VetCardCompact extends StatelessWidget {
  final _VetProfile vet;

  const _VetCardCompact({required this.vet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8EEF7),
            child: Text(
              vet.initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF173F7A),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vet.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                    ),
                    if (vet.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kLightGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (vet.specialisation.isNotEmpty)
                  Text(
                    vet.specialisation,
                    style: const TextStyle(fontSize: 13, color: _kMuted),
                  ),
                const Text(
                  'Next available: tomorrow',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A4A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
