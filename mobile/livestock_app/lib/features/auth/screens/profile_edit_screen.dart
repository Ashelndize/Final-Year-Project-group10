import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kInputBorder = Color(0xFFD5DBD2);
const _kBorder = Color(0xFFE2E6DF);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // User fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Farmer-specific
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Vet-specific
  final _licenseCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  final _clinicAddressCtrl = TextEditingController();

  bool _saving = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameCtrl.text = user.firstName;
      _lastNameCtrl.text = user.lastName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone;
    }

    try {
      if (user?.isVet == true) {
        final data = await ApiClient.get(ApiEndpoints.vetProfile);
        _licenseCtrl.text = data['license_number'] as String? ?? '';
        _specializationCtrl.text = data['specialization'] as String? ?? '';
        _clinicNameCtrl.text = data['clinic_name'] as String? ?? '';
        _clinicAddressCtrl.text = data['clinic_address'] as String? ?? '';
      } else {
        final data = await ApiClient.get(ApiEndpoints.farmerProfile);
        _locationCtrl.text = data['location'] as String? ?? '';
        _bioCtrl.text = data['bio'] as String? ?? '';
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    try {
      // 1. Update core user fields
      await ApiClient.patch(ApiEndpoints.me, {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });

      // 2. Update profile-specific fields
      if (user?.isVet == true) {
        await ApiClient.patch(ApiEndpoints.vetProfile, {
          'license_number': _licenseCtrl.text.trim(),
          'specialization': _specializationCtrl.text.trim(),
          'clinic_name': _clinicNameCtrl.text.trim(),
          'clinic_address': _clinicAddressCtrl.text.trim(),
        });
      } else {
        await ApiClient.patch(ApiEndpoints.farmerProfile, {
          'location': _locationCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
        });
      }

      // 3. Refresh user in memory
      await authProvider.refreshUser();

      if (!mounted) return;
      AppSnackBar.show(context, 'Profile updated successfully.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Network error. Please try again.', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _licenseCtrl.dispose();
    _specializationCtrl.dispose();
    _clinicNameCtrl.dispose();
    _clinicAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVet = context.read<AuthProvider>().user?.isVet == true;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving || _loadingProfile ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kBorder),
        ),
      ),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  const _SectionHeader('Personal information'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'First name',
                          controller: _firstNameCtrl,
                          hint: 'First name',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Last name',
                          controller: _lastNameCtrl,
                          hint: 'Last name',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Phone number',
                    controller: _phoneCtrl,
                    hint: '0788 123 456',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 9) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Email address',
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 28),

                  if (isVet) ...[
                    const _SectionHeader('Veterinary information'),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'License number',
                      controller: _licenseCtrl,
                      hint: 'e.g. VET-2024-001',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Specialization',
                      controller: _specializationCtrl,
                      hint: 'e.g. Large animals, cattle',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Clinic name',
                      controller: _clinicNameCtrl,
                      hint: 'e.g. Green Valley Vet Clinic',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Clinic address',
                      controller: _clinicAddressCtrl,
                      hint: 'Street, district',
                      maxLines: 2,
                    ),
                  ] else ...[
                    const _SectionHeader('Farm information'),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Location',
                      controller: _locationCtrl,
                      hint: 'e.g. Musanze District',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'About (optional)',
                      controller: _bioCtrl,
                      hint: 'A short description of your farm',
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: _kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted, fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFB42318)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFB42318), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kDark,
      ),
    );
  }
}
