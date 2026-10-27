import 'package:flutter/material.dart';
import 'package:pos_product/models/order.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:pos_product/screens/favorite_screen.dart';
import 'package:pos_product/screens/login_screen.dart';
import 'package:pos_product/screens/rewards_screen.dart';
import 'package:pos_product/screens/change_password_screen.dart';
import 'package:pos_product/screens/edit_profile_screen.dart';
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

  String _address = '';
  String _city = '';
  String _phone = '';
  int? _lastNavigationIndex;
  Future<List<Order>> _ordersFuture = _loadRemoteOrders();

  static Future<List<Order>> _loadRemoteOrders() async =>
      (await FoodieApi.instance.orders())
          .whereType<Map>()
          .map((row) => Order.fromJson(Map<String, dynamic>.from(row)))
          .toList();

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
      Map<String, dynamic> deliveryAddress = {};
      try {
        deliveryAddress = await FoodieApi.instance.deliveryAddress();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _name = (profile['username'] ?? profile['name'] ?? 'Customer')
            .toString();
        _email = (profile['email'] ?? '').toString();
        _address = (profile['address'] ?? deliveryAddress['address'] ?? '')
            .toString();
        _city = (profile['city'] ?? deliveryAddress['city'] ?? '').toString();
        _phone = (profile['phone'] ?? deliveryAddress['phone'] ?? '')
            .toString();
      });
    } catch (_) {}
  }

  Future<void> _editProfile() async {
    final changes = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          username: _name,
          address: _address,
          city: _city,
          phone: _phone,
          email: _email,
        ),
      ),
    );
    if (changes == null || !mounted) return;

    setState(() {
      _name = changes['username']!;
      _email = changes['email']!;
      _address = changes['address']!;
      _city = changes['city']!;
      _phone = changes['phone']!;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFF5233B)),
              SizedBox(width: 10),
              Text('Log out?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5233B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Log out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      await FoodieApi.instance.logout();
    } catch (_) {
      await ApiClient.instance.clearTokens();
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteCount = context.watch<FavoriteProvider>().favoriteCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Account'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDEDF0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFFEEF0),
                  child: Text(
                    _name.isEmpty ? 'C' : _name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFF5233B),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF24252B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _email.isEmpty ? 'Manage your account' : _email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF777982),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _editProfile,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF5233B),
                    backgroundColor: const Color(0xFFFFEEF0),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF24252B),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 26),
          const Text(
            'Account settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF24252B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDEDF0)),
            ),
            child: Column(
              children: [
                _accountOption(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Reward wallet',
                  subtitle: 'View rewards and history',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  ),
                ),
                _accountOption(
                  icon: Icons.favorite_border,
                  title: 'Favorite items',
                  subtitle: '$favoriteCount saved item(s)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  ),
                ),
                _accountOption(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery address',
                  subtitle: 'Add or update your address',
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
                _accountOption(
                  icon: Icons.lock_reset,
                  title: 'Reset password',
                  subtitle: 'Change your account password',
                  showDivider: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(initialEmail: _email),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF4D9DC)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFF5233B),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Log out',
                  style: TextStyle(
                    color: Color(0xFFF5233B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9A9BA2),
                ),
                onTap: _confirmLogout,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 3,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFF5233B), size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF292A30),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF777982), fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9A9BA2)),
            onTap: onTap,
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 14,
            color: Color(0xFFF0F0F2),
          ),
      ],
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
