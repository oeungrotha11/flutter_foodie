import 'package:flutter/material.dart';
import 'package:pos_product/screens/checkout_screen.dart';
import 'package:pos_product/screens/product_detail.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/food_image.dart';
import '../models/cart_item.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      appBar: const FoodieAppBar(
        title: 'F o o d i e',
        showSearchButton: true,
        showCartButton: false,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: Color(0xFFD93B32),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF242A25),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Add some delicious food!',
                    style: TextStyle(color: Color(0xFF727A73), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  itemCount: cart.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Your cart',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF242A25),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${cart.itemCount} items',
                              style: const TextStyle(
                                color: Color(0xFF727A73),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final item = cart.items[index - 1];
                    return _cartItem(context, item, cart);
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE4E7E3))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Color(0xFF727A73),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${cart.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF242A25),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD93B32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'CHECKOUT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EBE6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: ColoredBox(
                    color: const Color(0xFFF4F6F3),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: foodImage(item.food.imageUrl),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF252B26),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.selectedOptions.isEmpty
                          ? 'Standard'
                          : item.selectedOptions
                                .map(
                                  (option) => option.type == 'SIZE'
                                      ? '${option.name} (\$${(option.price ?? item.food.price).toStringAsFixed(2)})'
                                      : option.extraPrice == 0
                                      ? option.name
                                      : '${option.name} (+\$${option.extraPrice.toStringAsFixed(2)})',
                                )
                                .join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A827B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFFD93B32),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit product options',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      food: item.food,
                      editingItem: item,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFD93B32)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(color: Color(0xFF727A73), fontSize: 12),
                ),
              ),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F4),
                  border: Border.all(color: const Color(0xFFE4E7E3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: item.quantity == 1
                          ? 'Remove item'
                          : 'Decrease quantity',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      onPressed: () {
                        if (item.quantity == 1) {
                          _confirmRemoveItem(context, item, cart);
                        } else {
                          cart.decreaseQuantity(item);
                        }
                      },
                      icon: Icon(
                        item.quantity == 1
                            ? Icons.delete_outline
                            : Icons.remove,
                        color: item.quantity == 1
                            ? const Color(0xFFD93B32)
                            : const Color(0xFF4D554F),
                        size: 18,
                      ),
                    ),
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF252B26),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      onPressed: () => cart.increaseQuantity(item),
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF4D554F),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveItem(
    BuildContext context,
    CartItem item,
    CartProvider cart,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Remove item?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF242A25),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Remove ${item.food.name} from your cart?',
          style: const TextStyle(color: Color(0xFF727A73), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Keep item',
              style: TextStyle(color: Color(0xFF4D554F)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD93B32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && cart.items.contains(item)) {
      cart.removeItem(item);
    }
  }
}
