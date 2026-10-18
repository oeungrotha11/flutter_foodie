import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/foodie_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password recovery request sent.'),
          backgroundColor: Colors.green,
        ),
      );
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
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please sign in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ApiException
              ? error.message
              : 'Unable to reset your password. Please try again.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: AppBar(
      title: const Text('Forgot password'),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Enter the email address on your account to start password recovery.',
            style: TextStyle(color: Color(0xFF73757D)),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            enabled: !_requestSent,
            keyboardType: TextInputType.emailAddress,
            textInputAction: _requestSent
                ? TextInputAction.next
                : TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            const SizedBox(height: 12),
            const Text(
              'The recovery request was accepted. Set a new password below.',
              style: TextStyle(color: Color(0xFF217A45), fontSize: 13),
            ),
            const SizedBox(height: 20),
            _passwordField(
              controller: _newPassword,
              label: 'New password',
              obscure: _obscureNew,
              toggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a new password';
                if (value.length < 8) return 'Use at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _passwordField(
              controller: _confirmPassword,
              label: 'Confirm new password',
              obscure: _obscureConfirm,
              toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) => value != _newPassword.text
                  ? 'Passwords do not match'
                  : null,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : _requestSent
                  ? _resetPassword
                  : _requestReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5233B),
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_requestSent ? 'RESET PASSWORD' : 'SEND RESET REQUEST'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
