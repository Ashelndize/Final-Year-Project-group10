import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1: enter email  |  Step 2: enter OTP + new password
  int _step = 1;

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  bool _obscure = true;
  String? _devToken; // shown only when server returns dev_token

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.requestPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _step = 2;
        _devToken = result['devToken'] as String?;
      });
      if (_devToken != null) {
        AppSnackBar.show(
          context,
          'Dev mode: your reset code is $_devToken (15 min)',
        );
      } else {
        AppSnackBar.show(context, result['message'] as String);
      }
    } else {
      AppSnackBar.show(context, result['message'] as String, error: true);
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.confirmPasswordReset(
      token: _tokenCtrl.text.trim(),
      newPassword: _passwordCtrl.text,
      newPassword2: _password2Ctrl.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      AppSnackBar.show(context, 'Password reset! Please sign in.');
      context.go('/login');
    } else {
      AppSnackBar.show(context, result['message'] as String, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.loading);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: BackButton(onPressed: () {
          if (_step == 2) {
            setState(() => _step = 1);
          } else {
            context.go('/login');
          }
        },),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == 1 ? _buildStep1(loading) : _buildStep2(loading),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(bool loading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Forgot your password?',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address. We will send you a 6-digit reset code.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _requestReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,),
                  )
                : const Text('Send Reset Code', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool loading) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_outlined, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Enter Reset Code',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${_emailCtrl.text} and choose a new password.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          if (_devToken != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.amber, size: 18,),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dev mode — code: $_devToken',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold,),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _tokenCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.length != 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password2Ctrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _confirmReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,),
                  )
                : const Text('Reset Password', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }
}
