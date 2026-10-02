import 'package:flutter/material.dart';
import 'package:pos_product/screens/checkout_screen.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: const FoodieAppBar(
        title: 'My Cart',
        showSearchButton: true,
        showCartButton: false,
        
      ),

      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // ==========================================
          // EMPTY CART
          // ==========================================

          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Add some delicious food!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ==========================================
          // CART WITH PRODUCTS
          // ==========================================

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: cart.items.length,

                  itemBuilder: (context, index) {
                    final item = cart.items[index];

                    return _cartItem(context, item, cart);
                  },
                ),
              ),

              // ==========================================
              // BOTTOM CHECKOUT SECTION
              // ==========================================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        const Text(
                          'Total',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          '\$${cart.totalPrice.toStringAsFixed(2)}',

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF5233B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton(
                        onPressed: () {
                          // Make sure cart has items
                          if (cart.items.isEmpty) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5233B),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'CHECKOUT',

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CART ITEM
  // ==========================================

  Widget _cartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          // ==========================================
          // PRODUCT IMAGE
          // ==========================================
          Container(
            width: 80,
            height: 80,

            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Padding(
              padding: const EdgeInsets.all(8),

              child: Image.asset(item.food.imageUrl, fit: BoxFit.contain),
            
            ),
          ),

          const SizedBox(width: 12),

          // ==========================================
          // PRODUCT INFORMATION
          // ==========================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.food.name,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item.selectedSize == 1 ? 'Large (+\$2.00)' : 'Regular',

                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

                if (item.cheese)
                  const Text(
                    'Extra Cheese (+\$1.00)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                if (item.bacon)
                  const Text(
                    'Extra Bacon (+\$1.50)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                const SizedBox(height: 5),

                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',

                  style: const TextStyle(
                    color: Color(0xFFF5233B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // QUANTITY
          // ==========================================
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  IconButton(
                    padding: EdgeInsets.zero,

                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),

                    onPressed: () {
                      cart.decreaseQuantity(item);
                    },

                    icon: const Icon(Icons.remove, size: 18),
                  ),

                  Text(
                    '${item.quantity}',

                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  IconButton(
                    padding: EdgeInsets.zero,

                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),

                    onPressed: () {
                      cart.increaseQuantity(item);
                    },

                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              GestureDetector(
                onTap: () {
                  cart.removeItem(item);
                },

                child: const Text(
                  'Remove',

                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
