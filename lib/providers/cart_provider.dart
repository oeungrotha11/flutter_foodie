import 'package:flutter/foundation.dart';

import '../models/food_item.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalItems {
    return _items.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  int get itemCount {
    int count = 0;

    for (final item in _items) {
      count += item.quantity;
    }

    return count;
  }

  double get totalPrice {
    double total = 0;

    for (final item in _items) {
      total += item.totalPrice;
    }

    return total;
  }

  // =========================
  // ADD TO CART
  // =========================

  void addToCart({
    required FoodItem food,
    required int quantity,
    required int selectedSize,
    required bool cheese,
    required bool bacon,
  }) {
    final item = CartItem(
      food: food,
      quantity: quantity,
      selectedSize: selectedSize,
      cheese: cheese,
      bacon: bacon,
    );

    _items.add(item);

    notifyListeners();
  }

  // =========================
  // REMOVE ITEM
  // =========================

  void removeItem(CartItem item) {
    _items.remove(item);

    notifyListeners();
  }

  // =========================
  // INCREASE QUANTITY
  // =========================

  void increaseQuantity(CartItem item) {
    item.quantity++;

    notifyListeners();
  }

  // =========================
  // DECREASE QUANTITY
  // =========================

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;

      notifyListeners();
    }
  }

  // =========================
  // CLEAR CART
  // =========================

  void clearCart() {
    _items.clear();

    notifyListeners();
  }
}