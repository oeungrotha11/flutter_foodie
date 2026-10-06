import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/order_storage.dart';
import '../models/order.dart';
import '../providers/navigation_provider.dart';
import '../widgets/foodie_sliver_app_bar.dart';

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
    final orders = await OrderStorage.loadOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Orders'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your completed orders will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showReceipt(context, order),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFEEF0),
                        child: Icon(
                          Icons.receipt_long,
                          color: Color(0xFFF5233B),
                        ),
                      ),
                      title: Text(
                        '#${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${order.itemCount} item(s) • ${order.orderType}\n${order.paymentMethod}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFF5233B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(order.status),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showReceipt(BuildContext context, Order order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order receipt'),
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
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  [
                                    item.size,
                                    ...item.addOns,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  if (order.promoCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Promo (${order.promoCode})'),
                          Text('-\$${order.discount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
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
