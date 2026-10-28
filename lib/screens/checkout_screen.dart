import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/screens/delivery_address_screen.dart';
import 'package:pos_product/screens/order_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/foodie_sliver_app_bar.dart';
import '../models/order.dart';
import '../models/customer_reward.dart';
import '../models/product_option.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import '../widgets/food_image.dart';

const _brandColor = Color(0xFFF5233B);
const _pageColor = Color(0xFFF7F7F9);
const _mutedColor = Color(0xFF747782);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String orderType = 'Takeaway';
  String paymentMethod = 'Cash';
  String _deliveryAddress = '';
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  List<CustomerReward> _rewards = [];
  bool _loadingRewards = true;
  String? _rewardLoadError;
  int? _selectedRewardId;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final rewards = await FoodieApi.instance.rewards();
      if (!mounted) return;
      setState(() {
        _rewards = rewards;
        _loadingRewards = false;
        _rewardLoadError = null;
        if (!_rewards.any((reward) => reward.id == _selectedRewardId && reward.isAvailable)) {
          _selectedRewardId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRewards = false;
        _rewardLoadError = error.toString();
      });
    }
  }

  CustomerReward? _eligibleReward(double subtotal) {
    for (final reward in _rewards) {
      if (reward.id == _selectedRewardId && reward.isAvailable &&
          subtotal >= reward.minimumRedemptionSubtotal) return reward;
    }
    return null;
  }

  Future<void> _loadDeliveryAddress() async {
    String address = '';
    try {
      final remote = await FoodieApi.instance.deliveryAddress();
      _deliveryLatitude = (remote['latitude'] as num?)?.toDouble();
      _deliveryLongitude = (remote['longitude'] as num?)?.toDouble();
      address = [remote['address'], remote['city']]
          .whereType<String>().map((value) => value.trim())
          .where((value) => value.isNotEmpty).join(', ');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      _deliveryLatitude = prefs.getDouble('delivery.latitude');
      _deliveryLongitude = prefs.getDouble('delivery.longitude');
      address = [prefs.getString('delivery.address'), prefs.getString('delivery.city')]
          .whereType<String>().map((value) => value.trim())
          .where((value) => value.isNotEmpty).join(', ');
    }
    if (!mounted) return;
    setState(() => _deliveryAddress = address);
  }

  Future<void> _openDeliveryAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryAddressScreen()),
    );
    await _loadDeliveryAddress();
  }

  Future<String?> _cartItemMissingSize(CartProvider cart) async {
    final optionsByProduct = <String, List<ProductOption>>{};
    for (final item in cart.items) {
      if (!optionsByProduct.containsKey(item.food.id)) {
        optionsByProduct[item.food.id] =
            await FoodieApi.instance.productOptions(item.food.id);
      }
      final options = optionsByProduct[item.food.id]!;
      final sizes = options.where((option) => option.type == 'SIZE').toList();
      if (sizes.isEmpty) continue;

      final selectedSizeIds = item.selectedOptions
          .where((option) => option.type == 'SIZE')
          .map((option) => option.id)
          .toList();
      if (selectedSizeIds.length != 1 ||
          !sizes.any((option) => option.id == selectedSizeIds.single)) {
        return item.food.name;
      }
    }
    return null;
  }

  Future<void> _placeOrder(CartProvider cart) async {
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
    try {
      final missingSizeProduct = await _cartItemMissingSize(cart);
      if (missingSizeProduct != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Choose exactly one size for $missingSizeProduct. Go back to your cart and tap Edit.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

    final request = {
      'orderType': orderType,
      'paymentMethod': paymentMethod,
      'deliveryAddress': orderType == 'Delivery' ? _deliveryAddress : '',
      if (orderType == 'Delivery' && _deliveryLatitude != null) 'deliveryLatitude': _deliveryLatitude,
      if (orderType == 'Delivery' && _deliveryLongitude != null) 'deliveryLongitude': _deliveryLongitude,
      if (_eligibleReward(cart.totalPrice) != null) 'rewardId': _selectedRewardId,
      'items': cart.items.map((item) => {
        'productId': int.tryParse(item.food.id) ?? item.food.id,
        'quantity': item.quantity,
        'optionIds': item.selectedOptions.map((option) => option.id).toList(),
      }).toList(),
    };
      final response = await FoodieApi.instance.placeOrder(request);
      if (response is! Map) throw const ApiException('The server returned an invalid order response.');
      final order = Order.fromJson(Map<String, dynamic>.from(response));
      final finalTotal = order.total;
      if (!mounted) return;
      cart.clearCart();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(total: finalTotal, orderId: order.id)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is ApiException ? error.message : 'Unable to place order. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.totalPrice;
    final reward = _eligibleReward(subtotal);
    final discount = reward == null ? 0.0 : subtotal * reward.discountRate;
    final total = subtotal - discount;

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
          const SizedBox(height: 10),
          _orderTypeOption(
            icon: Icons.restaurant,
            title: 'Dine In',
            value: 'Dine In',
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
          _paymentOption(icon: Icons.payments_outlined, title: 'Cash', subtitle: 'Cash payment', value: 'Cash'),
          const SizedBox(height: 8),
          _paymentOption(icon: Icons.qr_code_2, title: 'QR Payment', subtitle: 'Pay by QR code', value: 'QR Payment'),
          const SizedBox(height: 8),
          _paymentOption(icon: Icons.credit_card_outlined, title: 'Card', subtitle: 'Credit or debit card', value: 'Card'),
          const SizedBox(height: 24),
          _sectionTitle('Reward wallet', ' '),
          const SizedBox(height: 12),
          _rewardSelector(subtotal),
          const SizedBox(height: 24),
          _sectionTitle('Order summary', ' '),
          const SizedBox(height: 12),
          _orderSummary(cart, subtotal, discount, total),
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
                  onPressed: () => _placeOrder(cart),
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

  Widget _rewardSelector(double subtotal) {
    if (_loadingRewards) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (_rewardLoadError != null) {
      return _rewardPanel(
        'Could not load rewards',
        'Check your connection and try again.',
        action: TextButton(onPressed: _loadRewards, child: const Text('Retry')),
      );
    }
    final available = _rewards.where((reward) => reward.isAvailable).toList();
    if (available.isEmpty) {
      return _rewardPanel('No available rewards', 'Rewards earned from completed orders will appear here.');
    }
    return Column(
      children: available.map((reward) {
        final meetsMinimum = subtotal >= reward.minimumRedemptionSubtotal;
        final selected = reward.id == _selectedRewardId;
        final percent = (reward.discountRate * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _brandColor : const Color(0xFFE8E8EC), width: selected ? 1.5 : 1),
          ),
          child: RadioListTile<int>(
            value: reward.id,
            groupValue: _selectedRewardId,
            activeColor: _brandColor,
            onChanged: !meetsMinimum && !selected
                ? null
                : (id) {
                    if (selected) {
                      setState(() => _selectedRewardId = null);
                    } else {
                      setState(() => _selectedRewardId = id);
                    }
                  },
            title: Text(reward.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(meetsMinimum
                ? '$percent% off this food subtotal'
                : 'Order at least \$${reward.minimumRedemptionSubtotal.toStringAsFixed(2)} to use'),
          ),
        );
      }).toList(),
    );
  }

  Widget _rewardPanel(String title, String detail, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Row(children: [const Icon(Icons.card_giftcard_outlined, color: _brandColor), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(detail, style: const TextStyle(color: _mutedColor, fontSize: 12))])), if (action != null) action]),
    );
  }

  Widget _orderSummary(CartProvider cart, double subtotal, double discount, double total) {
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
                      child: foodImage(item.food.imageUrl),
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
                          [
                            'Qty ${item.quantity}',
                            ...item.selectedOptions.map((option) => option.name),
                          ].join(' · '),
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
          _priceRow('Food subtotal (estimate)', subtotal),
          const SizedBox(height: 10),
          if (orderType == 'Delivery')
            _infoPriceRow('Delivery fee', 'Calculated by server')
          else
            _infoPriceRow('Service fee', 'None'),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _priceRow('Reward estimate', -discount),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated total',
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
          const SizedBox(height: 8),
          const Text(
            'Final prices, delivery fee, and reward discount are confirmed by the server when you place the order.',
            style: TextStyle(color: _mutedColor, fontSize: 11),
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

  Widget _infoPriceRow(String title, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(color: _mutedColor, fontSize: 13)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}
