import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:pos_product/screens/order_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/order_storage.dart';
import '../helpers/promo_code.dart';
import '../models/order.dart';
import '../widgets/foodie_sliver_app_bar.dart';

const _brandColor = Color(0xFFF5233B);
const _pageColor = Color(0xFFF7F7F9);
const _mutedColor = Color(0xFF747782);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();
  String orderType = 'Takeaway';
  String paymentMethod = 'Cash';
  String _deliveryAddress = '';
  bool _promoApplied = false;
  String? _promoMessage;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
  }

  Future<void> _loadDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _deliveryAddress =
          [
                prefs.getString('delivery.address'),
                prefs.getString('delivery.city'),
              ]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join(', ');
    });
  }

  Future<void> _openDeliveryAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryAddressScreen()),
    );
    await _loadDeliveryAddress();
  }

  void _applyPromoCode(double subtotal) {
    final code = _promoController.text.trim().toUpperCase();
    final discount = PromoCode.discountFor(code: code, subtotal: subtotal);
    setState(() {
      if (discount > 0) {
        _promoApplied = true;
        _promoMessage = '10% discount applied to your food subtotal.';
      } else {
        _promoApplied = false;
        _promoMessage = code.isEmpty
            ? 'Enter a promo code first.'
            : 'That promo code is not valid.';
      }
    });
  }

  Future<void> _placeOrder(
    CartProvider cart,
    double total,
    double discount,
  ) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty. Add items before checkout.'),
        ),
      );
      return;
    }
    if (orderType == 'Delivery' && _deliveryAddress.isEmpty) {
      await _openDeliveryAddress();
      return;
    }
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      total: total,
      orderType: orderType,
      paymentMethod: paymentMethod,
      address: _deliveryAddress,
      itemCount: cart.totalItems,
      createdAt: DateTime.now(),
      promoCode: _promoApplied ? PromoCode.foodie10 : '',
      discount: discount,
      items: cart.items
          .map(
            (item) => OrderItem(
              name: item.food.name,
              quantity: item.quantity,
              size: item.selectedSize == 1 ? 'Large' : 'Regular',
              addOns: [
                if (item.cheese) 'Extra cheese',
                if (item.bacon) 'Bacon',
              ],
              unitPrice: item.unitPrice,
            ),
          )
          .toList(),
    );
    await OrderStorage.addOrder(order);
    if (!mounted) return;

    cart.clearCart();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(total: total)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.totalPrice;
    final deliveryFee = orderType == 'Delivery' ? 2.00 : 0.00;
    final discount = _promoApplied
        ? PromoCode.discountFor(
            code: _promoController.text,
            subtotal: subtotal,
          )
        : 0.0;
    final total = subtotal + deliveryFee - discount;

    return Scaffold(
      backgroundColor: _pageColor,
      appBar: const FoodieAppBar(
        title: 'Checkout',
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Almost there',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Choose how you’d like your order and payment.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Order type', '01'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _orderTypeOption(
                  icon: Icons.restaurant_outlined,
                  title: 'Dine in',
                  value: 'Dine In',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _orderTypeOption(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Takeaway',
                  value: 'Takeaway',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _orderTypeOption(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Delivery',
                  value: 'Delivery',
                ),
              ),
            ],
          ),
          if (orderType == 'Delivery') ...[
            const SizedBox(height: 22),
            _sectionTitle('Delivery location', '02'),
            const SizedBox(height: 12),
            _deliveryLocationCard(),
          ],
          const SizedBox(height: 24),
          _sectionTitle(
            'Payment method',
            orderType == 'Delivery' ? '03' : '02',
          ),
          const SizedBox(height: 12),
          _paymentOption(
            icon: Icons.payments_outlined,
            title: 'Cash',
            subtitle: 'Pay when your order arrives',
            value: 'Cash',
          ),
          const SizedBox(height: 10),
          _paymentOption(
            icon: Icons.credit_card_outlined,
            title: 'Credit / debit card',
            subtitle: 'Pay securely by card',
            value: 'Card',
          ),
          const SizedBox(height: 24),
          _sectionTitle('Promo code', ' '),
          const SizedBox(height: 12),
          _promoCodeEntry(subtotal),
          const SizedBox(height: 24),
          _sectionTitle('Order summary', ' '),
          const SizedBox(height: 12),
          _orderSummary(cart, subtotal, deliveryFee, discount, total),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'items'}',
                    style: const TextStyle(color: _mutedColor, fontSize: 13),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _placeOrder(cart, total, discount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Place order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String step) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (step.trim().isNotEmpty)
          Text(
            step,
            style: const TextStyle(
              color: _mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _orderTypeOption({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final selected = orderType == value;
    return Material(
      color: selected ? const Color(0xFFFFF0F2) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => orderType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 94,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _brandColor : const Color(0xFFE8E8EC),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? _brandColor : _mutedColor, size: 23),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? _brandColor : const Color(0xFF343640),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliveryLocationCard() {
    final hasAddress = _deliveryAddress.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openDeliveryAddress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E8EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: _brandColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress ? 'Deliver to' : 'Add delivery address',
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAddress
                          ? _deliveryAddress
                          : 'Choose where to deliver your order',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                hasAddress
                    ? Icons.edit_outlined
                    : Icons.add_location_alt_outlined,
                color: _brandColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = paymentMethod == value;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _brandColor : const Color(0xFFE8E8EC),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? _brandColor : _mutedColor, size: 23),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? _brandColor : const Color(0xFFB9BBC2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoCodeEntry(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_promoApplied || _promoMessage != null) {
                      setState(() {
                        _promoApplied = false;
                        _promoMessage = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _applyPromoCode(subtotal),
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _applyPromoCode(subtotal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          if (_promoMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _promoMessage!,
              style: TextStyle(
                color: _promoApplied
                    ? const Color(0xFF217A45)
                    : _brandColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Try ${PromoCode.foodie10} for 10% off your food subtotal.',
              style: TextStyle(color: _mutedColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderSummary(
    CartProvider cart,
    double subtotal,
    double deliveryFee,
    double discount,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF0)),
      ),
      child: Column(
        children: [
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 54,
                      height: 54,
                      color: _pageColor,
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        item.food.imageUrl,
                        fit: BoxFit.contain,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty ${item.quantity}',
                          style: const TextStyle(
                            color: _mutedColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          _priceRow('Subtotal', subtotal),
          const SizedBox(height: 10),
          _priceRow('Delivery fee', deliveryFee),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _priceRow('FOODIE10 discount', -discount),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _brandColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, double price) {
    final formattedPrice = price < 0
        ? '-\$${price.abs().toStringAsFixed(2)}'
        : '\$${price.toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: _mutedColor, fontSize: 13)),
        Text(
          formattedPrice,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
