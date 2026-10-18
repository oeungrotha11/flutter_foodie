import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/foodie_api.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose a new password for your account.',
            style: TextStyle(color: Color(0xFF73757D)),
          ),
          const SizedBox(height: 22),
          _passwordField(
            controller: _currentPassword,
            label: 'Current password',
            obscure: _obscureCurrent,
            toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (value) => value == null || value.isEmpty
                ? 'Enter your current password'
                : null,
          ),
          const SizedBox(height: 14),
          _passwordField(
            controller: _newPassword,
            label: 'New password',
            obscure: _obscureNew,
            toggle: () => setState(() => _obscureNew = !_obscureNew),
            validator: (value) => _validateNewPassword(value),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
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
                  : const Text('UPDATE PASSWORD'),
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
