import '../models/food_item.dart';
import 'product_option.dart';

class CartItem {
  final FoodItem food;
  int quantity;
  final List<ProductOption> selectedOptions;

  CartItem({
    required this.food,
    this.quantity = 1,
    this.selectedOptions = const [],
  });

  ProductOption? get selectedSize {
    for (final option in selectedOptions) {
      if (option.type == 'SIZE') return option;
    }
    return null;
  }

  double get unitPrice {
    final basePrice = selectedSize?.price ?? food.price;
    final addOnPrice = selectedOptions
        .where((option) => option.type != 'SIZE')
        .fold<double>(0, (sum, option) => sum + option.extraPrice);
    return basePrice + addOnPrice;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }
}
