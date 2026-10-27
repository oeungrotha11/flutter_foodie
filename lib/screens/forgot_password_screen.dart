import 'package:flutter/material.dart';
import 'package:pos_product/widgets/foodie_sliver_app_bar.dart';

import '../services/api_client.dart';
import '../services/foodie_api.dart';
import '../widgets/app_text_form_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _requestSent = false;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FoodieApi.instance.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _requestSent = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('If an account exists for this email, a reset code has been sent.'),
          backgroundColor: Colors.green,
        ));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FoodieApi.instance.resetPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Password reset successfully. Please sign in again.'),
          backgroundColor: Colors.green,
        ));
      Navigator.pop(context);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          error is ApiException
              ? error.message
              : 'Unable to reset your password. Please try again.',
        ),
        backgroundColor: Colors.red,
      ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: const FoodieAppBar(
      title: ('Forgot password'),
      showBackButton: true,
      showSearchButton: false,
      showCartButton: false,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Enter your account email. We will send a verification code before allowing you to reset your password.',
            style: TextStyle(color: Color(0xFF73757D)),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: _email,
            labelText: 'Email',
            prefixIcon: Icons.email_outlined,
            enabled: !_requestSent,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          if (_requestSent) ...[
            const SizedBox(height: 18),
            const Text(
              'Enter the 6-digit code sent to your email, then choose a new password. The code expires in 10 minutes.',
              style: TextStyle(color: Color(0xFF73757D), fontSize: 13),
            ),
            const SizedBox(height: 16),
            AppTextFormField(
              controller: _code,
              labelText: 'Verification code',
              prefixIcon: Icons.password_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
              counterText: '',
              validator: (value) => value != null && RegExp(r'^[0-9]{6}$').hasMatch(value.trim())
                  ? null
                  : 'Enter the 6-digit code from your email',
            ),
            const SizedBox(height: 16),
            AppTextFormField(
              controller: _newPassword,
              labelText: 'New password',
              obscureText: _obscureNew,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(onPressed: () => setState(() => _obscureNew = !_obscureNew), icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility)),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a new password';
                if (value.length < 8) return 'Use at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextFormField(
              controller: _confirmPassword,
              labelText: 'Confirm new password',
              obscureText: _obscureConfirm,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility)),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirm your new password';
                if (value != _newPassword.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : (_requestSent ? _resetPassword : _requestReset),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5233B),
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_requestSent ? 'VERIFY CODE & RESET PASSWORD' : 'SEND VERIFICATION CODE'),
            ),
          ),
          if (_requestSent)
            TextButton(
              onPressed: _loading ? null : () {
                setState(() {
                  _requestSent = false;
                  _code.clear();
                  _newPassword.clear();
                  _confirmPassword.clear();
                });
              },
              child: const Text('Use a different email'),
            ),
        ],
      ),
    ),
  );
}
