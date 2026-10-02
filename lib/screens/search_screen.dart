import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_data.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import '../widgets/food_card.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return MockData.foodItems;
    }

    return MockData.foodItems.where((food) {
      return food.name.toLowerCase().contains(query) ||
          food.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  void _addFoodToCart(FoodItem food) {
    context.read<CartProvider>().addToCart(
      food: food,
      quantity: 1,
      selectedSize: 0,
      cheese: false,
      bacon: false,
    );

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('${food.name} added to cart'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), controller.close);
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredItems;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          stops: [0.1, 0.9],
          colors: [Colors.white, Color(0xFFE1E1E1)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: FoodieAppBar(
          title: 'Search food',
          showSearchButton: false,
          showCartButton: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search burgers, pizza, drinks...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey,),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _query.trim().isEmpty
                      ? 'All food'
                      : '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: results.isEmpty
                      ? const Center(
                          child: Text(
                            'No food found.\nTry another search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: results.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                          itemBuilder: (context, index) => FoodCard(
                            food: results[index],
                            onAddTap: () => _addFoodToCart(results[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
