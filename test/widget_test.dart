import 'package:flutter_test/flutter_test.dart';
import 'package:pos_product/helpers/mock_data.dart';
import 'package:pos_product/helpers/order_storage.dart';
import 'package:pos_product/helpers/promo_code.dart';
import 'package:pos_product/models/order.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/favorite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('adds a regular food item to the cart', () {
    final cart = CartProvider();
    final food = MockData.foodItems.first;

    cart.addToCart(
      food: food,
      quantity: 1,
      selectedSize: 0,
      cheese: false,
      bacon: false,
    );

    expect(cart.itemCount, 1);
    expect(cart.totalPrice, food.price);
  });

  test('applies FOODIE10 case-insensitively to the food subtotal', () {
    expect(PromoCode.discountFor(code: ' foodie10 ', subtotal: 25), 2.5);
    expect(PromoCode.discountFor(code: 'INVALID', subtotal: 25), 0);
    expect(PromoCode.discountFor(code: 'FOODIE10', subtotal: 0), 0);
  });

  test('new orders default to processing and preserve status and promo', () {
    const orderItem = OrderItem(
      name: 'Classic Burger',
      quantity: 2,
      size: 'Large',
      addOns: ['Extra cheese'],
      unitPrice: 12.5,
    );
    final order = Order(
      id: 'order-1',
      total: 22.5,
      orderType: 'Takeaway',
      paymentMethod: 'Cash',
      address: '',
      itemCount: 2,
      createdAt: DateTime.utc(2026),
      promoCode: 'FOODIE10',
      discount: 2.5,
      items: [orderItem],
    );

    final restored = Order.fromJson(order.toJson());

    expect(order.status, OrderStatus.processing);
    expect(restored.status, OrderStatus.processing);
    expect(restored.promoCode, 'FOODIE10');
    expect(restored.discount, 2.5);
    expect(restored.items.single.name, 'Classic Burger');
    expect(restored.items.single.quantity, 2);
    expect(restored.items.single.size, 'Large');
    expect(restored.items.single.addOns, ['Extra cheese']);
    expect(restored.items.single.totalPrice, 25);
    expect(
      order.copyWith(status: OrderStatus.cancelled).status,
      OrderStatus.cancelled,
    );
  });

  test('persists seller-updated order status', () async {
    SharedPreferences.setMockInitialValues({});
    final order = Order(
      id: 'order-2',
      total: 10,
      orderType: 'Takeaway',
      paymentMethod: 'Cash',
      address: '',
      itemCount: 1,
      createdAt: DateTime(2026),
    );
    await OrderStorage.addOrder(order);
    await OrderStorage.updateOrder(
      order.copyWith(status: OrderStatus.purchased),
    );

    final orders = await OrderStorage.loadOrders();
    expect(orders.single.status, OrderStatus.purchased);
  });

  test('saves favorites for the account and favorites screen', () async {
    SharedPreferences.setMockInitialValues({});
    final favorites = FavoriteProvider();
    await favorites.load();
    await favorites.toggleFavorite('food-1');

    final restoredFavorites = FavoriteProvider();
    await restoredFavorites.load();
    expect(restoredFavorites.favoriteCount, 1);
    expect(restoredFavorites.isFavorite('food-1'), isTrue);
  });
}
