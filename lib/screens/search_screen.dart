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
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    return MockData.foodItems.where((food) {
      final matchesCategory =
          _selectedCategory == 'All' || food.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          food.name.toLowerCase().contains(query) ||
          food.subtitle.toLowerCase().contains(query) ||
          food.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = MockData.categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE53935) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedResults(List<FoodItem> results) {
    final categories = MockData.categories
        .skip(1)
        .where((category) => results.any((food) => food.category == category));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final category in categories)
          _buildCategorySection(
            category,
            results.where((food) => food.category == category).toList(),
          ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<FoodItem> foods) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foods.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemBuilder: (context, index) => FoodCard(
              food: foods[index],
              onAddTap: () => _addFoodToCart(foods[index]),
            ),
          ),
        ],
      ),
    );
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
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryFilters(),
                const SizedBox(height: 20),
                Text(
                  _query.trim().isEmpty
                      ? (_selectedCategory == 'All'
                            ? 'Browse by category'
                            : _selectedCategory)
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
                      : _selectedCategory == 'All'
                      ? _buildGroupedResults(results)
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
