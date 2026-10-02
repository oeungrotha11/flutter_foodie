import 'package:flutter_test/flutter_test.dart';
import 'package:pos_product/helpers/mock_data.dart';
import 'package:pos_product/providers/cart_provider.dart';

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
}
