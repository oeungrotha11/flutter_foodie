import 'package:flutter/material.dart';
import 'package:pos_product/models/order.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:pos_product/screens/favorite_screen.dart';
import 'package:pos_product/screens/login_screen.dart';
import 'package:pos_product/screens/rewards_screen.dart';
import 'package:pos_product/screens/change_password_screen.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';
import '../widgets/foodie_sliver_app_bar.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _name = 'Customer';
  String _email = '';
  int? _lastNavigationIndex;
  Future<List<Order>> _ordersFuture = _loadRemoteOrders();

  static Future<List<Order>> _loadRemoteOrders() async =>
      (await FoodieApi.instance.orders()).whereType<Map>()
          .map((row) => Order.fromJson(Map<String, dynamic>.from(row))).toList();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = context.watch<NavigationProvider>().currentIndex;
    if (index != _lastNavigationIndex) {
      _lastNavigationIndex = index;
      if (index == 4) _ordersFuture = _loadRemoteOrders();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await FoodieApi.instance.currentUser();
      if (!mounted) return;
      setState(() {
        _name = (profile['username'] ?? profile['name'] ?? 'Customer').toString();
        _email = (profile['email'] ?? '').toString();
      });
    } catch (_) {}
  }

  Future<void> _logout() async {
    try { await FoodieApi.instance.logout(); } catch (_) { await ApiClient.instance.clearTokens(); }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteCount = context.watch<FavoriteProvider>().favoriteCount;
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
          FutureBuilder<List<Order>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <Order>[];
              final itemsOrdered = orders
                  .where((order) => order.status != OrderStatus.cancelled)
                  .fold<int>(0, (total, order) => total + order.itemCount);
              return Row(
                children: [
                  Expanded(
                    child: _accountStat(
                      icon: Icons.shopping_bag_outlined,
                      value: '$itemsOrdered',
                      label: 'Items ordered',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _accountStat(
                      icon: Icons.favorite_border,
                      value: '$favoriteCount',
                      label: 'Favorites',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard_outlined, color: Color(0xFFF5233B)),
              title: const Text('Reward wallet'),
              subtitle: const Text('View available rewards and history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.favorite_border,
                color: Color(0xFFF5233B),
              ),
              title: const Text('Favorite items'),
              subtitle: Text('$favoriteCount saved item(s)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoriteScreen()),
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
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset password'),
              subtitle: const Text('Change your account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
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

  Widget _accountStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF5233B), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
