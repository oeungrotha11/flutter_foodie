import 'package:flutter/material.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:pos_product/screens/login_screen.dart';
import 'package:pos_product/screens/orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _name = 'Customer';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('sv11-12.pos_mobile.name') ?? 'Customer';
      _email = prefs.getString('sv11-12.pos_mobile.email') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sv11-12.pos_mobile.token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Account'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFFFEEF0),
            child: Text(
              _name.isEmpty ? 'C' : _name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFF5233B),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_email.isNotEmpty)
            Text(
              _email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              subtitle: const Text('View your order history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Delivery Address'),
              subtitle: const Text('Add or update your delivery address'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryAddressScreen(),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFF5233B)),
              title: const Text('Log out'),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
