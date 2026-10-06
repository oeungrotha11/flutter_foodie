class PromoCode {
  static const foodie10 = 'FOODIE10';
  static const foodie10DiscountRate = 0.10;

  static double discountFor({
    required String code,
    required double subtotal,
  }) {
    if (code.trim().toUpperCase() != foodie10 || subtotal <= 0) return 0;
    return subtotal * foodie10DiscountRate;
  }
}
