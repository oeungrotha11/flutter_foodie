import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/catalog_provider.dart';
import '../services/foodie_api.dart';
import 'delivery_tracking_screen.dart';
import '../providers/navigation_provider.dart';
import '../widgets/foodie_sliver_app_bar.dart';
import '../widgets/food_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  int? _lastNavigationIndex;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = context.watch<NavigationProvider>().currentIndex;
    if (index != _lastNavigationIndex) {
      _lastNavigationIndex = index;
      if (index == 3) _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    List<Order> orders;
    try {
      orders = (await FoodieApi.instance.orders())
          .whereType<Map>()
          .map((row) => Order.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      appBar: const FoodieAppBar(title: 'F o o d i e'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD93B32)),
            )
          : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Color(0xFFD93B32),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF242A25),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Your completed orders will appear here.',
                    style: TextStyle(color: Color(0xFF727A73), fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFD93B32),
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showReceipt(context, order),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE7EBE6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order #${order.id}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Color(0xFF252B26),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${order.itemCount} items · ${order.orderType} · ${order.paymentMethod}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF7A827B),
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFFD93B32),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      _statusBadge(order.status),
                                      const SizedBox(height: 5),
                                      _paymentStatusBadge(order.paymentStatus),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE7EBE6),
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xFF727A73),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'View receipt',
                                    style: TextStyle(
                                      color: Color(0xFF727A73),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9AA19B),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showReceipt(BuildContext parentContext, Order order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Order receipt',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF242A25),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.orderType} • ${order.paymentMethod}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 24),
                if (order.items.isEmpty)
                  const Text(
                    'Item details are unavailable for this order.',
                    style: TextStyle(color: Colors.grey),
                  )
                else ...[
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 54,
                              height: 54,
                              child: ColoredBox(
                                color: const Color(0xFFF4F6F3),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: foodImage(
                                    _receiptImageFor(parentContext, item),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity} × ${item.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [item.size, ...item.addOns].join(' • '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF252B26),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.rewardTitle.isNotEmpty || order.discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.rewardTitle.isEmpty ? 'Reward' : order.rewardTitle),
                          Text('-\$${order.discount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  if (order.subtotal > 0) ...[
                    const Divider(height: 16),
                    _receiptPriceRow('Food subtotal', order.subtotal),
                    if (order.deliveryFee > 0)
                      _receiptPriceRow('Delivery fee', order.deliveryFee),
                  ],
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFF5233B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (order.orderType.toLowerCase().contains('delivery') && order.status == OrderStatus.purchased)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(parentContext, MaterialPageRoute(
                  builder: (_) => DeliveryTrackingScreen(orderId: order.id)));
              },
              child: const Text('Track delivery'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _receiptImageFor(BuildContext context, OrderItem item) {
    if (item.imageUrl.isNotEmpty) return item.imageUrl;

    final products = context.read<CatalogProvider>().products;
    for (final product in products) {
      if (item.productId.isNotEmpty && product.id == item.productId) {
        return product.imageUrl;
      }
    }
    for (final product in products) {
      if (product.name.toLowerCase() == item.name.toLowerCase()) {
        return product.imageUrl;
      }
    }
    return '';
  }

  Widget _receiptPriceRow(String label, double amount) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('\$${amount.toStringAsFixed(2)}')],
    ),
  );


  Widget _paymentStatusBadge(String status) {
    final normalized = status.toUpperCase();
    final (label, foreground, background) = switch (normalized) {
      'PAID' => ('Paid', const Color(0xFF217A45), const Color(0xFFE4F5EA)),
      'PENDING' => ('Payment pending', const Color(0xFF2456A6), const Color(0xFFE8F0FF)),
      'FAILED' => ('Payment failed', const Color(0xFFB3261E), const Color(0xFFFCE8E6)),
      'EXPIRED' => ('Payment expired', const Color(0xFF8A4B00), const Color(0xFFFFF3D6)),
      'REFUNDED' => ('Refunded', const Color(0xFF5D3B8C), const Color(0xFFF0E8FA)),
      _ => ('Unpaid', const Color(0xFF6B7280), const Color(0xFFF0F1F3)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    final (label, foreground, background) = switch (status) {
      OrderStatus.processing => (
        'Processing',
        const Color(0xFF9A6500),
        const Color(0xFFFFF3D6),
      ),
      OrderStatus.purchased => (
        'Purchased',
        const Color(0xFF217A45),
        const Color(0xFFE4F5EA),
      ),
      OrderStatus.cancelled => (
        'Cancelled',
        const Color(0xFFB3261E),
        const Color(0xFFFCE8E6),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
