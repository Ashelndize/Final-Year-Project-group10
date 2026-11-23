import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../reports/providers/report_provider.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);
const _kInputBorder = Color(0xFFD5DBD2);
const _kBlueBg = Color(0xFFE8EEF7);
const _kBlueText = Color(0xFF173F7A);

class VetReportFormScreen extends StatefulWidget {
  const VetReportFormScreen({super.key});

  @override
  State<VetReportFormScreen> createState() => _VetReportFormScreenState();
}

class _VetReportFormScreenState extends State<VetReportFormScreen> {
  String _species = 'Cattle';
  DateTime _observedOn = DateTime.now();
  String _district = 'Nyagatare';
  String _sector = 'Karangazi';
  int _affectedCount = 1;
  final Set<String> _selectedSigns = {};
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  static const _speciesOptions = [
    'Cattle', 'Goats', 'Sheep', 'Pigs', 'Poultry', 'Other',
  ];

  static const _signsOptions = [
    'Fever', 'Lameness', 'Drooling', 'Mouth lesions',
    'Reduced milk', 'Abortion', 'Sudden death', 'Other',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _observedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _observedOn = picked);
  }

  Future<void> _submit({bool draft = false}) async {
    if (_selectedSigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sign observed.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'species': _species.toUpperCase(),
        'observation_date':
            '${_observedOn.year}-${_observedOn.month.toString().padLeft(2, '0')}-${_observedOn.day.toString().padLeft(2, '0')}',
        'area_name': '$_sector, $_district',
        'observed_signs': _selectedSigns.join(', '),
        'notes': _notesCtrl.text.trim(),
        'location_consent': false,
        if (draft) 'status': 'DRAFT',
      };
      await context.read<ReportProvider>().submitReport(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              draft ? 'Draft saved.' : 'Report submitted for review.',
            ),
          ),
        );
        context.go('/vet-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: _kDark,),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'New disease report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10,),
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: _kBlueText, size: 18,),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sent to the veterinary authority for review. It is not an official outbreak announcement.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kBlueText,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2-col grid: species + date, district + sector
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Species'),
                              const SizedBox(height: 6),
                              _DropdownField<String>(
                                value: _species,
                                items: _speciesOptions,
                                onChanged: (v) =>
                                    setState(() => _species = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Observed on'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10,),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: _kInputBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _formatDate(_observedOn),
                                          style: const TextStyle(
                                              fontSize: 14, color: _kDark,),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: _kMuted,),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('District'),
                              const SizedBox(height: 6),
                              _DropdownField<String>(
                                value: _district,
                                items: const ['Nyagatare', 'Kigali', 'Musanze'],
                                onChanged: (v) =>
                                    setState(() => _district = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Sector'),
                              const SizedBox(height: 6),
                              _DropdownField<String>(
                                value: _sector,
                                items: const [
                                  'Karangazi',
                                  'Rwimiyaga',
                                  'Matimba',
                                  'Katabagemu',
                                ],
                                onChanged: (v) =>
                                    setState(() => _sector = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Animals showing signs
                    const _Label('Animals showing signs'),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kInputBorder),
                      ),
                      child: Row(
                        children: [
                          _CountButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_affectedCount > 1) {
                                setState(() => _affectedCount--);
                              }
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$_affectedCount',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kDark,
                                ),
                              ),
                            ),
                          ),
                          _CountButton(
                            icon: Icons.add,
                            onTap: () => setState(() => _affectedCount++),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Signs observed
                    const _Label('Signs observed'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _signsOptions.map((sign) {
                        final selected = _selectedSigns.contains(sign);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedSigns.remove(sign);
                              } else {
                                _selectedSigns.add(sign);
                              }
                            });
                          },
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE3F0E8)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? _kPrimary
                                    : _kInputBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sign,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected ? _kPrimary : _kDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Notes
                    const _Label('Notes'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(fontSize: 15, color: _kDark),
                      decoration: InputDecoration(
                        hintText: 'Anything the reviewer should know',
                        hintStyle:
                            const TextStyle(color: _kMuted, fontSize: 15),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10,),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kInputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kInputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kPrimary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Add photo button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF9AA79F),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 18, color: _kDark,),
                            SizedBox(width: 8),
                            Text(
                              'Add photo (optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
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

            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => _submit(draft: true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: const BorderSide(color: _kInputBorder),
                      ),
                      child: const Text(
                        'Save draft',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit report',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kDark,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kInputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 15, color: _kDark),
          icon: const Icon(Icons.keyboard_arrow_down, color: _kMuted),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i,
                    child: Text(i.toString()),
                  ),)
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CountButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _kInputBorder)),
        ),
        child: Icon(icon, size: 20, color: _kDark),
      ),
    );
  }
}
