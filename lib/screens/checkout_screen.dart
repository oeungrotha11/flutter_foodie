import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/screens/order_success_screen.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/order_storage.dart';
import '../models/order.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String orderType = 'Takeaway';
  String paymentMethod = 'Cash';
  String _deliveryAddress = '';

  Future<void> _openDeliveryAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryAddressScreen()),
    );
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _deliveryAddress = [
        prefs.getString('delivery.address'),
        prefs.getString('delivery.city'),
      ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    final double subtotal = cart.totalPrice;
    final double deliveryFee = orderType == 'Delivery' ? 2.00 : 0.00;
    final double total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: const FoodieAppBar(
        title: 'Checkout',
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==========================================
            // ORDER TYPE
            // ==========================================
            const Text(
              'Order Type',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _orderTypeButton(
                    icon: Icons.restaurant,
                    title: 'Dine In',
                    value: 'Dine In',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _orderTypeButton(
                    icon: Icons.shopping_bag,
                    title: 'Takeaway',
                    value: 'Takeaway',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _orderTypeButton(
                    icon: Icons.delivery_dining,
                    title: 'Delivery',
                    value: 'Delivery',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            if (orderType == 'Delivery') ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    _deliveryAddress.isEmpty
                        ? 'Add delivery address'
                        : _deliveryAddress,
                  ),
                  subtitle: Text(
                    _deliveryAddress.isEmpty
                        ? 'Required for delivery'
                        : 'Tap to change address',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openDeliveryAddress,
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ==========================================
            // PAYMENT METHOD
            // ==========================================
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _paymentOption(icon: Icons.money, title: 'Cash', value: 'Cash'),

            const SizedBox(height: 10),

            _paymentOption(
              icon: Icons.qr_code,
              title: 'QR Payment',
              value: 'QR Payment',
            ),

            const SizedBox(height: 10),

            _paymentOption(
              icon: Icons.credit_card,
              title: 'Credit / Debit Card',
              value: 'Card',
            ),

            const SizedBox(height: 28),

            // ==========================================
            // ORDER SUMMARY
            // ==========================================
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  // Products
                  ...cart.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),

                      child: Row(
                        children: [
                          // Image
                          Container(
                            width: 55,
                            height: 55,

                            padding: const EdgeInsets.all(5),

                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Image.asset(
                              item.food.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Name + quantity
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  item.food.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,

                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Qty: ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',

                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(),

                  const SizedBox(height: 8),

                  // Subtotal
                  _priceRow('Subtotal', subtotal),

                  const SizedBox(height: 8),

                  // Delivery
                  _priceRow('Delivery Fee', deliveryFee),

                  const SizedBox(height: 12),

                  const Divider(),

                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '\$${total.toStringAsFixed(2)}',

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5233B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // PLACE ORDER
      // ==========================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,

            width: double.infinity,

            child: ElevatedButton(
              onPressed: () async {
                if (orderType == 'Delivery' && _deliveryAddress.isEmpty) {
                  await _openDeliveryAddress();
                  return;
                }

                // Save total before clearing cart
                final orderTotal = total;
                final order = Order(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  total: orderTotal,
                  orderType: orderType,
                  paymentMethod: paymentMethod,
                  address: _deliveryAddress,
                  itemCount: cart.totalItems,
                  createdAt: DateTime.now(),
                );
                await OrderStorage.addOrder(order);
                if (!context.mounted) return;

                // Clear cart
                cart.clearCart();

                // Go to success screen
                Navigator.pushAndRemoveUntil(
                  context,

                  MaterialPageRoute(
                    builder: (_) => OrderSuccessScreen(total: orderTotal),
                  ),

                  (route) => false,
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
                'PLACE ORDER',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ORDER TYPE BUTTON
  // ==========================================

  Widget _orderTypeButton({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final bool selected = orderType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          orderType = value;
        });
      },

      child: Container(
        height: 90,

        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEEF0) : Colors.white,

          borderRadius: BorderRadius.circular(15),

          border: Border.all(
            color: selected ? const Color(0xFFF5233B) : Colors.grey.shade300,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 25,
              color: selected ? const Color(0xFFF5233B) : Colors.grey,
            ),

            const SizedBox(height: 7),

            Text(
              title,
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,

                color: selected ? const Color(0xFFF5233B) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PAYMENT OPTION
  // ==========================================

  Widget _paymentOption({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final bool selected = paymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: selected ? const Color(0xFFF5233B) : Colors.grey.shade300,
          ),
        ),

        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFFF5233B) : Colors.grey),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFF5233B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRICE ROW
  // ==========================================

  Widget _priceRow(String title, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,

          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),

        Text(
          '\$${price.toStringAsFixed(2)}',

          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
