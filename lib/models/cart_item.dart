import '../models/food_item.dart';

class CartItem {
  final FoodItem food;
  int quantity;
  int selectedSize;
  bool cheese;
  bool bacon;

  CartItem({
    required this.food,
    this.quantity = 1,
    this.selectedSize = 0,
    this.cheese = false,
    this.bacon = false,
  });

  double get sizePrice {
    return selectedSize == 1 ? 2.0 : 0.0;
  }

  double get extraPrice {
    double price = 0;

    if (cheese) {
      price += 1.0;
    }

    if (bacon) {
      price += 1.5;
    }

    return price;
  }

  double get unitPrice {
    return food.price + sizePrice + extraPrice;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }
}