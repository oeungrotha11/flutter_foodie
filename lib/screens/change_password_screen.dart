import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/foodie_api.dart';
import 'forgot_password_screen.dart';
import '../widgets/app_text_form_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ChangePasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FoodieApi.instance.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Unable to update your password. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: AppBar(
      title: const Text('Reset password'),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        children: [
          const Text(
            'Choose a new password for your account.',
            style: TextStyle(color: Color(0xFF73757D)),
          ),
          const SizedBox(height: 22),
          AppTextFormField(
            controller: _currentPassword,
            labelText: 'Current password',
            obscureText: _obscureCurrent,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent), icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility)),
            toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (value) => value == null || value.isEmpty
                ? 'Enter your current password'
                : null,
          ),
          const SizedBox(height: 14),
          AppTextFormField(
            controller: _newPassword,
            labelText: 'New password',
            obscureText: _obscureNew,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscureNew = !_obscureNew), icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility)),
            toggle: () => setState(() => _obscureNew = !_obscureNew),
            validator: (value) => _validateNewPassword(value),
          ),
          const SizedBox(height: 14),
          AppTextFormField(
            controller: _confirmPassword,
            labelText: 'Confirm new password',
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility)),
            toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (value) => value != _newPassword.text
                ? 'Passwords do not match'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: widget.initialEmail,
                          ),
                        ),
                      ),
              child: const Text(
                'Forgot your password?',
                style: TextStyle(color: Color(0xFFF5233B)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5233B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF5233B),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'UPDATE PASSWORD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (value == _currentPassword.text) {
      return 'Choose a password different from your current one';
    }
    return null;
  }
}
