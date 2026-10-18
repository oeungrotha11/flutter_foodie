import 'package:flutter/material.dart';
import 'package:pos_product/models/food_item.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/food_image.dart';
import '../models/product_option.dart';
import '../models/cart_item.dart';
import '../services/foodie_api.dart';

class ProductDetailScreen extends StatefulWidget {
  final FoodItem food;
  final CartItem? editingItem;

  const ProductDetailScreen({super.key, required this.food, this.editingItem});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  List<ProductOption> _options = [];
  final Set<int> _selectedOptionIds = {};
  bool _loadingOptions = true;
  String? _optionsError;

  List<ProductOption> get _selectedOptions =>
      _options.where((option) => _selectedOptionIds.contains(option.id)).toList();

  int? get _selectedSizeOptionId {
    for (final option in _options) {
      if (option.type == 'SIZE' && _selectedOptionIds.contains(option.id)) {
        return option.id;
      }
    }
    return null;
  }

  bool get _requiresSize => _options.any((option) => option.type == 'SIZE');

  @override
  void initState() {
    super.initState();
    quantity = widget.editingItem?.quantity ?? 1;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() { _loadingOptions = true; _optionsError = null; });
    try {
      final options = await FoodieApi.instance.productOptions(widget.food.id);
      if (!mounted) return;
      final previousSelections = widget.editingItem?.selectedOptions ?? const [];
      final matchedSelections = options
          .where((option) => previousSelections.any((selected) => selected.id == option.id))
          .toList();
      ProductOption? previousSize;
      for (final option in matchedSelections) {
        if (option.type == 'SIZE') previousSize = option;
      }
      final previousSizeId = previousSize?.id;
      setState(() {
        _options = options;
        _selectedOptionIds
          ..clear()
          ..addAll(
            matchedSelections
                .where((option) => option.type != 'SIZE')
                .map((option) => option.id),
          );
        if (previousSizeId != null) _selectedOptionIds.add(previousSizeId);
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _optionsError = error.toString(); _loadingOptions = false; });
    }
  }

  void _toggleOption(ProductOption option, bool selected) {
    setState(() {
      if (selected) _selectedOptionIds.add(option.id);
      else _selectedOptionIds.remove(option.id);
    });
  }

  void _selectSize(int? optionId) {
    if (optionId == null) return;
    setState(() {
      _selectedOptionIds.removeWhere((id) =>
          _options.any((option) => option.id == id && option.type == 'SIZE'));
      _selectedOptionIds.add(optionId);
    });
  }

  void _openCart() {
    context.read<NavigationProvider>().setCurrentIndex(2);
    Navigator.pop(context);
  }

  void _submitSelection() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final editingItem = widget.editingItem;
    if (editingItem != null) {
      cart.updateItem(
        item: editingItem,
        quantity: quantity,
        selectedOptions: _selectedOptions,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.food.name} updated in cart')),
      );
      return;
    }

    cart.addToCart(
      food: widget.food,
      quantity: quantity,
      selectedOptions: _selectedOptions,
    );
    _showAddedToCartBottomSheet(context);
  }

  double get totalPrice {
    ProductOption? size;
    for (final option in _selectedOptions) {
      if (option.type == 'SIZE') size = option;
    }
    final addOnPrice = _selectedOptions
        .where((option) => option.type != 'SIZE')
        .fold<double>(0, (sum, option) => sum + option.extraPrice);
    return ((size?.price ?? widget.food.price) + addOnPrice) * quantity;
  }

  void _showAddedToCartBottomSheet(BuildContext context) {
    final selectedOptions = _selectedOptions.map((option) => option.name).toList();

    // Price for ONE item
    final double unitPrice = totalPrice / quantity;

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

                      child: foodImage(widget.food.imageUrl),
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

                      child: foodImage(widget.food.imageUrl),
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

                      _buildOptionControls(),
                      if (!_loadingOptions && _requiresSize && _selectedSizeOptionId == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Choose a size to continue.', style: TextStyle(color: Color(0xFFF5233B), fontSize: 12)),
                        ),
                      const SizedBox(height: 20),

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
                  onPressed: _loadingOptions || _optionsError != null || (_requiresSize && _selectedSizeOptionId == null)
                      ? null
                      : _submitSelection,

                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),

                  label: Text(widget.editingItem == null ? 'ADD TO CART' : 'UPDATE CART'),

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

  Widget _buildOptionControls() {
    if (_loadingOptions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_optionsError != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_optionsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        TextButton(onPressed: _loadOptions, child: const Text('Retry loading options')),
      ]);
    }
    if (_options.isEmpty) return const SizedBox.shrink();

    final sizes = _options.where((option) => option.type == 'SIZE').toList();
    final extras = _options.where((option) => option.type == 'ADD_ON').toList();
    final other = _options.where((option) => option.type != 'SIZE' && option.type != 'ADD_ON').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (sizes.isNotEmpty) ...[
        const Text('Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        RadioGroup<int>(
          groupValue: _selectedSizeOptionId,
          onChanged: _selectSize,
          child: Column(
            children: sizes.map((option) => RadioListTile<int>(
              value: option.id,
              selected: _selectedOptionIds.contains(option.id),
              activeColor: const Color(0xFFF5233B),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(option.name),
              subtitle: Text('\$${(option.price ?? widget.food.price).toStringAsFixed(2)}'),
            )).toList(),
          ),
        ),
        const SizedBox(height: 18),
      ],
      if (extras.isNotEmpty || other.isNotEmpty) ...[
        const Text('Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...[...extras, ...other].map((option) => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFFF5233B),
          value: _selectedOptionIds.contains(option.id),
          title: Text(option.name),
          subtitle: Text(option.extraPrice == 0 ? 'Included' : '+\$${option.extraPrice.toStringAsFixed(2)}'),
          onChanged: (selected) => _toggleOption(option, selected ?? false),
        )),
      ],
    ]);
  }
}
