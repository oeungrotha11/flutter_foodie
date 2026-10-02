import 'package:flutter/material.dart';
import 'package:pos_product/models/food_item.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final FoodItem food;

  const ProductDetailScreen({super.key, required this.food});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int selectedSize = 0;

  bool cheese = false;
  bool bacon = false;

  bool get supportsSize =>
      widget.food.category == 'Pizza' || widget.food.category == 'Burger';

  bool get supportsExtras => widget.food.category == 'Burger';

  double get extraPrice {
    if (!supportsExtras) {
      return 0;
    }

    double price = 0;

    if (cheese) {
      price += 1.0;
    }

    if (bacon) {
      price += 1.5;
    }

    return price;
  }

  void _openCart() {
    context.read<NavigationProvider>().setCurrentIndex(2);
    Navigator.pop(context);
  }

  double get sizePrice {
    if (!supportsSize) {
      return 0;
    }

    if (selectedSize == 1) {
      return 2.0;
    }

    return 0;
  }

  double get totalPrice {
    return (widget.food.price + sizePrice + extraPrice) * quantity;
  }

  void _showAddedToCartBottomSheet(BuildContext context) {
    // Build selected options
    final List<String> selectedOptions = [];

    if (supportsSize) {
      if (selectedSize == 1) {
        selectedOptions.add('Large');
      } else {
        selectedOptions.add('Regular');
      }
    }

    if (supportsExtras) {
      if (cheese) {
        selectedOptions.add('Extra Cheese');
      }
      if (bacon) {
        selectedOptions.add('Extra Bacon');
      }
    }

    // Price for ONE item
    final double unitPrice = widget.food.price + sizePrice + extraPrice;

    // Price for all quantities
    final double finalTotal = unitPrice * quantity;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,

      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 25),

          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // =====================================
              // DRAG HANDLE
              // =====================================
              Container(
                width: 45,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              // =====================================
              // SUCCESS ICON
              // =====================================
              Container(
                width: 50,
                height: 50,

                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),

                child: const Icon(Icons.check, color: Colors.green, size: 28),
              ),

              const SizedBox(height: 12),

              const Text(
                'Added to Cart!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // =====================================
              // PRODUCT
              // =====================================
              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================
                    // IMAGE
                    // =================================
                    Container(
                      width: 75,
                      height: 75,

                      padding: const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Image.asset(
                        widget.food.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // =================================
                    // INFORMATION
                    // =================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            widget.food.name,

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Selected options
                          Text(
                            selectedOptions.join(' • '),

                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Quantity + unit price
                          Row(
                            children: [
                              Text(
                                '$quantity × ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              Text(
                                '\$${unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          // Total
                          Text(
                            '\$${finalTotal.toStringAsFixed(2)}',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF5233B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =====================================
              // GO TO CART
              // =====================================
              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                    _openCart();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5233B),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'GO TO CART',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =====================================
              // CONTINUE SHOPPING
              // =====================================
              SizedBox(
                width: double.infinity,
                height: 48,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                  },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF5233B),

                    side: const BorderSide(color: Color(0xFFF5233B)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'CONTINUE SHOPPING',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // =====================================
            // IMAGE SECTION
            // =====================================
            SizedBox(
              height: 320,

              child: Stack(
                children: [
                  // Product image
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),

                      child: Image.asset(
                        widget.food.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: 15,
                    left: 20,

                    child: _circleButton(
                      icon: Icons.arrow_back,

                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // Cart button with badge
                  Positioned(
                    top: 15,
                    right: 20,
                    child: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Cart icon
                              IconButton(
                                onPressed: () {
                                  _openCart();
                                },
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 20,
                                ),
                              ),

                              // Badge
                              if (cart.totalItems > 0)
                                Positioned(
                                  right: 0,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5233B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cart.totalItems}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // =====================================
            // PRODUCT INFORMATION
            // =====================================
            Expanded(
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 15,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // =====================================
                      // PRODUCT NAME
                      // =====================================
                      Text(
                        widget.food.name,

                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // =====================================
                      // RATING
                      // =====================================
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),

                          const SizedBox(width: 5),

                          Text(
                            widget.food.rating.toString(),

                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            'Rating',

                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // =====================================
                      // PRICE
                      // =====================================
                      Text(
                        '\$${widget.food.price.toStringAsFixed(2)}',

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5233B),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // =====================================
                      // DESCRIPTION
                      // =====================================
                      Text(
                        widget.food.subtitle,

                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 25),

                      if (supportsSize) ...[
                        // =====================================
                        // SIZE
                        // =====================================
                        const Text(
                          'Size',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _sizeButton(title: 'Regular', index: 0),

                            const SizedBox(width: 10),

                            _sizeButton(title: 'Large +\$2', index: 1),
                          ],
                        ),

                        const SizedBox(height: 25),
                      ],

                      if (supportsExtras) ...[
                        // =====================================
                        // EXTRAS
                        // =====================================
                        const Text(
                          'Extras',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        _extraItem(
                          title: 'Extra Cheese',
                          price: '+\$1.00',
                          value: cheese,

                          onChanged: (value) {
                            setState(() {
                              cheese = value;
                            });
                          },
                        ),

                        _extraItem(
                          title: 'Extra Bacon',
                          price: '+\$1.50',
                          value: bacon,

                          onChanged: (value) {
                            setState(() {
                              bacon = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),
                      ],

                      // =====================================
                      // QUANTITY
                      // =====================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          const Text(
                            'Quantity',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Container(
                            height: 42,

                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),

                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Row(
                              children: [
                                // Minus
                                IconButton(
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                      });
                                    }
                                  },

                                  icon: const Icon(Icons.remove, size: 18),
                                ),

                                // Quantity
                                Text(
                                  '$quantity',

                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Plus
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                    });
                                  },

                                  icon: const Icon(Icons.add, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // =====================================
      // BOTTOM CART BAR
      // =====================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 15),

          decoration: const BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),

          child: Row(
            children: [
              // =====================================
              // TOTAL
              // =====================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      'Total',

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',

                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================
              // ADD TO CART
              // =====================================
              SizedBox(
                height: 50,

                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).addToCart(
                      food: widget.food,
                      quantity: quantity,
                      selectedSize: selectedSize,
                      cheese: cheese,
                      bacon: bacon,
                    );

                    _showAddedToCartBottomSheet(context);
                  },

                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),

                  label: const Text('ADD TO CART'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5233B),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    padding: const EdgeInsets.symmetric(horizontal: 22),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================
  // CIRCLE BUTTON
  // =====================================
  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),

      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20)),
    );
  }

  // =====================================
  // SIZE BUTTON
  // =====================================
  Widget _sizeButton({required String title, required int index}) {
    final bool selected = selectedSize == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = index;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),

        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEEF0) : Colors.white,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(
            color: selected ? const Color(0xFFF5233B) : Colors.grey.shade300,
          ),
        ),

        child: Text(
          title,

          style: TextStyle(
            fontSize: 12,

            fontWeight: FontWeight.w600,

            color: selected ? const Color(0xFFF5233B) : Colors.black87,
          ),
        ),
      ),
    );
  }

  // =====================================
  // EXTRA ITEM
  // =====================================
  Widget _extraItem({
    required String title,
    required String price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,

          activeColor: const Color(0xFFF5233B),

          onChanged: (value) {
            onChanged(value ?? false);
          },
        ),

        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),

        Text(
          price,

          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
