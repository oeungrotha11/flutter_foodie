import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import '../widgets/foodie_sliver_app_bar.dart';
import '../widgets/app_text_form_field.dart';

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
    Navigator.pop(context);
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
            AppTextFormField(controller: _addressController, labelText: 'Street address', prefixIcon: Icons.home_outlined, validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            AppTextFormField(controller: _cityController, labelText: 'City', prefixIcon: Icons.location_city_outlined, validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            AppTextFormField(
              controller: _phoneController,
              labelText: 'Phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
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
}
