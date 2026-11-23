import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/app_widgets.dart';

const _kBg = Color(0xFFF5F6F1);
const _kPrimary = Color(0xFF1E6B45);
const _kDark = Color(0xFF1B2620);
const _kMuted = Color(0xFF5B675F);
const _kInputBorder = Color(0xFFD5DBD2);
const _kLightGreen = Color(0xFFE3F0E8);
const _kBorder = Color(0xFFE2E6DF);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1: enter phone/email  |  Step 2: enter OTP + new password
  int _step = 1;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  // 6 individual digit controllers + focus nodes
  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocus =
      List.generate(6, (_) => FocusNode());

  bool _obscure = true;
  bool _obscure2 = true;
  String? _devToken;
  String _maskedContact = '';

  // Resend countdown
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    for (final c in _digitCtrl) {
      c.dispose();
    }
    for (final f in _digitFocus) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _codeValue =>
      _digitCtrl.map((c) => c.text).join();

  String _maskContact(String contact) {
    if (contact.contains('@')) {
      final parts = contact.split('@');
      final name = parts[0];
      return '${name.length > 2 ? '${name.substring(0, 2)}***' : '***'}@${parts[1]}';
    }
    final digits = contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      return '${digits.substring(0, 3)} ••• ${digits.substring(digits.length - 3)}';
    }
    return '••• $contact';
  }

  Future<void> _requestReset() async {
    final contact = _emailCtrl.text.trim();
    if (contact.isEmpty) {
      AppSnackBar.show(context, 'Please enter your phone number or email.',
          error: true,);
      return;
    }
    final auth = context.read<AuthProvider>();
    final result = await auth.requestPasswordReset(contact);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _step = 2;
        _maskedContact = _maskContact(contact);
        _devToken = result['devToken'] as String?;
      });
      _startResendTimer();
      if (_devToken != null) {
        AppSnackBar.show(
          context,
          'Dev mode: your reset code is $_devToken',
        );
      }
    } else {
      AppSnackBar.show(context, result['message'] as String, error: true);
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.requestPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (result['success'] == true) {
      _startResendTimer();
      setState(() => _devToken = result['devToken'] as String?);
      AppSnackBar.show(context, 'Code resent.');
      if (_devToken != null) {
        AppSnackBar.show(context, 'Dev mode: code is $_devToken');
      }
    } else {
      AppSnackBar.show(context, result['message'] as String, error: true);
    }
  }

  Future<void> _confirmReset() async {
    final code = _codeValue;
    if (code.length != 6) {
      AppSnackBar.show(context, 'Enter the full 6-digit code.', error: true);
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      AppSnackBar.show(context, 'Password must be at least 8 characters.',
          error: true,);
      return;
    }
    if (_passwordCtrl.text != _password2Ctrl.text) {
      AppSnackBar.show(context, 'Passwords do not match.', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final result = await auth.confirmPasswordReset(
      token: code,
      newPassword: _passwordCtrl.text,
      newPassword2: _password2Ctrl.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      AppSnackBar.show(context, 'Password updated. Please sign in.');
      context.go('/login');
    } else {
      AppSnackBar.show(context, result['message'] as String, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.loading);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _step == 1
            ? _buildStep1(loading)
            : _buildStep2(loading),
      ),
    );
  }

  // ── Step 1: Request reset code ───────────────────────────────────────────

  Widget _buildStep1(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: -10),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, size: 24, color: _kDark),
            ),
          ),

          const SizedBox(height: 24),

          // Icon + heading
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: _kLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: _kPrimary, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'Forgot your password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter the phone number or email on your account. We'll send you a 6-digit code to set a new password.",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF3E4A43),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Phone / email field
          const _Label('Phone number or email'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: loading ? null : (_) => _requestReset(),
            style: const TextStyle(fontSize: 16, color: _kDark),
            decoration: _dec(hint: '0788 123 456'),
          ),

          const SizedBox(height: 20),

          // Send code button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : _requestReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,),
                    )
                  : const Text(
                      'Send code',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,),
                    ),
            ),
          ),

          const SizedBox(height: 32),

          // Info note
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _kPrimary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No phone or email on your account? Ask your system administrator to help you reset it.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3E4A43),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remembered it? ',
                style: TextStyle(fontSize: 15, color: Color(0xFF3E4A43)),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Enter code + set new password ────────────────────────────────

  Widget _buildStep2(bool loading) {
    final pw = _passwordCtrl.text;
    final rulesOk = [
      pw.length >= 8,
      pw.isNotEmpty && !['password', '12345678', 'qwerty'].contains(pw.toLowerCase()),
      pw == _password2Ctrl.text && pw.isNotEmpty,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: () => setState(() {
              _step = 1;
              for (final c in _digitCtrl) {
                c.clear();
              }
            }),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: -10),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, size: 24, color: _kDark),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Set a new password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF3E4A43), height: 1.5,),
              children: [
                const TextSpan(text: 'If an account matches '),
                TextSpan(
                  text: _maskedContact,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      color: _kDark,),
                ),
                const TextSpan(
                    text:
                        ', we sent it a 6-digit code. The code expires in 15 minutes.',),
              ],
            ),
          ),

          // Dev token banner
          if (_devToken != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8C27A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF7A4A00), size: 16,),
                  const SizedBox(width: 8),
                  Text(
                    'Dev mode — code: $_devToken',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A4A00),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // 6-digit code boxes
          const _Label2('6-digit code'),
          const SizedBox(height: 10),
          Row(
            children: List.generate(6, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  child: _DigitBox(
                    controller: _digitCtrl[i],
                    focusNode: _digitFocus[i],
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _digitFocus[i + 1].requestFocus();
                      }
                      setState(() {});
                    },
                    onBackspace: () {
                      if (_digitCtrl[i].text.isEmpty && i > 0) {
                        _digitCtrl[i - 1].clear();
                        _digitFocus[i - 1].requestFocus();
                        setState(() {});
                      }
                    },
                    isFilled: _digitCtrl[i].text.isNotEmpty,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _resendSeconds == 0 ? _resendCode : null,
            child: Text(
              _resendSeconds > 0
                  ? 'Didn\'t get it? Resend code in 0:${_resendSeconds.toString().padLeft(2, '0')}'
                  : 'Resend code',
              style: TextStyle(
                fontSize: 13,
                color: _resendSeconds == 0 ? _kPrimary : _kMuted,
                fontWeight: _resendSeconds == 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // New password
          const _Label2('New password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16, color: _kDark),
            decoration: _dec(hint: '••••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _kMuted,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Confirm password
          const _Label2('Confirm new password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _password2Ctrl,
            obscureText: _obscure2,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: loading ? null : (_) => _confirmReset(),
            style: const TextStyle(fontSize: 16, color: _kDark),
            decoration: _dec(hint: '••••••••••').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _kMuted,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Password rules
          Column(
            children: [
              _RuleRow(label: 'At least 8 characters', met: rulesOk[0]),
              const SizedBox(height: 6),
              _RuleRow(label: 'Not a common password', met: rulesOk[1]),
              const SizedBox(height: 6),
              _RuleRow(label: 'Both passwords match', met: rulesOk[2]),
            ],
          ),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : _confirmReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,),
                    )
                  : const Text(
                      'Set new password',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

InputDecoration _dec({String hint = ''}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kMuted, fontSize: 16),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      borderSide: const BorderSide(color: _kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFB42318)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: Color(0xFFB42318), width: 1.5),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kDark,
        ),
      );
}

// Step-2 uses a non-const label identical to _Label but needed separately
class _Label2 extends StatelessWidget {
  final String text;
  const _Label2(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kDark,
        ),
      );
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool met;
  const _RuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check : Icons.check,
          size: 16,
          color: met ? _kPrimary : _kMuted,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: met ? _kPrimary : _kMuted,
          ),
        ),
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool isFilled;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          onBackspace();
        }
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _kDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          constraints: const BoxConstraints(minHeight: 52),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFilled ? _kPrimary : _kInputBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFilled ? _kPrimary : _kInputBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _kPrimary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
