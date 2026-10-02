import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:provider/provider.dart';

class FoodieAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showSearchButton;
  final bool showCartButton;
  final bool showCartBadge;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onCartPressed;

  const FoodieAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showSearchButton = true,
    this.showCartButton = true,
    this.showCartBadge = true,
    this.onSearchPressed,
    this.onCartPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: showBackButton
          ? IconButton(
              constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
              splashRadius: 18,
              iconSize: 20,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
            )
          : showSearchButton
          ? _SearchButton(onPressed: onSearchPressed)
          : null,
      title: _FoodieTitle(title: title),
      centerTitle: true,
      actions: [
        if (showCartButton)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            // Match the right-side inset with leading left-side inset
            child: _CartButton(
              onPressed: onCartPressed,
              showBadge: showCartBadge,
            ),
          ),
      ],
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SearchButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      splashRadius: 18,
      iconSize: 22,
      onPressed:
          onPressed ??
          () {
            context.read<NavigationProvider>().setCurrentIndex(1);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
      icon: const Icon(Icons.search, color: Colors.black87),
    );
  }
}

class _FoodieTitle extends StatelessWidget {
  final String title;

  const _FoodieTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.normal,
        color: Color.fromARGB(255, 239, 43, 1),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool showBadge;

  const _CartButton({this.onPressed, this.showBadge = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
              splashRadius: 18,
              iconSize: 20,
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black87,
              ),
              onPressed:
                  onPressed ??
                  () {
                    context.read<NavigationProvider>().setCurrentIndex(2);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            ),
            if (showBadge && cart.itemCount > 0)
              Positioned(
                right: 1,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5233B),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cart.itemCount}',
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
    );
  }
}
