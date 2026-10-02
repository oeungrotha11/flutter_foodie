import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/screens/orders_screen.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'shop_screen.dart';

class MenuItem {
  final String label;
  final String icon;

  const MenuItem({required this.label, required this.icon});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<MenuItem> _menus = const [
    MenuItem(label: 'Shop', icon: 'assets/svg/Shop.svg'),
    MenuItem(label: 'Search', icon: 'assets/svg/Search.svg'),
    MenuItem(label: 'Cart', icon: 'assets/svg/Cart.svg'),
    MenuItem(label: 'Order', icon: 'assets/svg/receipt.svg'),
    MenuItem(label: 'Account', icon: 'assets/svg/Account.svg'),
  ];

  late final List<Widget> _pages = [
    const ShopScreen(),
    const SearchScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (int index = 0; index < _menus.length; index++)
                    Expanded(child: _menuButton(context, index, currentIndex)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, int index, int currentIndex) {
    final menu = _menus[index];
    final selected = currentIndex == index;
    final color = selected ? const Color(0xFFF5233B) : Colors.grey.shade500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<NavigationProvider>().setCurrentIndex(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFF5233B).withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        menu.icon,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                      if (index == 2 && cart.totalItems > 0)
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5233B),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cart.totalItems}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 3),
            Text(
              menu.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
