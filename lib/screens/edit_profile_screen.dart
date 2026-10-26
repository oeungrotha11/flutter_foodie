import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/foodie_api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.address,
    required this.city,
    required this.phone,
  });

  final String username;
  final String email;
  final String address;
  final String city;
  final String phone;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
    _cityController = TextEditingController(text: widget.city);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = await FoodieApi.instance.updateCurrentUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, <String, String>{
        'username':
            (updated['username'] ??
                    updated['name'] ??
                    _usernameController.text.trim())
                .toString(),
        'email': (updated['email'] ?? _emailController.text.trim()).toString(),
        'address': (updated['address'] ?? _addressController.text.trim())
            .toString(),
        'city': (updated['city'] ?? _cityController.text.trim()).toString(),
        'phone': (updated['phone'] ?? _phoneController.text.trim()).toString(),
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not update your profile.',
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
      title: const Text('Edit profile'),
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
          _field(
            controller: _usernameController,
            label: 'Name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _field(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _field(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your address'
                : null,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your city'
                : null,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _phoneController,
            label: 'Phone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your phone number'
                : null,
          ),
          const SizedBox(height: 20),
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
                      'SAVE PROFILE',
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    autofillHints: autofillHints,
    textCapitalization: textCapitalization,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteractionIfError,
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      hintText: 'Enter ${label.toLowerCase()}',
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFFF5233B)),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      prefixIconConstraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      errorStyle: const TextStyle(fontSize: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFF5233B), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red, width: 0.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    ),
  );
}
