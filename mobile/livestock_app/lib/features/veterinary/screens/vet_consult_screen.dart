import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/assistance_provider.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kBorder = Color(0xFFE2E6DF);
const _kLightGreen = Color(0xFFE3F0E8);
const _kInputBorder = Color(0xFFD5DBD2);

class VetConsultScreen extends StatefulWidget {
  final int requestId;
  const VetConsultScreen({super.key, required this.requestId});

  @override
  State<VetConsultScreen> createState() => _VetConsultScreenState();
}

class _VetConsultScreenState extends State<VetConsultScreen> {
  final _findingsCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  DateTime _visitDate = DateTime.now();
  DateTime? _followUpDate;
  bool _suspectDisease = false;
  bool _saving = false;

  @override
  void dispose() {
    _findingsCtrl.dispose();
    _treatmentCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_monthName(dt.month)} ${dt.year}';

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Future<void> _save() async {
    if (_findingsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your findings.')),
      );
      return;
    }
    setState(() => _saving = true);
    // Simulate save — in a real app, call an API endpoint
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _saving = false);
    if (_suspectDisease) {
      context.go('/vet/reports/new?requestId=${widget.requestId}');
    } else {
      context.go('/vet-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AssistanceProvider>();
    final request = provider.requests
        .where((r) => r.id == widget.requestId)
        .firstOrNull;

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
                    'Record consultation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12,),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: _kLightGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'CT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request?.animalName ?? 'Animal',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${request?.farmName ?? ''} · ${request?.farmerUsername ?? ''}',
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
                    ),

                    const SizedBox(height: 14),

                    // Visit date
                    const _FieldLabel('Visit date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickVisitDate,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kInputBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(_visitDate),
                              style: const TextStyle(
                                  fontSize: 15, color: _kDark,),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: _kMuted,),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Findings
                    const _FieldLabel('Findings'),
                    const SizedBox(height: 6),
                    _TextArea(
                      controller: _findingsCtrl,
                      hint: 'Describe your clinical findings…',
                      minLines: 3,
                    ),

                    const SizedBox(height: 14),

                    // Treatment given
                    const _FieldLabel('Treatment given'),
                    const SizedBox(height: 6),
                    _TextArea(
                      controller: _treatmentCtrl,
                      hint: 'Describe the treatment you gave',
                      minLines: 3,
                    ),

                    const SizedBox(height: 14),

                    // Follow-up date
                    const _FieldLabel('Follow-up date (optional)'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickFollowUpDate,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kInputBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _followUpDate != null
                                  ? _formatDate(_followUpDate!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 15,
                                color: _followUpDate != null
                                    ? _kDark
                                    : _kMuted,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: _kMuted,),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Disease suspect checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12,),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _suspectDisease,
                              onChanged: (v) =>
                                  setState(() => _suspectDisease = v ?? false),
                              activeColor: _kPrimary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I suspect a reportable disease. Start a disease report after saving.',
                              style: TextStyle(
                                fontSize: 14,
                                color: _kDark,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'This record will show as "Recorded by vet" in the farmer\'s history.',
                      style: TextStyle(fontSize: 13, color: _kMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _kBorder)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save consultation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

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

class _TextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;

  const _TextArea({
    required this.controller,
    required this.hint,
    this.minLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: minLines,
      style: const TextStyle(fontSize: 15, color: _kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      ),
    );
  }
}
