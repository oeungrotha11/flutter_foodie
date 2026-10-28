import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import '../widgets/foodie_sliver_app_bar.dart';
import 'map_location_picker_screen.dart';

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
  double? _latitude;
  double? _longitude;

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
      _latitude = (data['latitude'] as num?)?.toDouble() ?? prefs.getDouble('delivery.latitude');
      _longitude = (data['longitude'] as num?)?.toDouble() ?? prefs.getDouble('delivery.longitude');
    } catch (_) {
      _addressController.text = prefs.getString('delivery.address') ?? '';
      _cityController.text = prefs.getString('delivery.city') ?? '';
      _phoneController.text = prefs.getString('delivery.phone') ?? '';
      _latitude = prefs.getDouble('delivery.latitude');
      _longitude = prefs.getDouble('delivery.longitude');
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

  Future<void> _chooseOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => MapLocationPickerScreen(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      )),
    );
    if (result == null || !mounted) return;
    setState(() {
      _addressController.text = (result['address'] ?? '').toString();
      _cityController.text = (result['city'] ?? 'Phnom Penh').toString();
      _latitude = (result['latitude'] as num).toDouble();
      _longitude = (result['longitude'] as num).toDouble();
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FoodieApi.instance.saveDeliveryAddress(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery.address', _addressController.text.trim());
      await prefs.setString('delivery.city', _cityController.text.trim());
      await prefs.setString('delivery.phone', _phoneController.text.trim());
      if (_latitude != null && _longitude != null) {
        await prefs.setDouble('delivery.latitude', _latitude!);
        await prefs.setDouble('delivery.longitude', _longitude!);
      }
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
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _chooseOnMap,
                icon: const Icon(Icons.map_outlined, color: Color(0xFFF5233B), size: 18),
                label: Text(_latitude != null && _longitude != null ? 'CHANGE MAP LOCATION' : 'CHOOSE ON MAP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF5233B), side: const BorderSide(color: Color(0xFFF5233B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
              ),
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 7),
              Text('Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
            const SizedBox(height: 14),
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
