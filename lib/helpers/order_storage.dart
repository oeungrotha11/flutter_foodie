import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';

class OrderStorage {
  static const _key = 'pos_product.orders';

  static Future<List<Order>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? [];
    return values
        .map(
          (value) => Order.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> addOrder(Order order) async {
    final orders = await loadOrders();
    orders.insert(0, order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      orders.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  static Future<void> updateOrder(Order updatedOrder) async {
    final orders = await loadOrders();
    final index = orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) {
      throw StateError('Order ${updatedOrder.id} was not found.');
    }
    orders[index] = updatedOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      orders.map((order) => jsonEncode(order.toJson())).toList(),
    );
  }
}
