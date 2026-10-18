import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await FoodieApi.instance.deliveryAddress();
      _addressController.text = (data['address'] ?? prefs.getString('delivery.address') ?? '').toString();
      _cityController.text = (data['city'] ?? prefs.getString('delivery.city') ?? '').toString();
      _phoneController.text = (data['phone'] ?? prefs.getString('delivery.phone') ?? '').toString();
    } catch (_) {
      _addressController.text = prefs.getString('delivery.address') ?? '';
      _cityController.text = prefs.getString('delivery.city') ?? '';
      _phoneController.text = prefs.getString('delivery.phone') ?? '';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FoodieApi.instance.saveDeliveryAddress(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery.address', _addressController.text.trim());
      await prefs.setString('delivery.city', _cityController.text.trim());
      await prefs.setString('delivery.phone', _phoneController.text.trim());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is ApiException ? error.message : 'Unable to save delivery address.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery address saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(
        title: 'Delivery Address',
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          children: [
            _field(_addressController, 'Street address', Icons.home_outlined),
            const SizedBox(height: 14),
            _field(_cityController, 'City', Icons.location_city_outlined),
            const SizedBox(height: 14),
            _field(
              _phoneController,
              'Phone number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5233B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'SAVE ADDRESS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
      style: const TextStyle(fontSize: 12),
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter ${label.toLowerCase()}',
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFFF5233B)),
        labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 35,
          minHeight: 35,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
}
