import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_provider.dart';
import '../models/food_category.dart';
import '../models/food_item.dart';
import 'product_detail.dart';
import '../widgets/food_card.dart';
import '../widgets/food_image.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedCategoryId = 0;
  Timer? _searchDebounce;
  List<FoodItem>? _remoteResults;
  bool _searchLoading = false;
  String? _searchError;

  List<FoodCategory> get _categories =>
      context.read<CatalogProvider>().categories;
  List<FoodItem> get _products => context.read<CatalogProvider>().products;
  FoodCategory get _selectedCategory => _categories.firstWhere(
    (category) => category.categoryId == _selectedCategoryId,
    orElse: () => FoodCategory.all,
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _searchError = null;
      if (value.trim().isEmpty) {
        _remoteResults = null;
        _searchLoading = false;
      }
    });
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 350), _searchProducts);
  }

  Future<void> _searchProducts() async {
    final query = _query.trim();
    if (query.isEmpty) return;
    setState(() => _searchLoading = true);
    try {
      final products = await context.read<CatalogProvider>().search(query);
      if (!mounted || _query.trim() != query) return;
      setState(() {
        _remoteResults = products;
        _searchError = null;
        _searchLoading = false;
      });
    } catch (error) {
      if (!mounted || _query.trim() != query) return;
      setState(() {
        _searchError = error.toString();
        _searchLoading = false;
      });
    }
  }

  List<FoodItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    final category = _selectedCategory;
    final categoryProducts =
        category.categoryId != 0 && category.products.isNotEmpty
        ? category.products
        : _products;
    return (_remoteResults ?? categoryProducts).where((food) {
      final matchesCategory =
          category.categoryId == 0 ||
          food.categoryId == category.categoryId ||
          food.category.toLowerCase() == category.categoryName.toLowerCase();
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
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.categoryId;
          final productCount = category.categoryId == 0
              ? _products.length
              : category.productCount > 0
              ? category.productCount
              : category.products.length;

          return ChoiceChip(
            avatar: category.imageUrl.isEmpty
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: foodImage(category.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.categoryName),
                const SizedBox(width: 5),
                Text(
                  '$productCount',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.78)
                        : const Color(0xFF8A918B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) =>
                setState(() => _selectedCategoryId = category.categoryId),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFD93B32),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFD93B32)
                  : const Color(0xFFE4E7E3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4D554F),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          );
        },
      ),
    );
  }

  Widget _buildEmptyResults(CatalogProvider catalog) {
    if (_searchLoading || (catalog.loading && catalog.products.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD93B32)),
      );
    }
    if (_searchError != null) {
      return Center(
        child: Text(
          _searchError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF727A73)),
        ),
      );
    }
    if (catalog.error != null && catalog.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(catalog.error!, textAlign: TextAlign.center),
            TextButton(onPressed: catalog.load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return const Center(
      child: Text(
        'No food found.\nTry another search.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF727A73), fontSize: 14),
      ),
    );
  }

  void _addFoodToCart(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(food: food)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final results = _filteredItems;
    final selectedCategory = _selectedCategory;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      extendBody: true,
      appBar: const FoodieAppBar(
        title: 'F o o d i e',
        showSearchButton: false,
        showCartButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find your next favorite',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF242A25),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Search dishes or browse by category.',
                style: TextStyle(color: Color(0xFF727A73), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Color(0xFF252B26), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search burgers, pizza, drinks...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8A918B),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF727A73),
                    size: 21,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF727A73),
                            size: 19,
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E7E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFD93B32),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  color: Color(0xFF727A73),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              _buildCategoryFilters(),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _query.trim().isEmpty
                            ? (selectedCategory.categoryId == 0
                                  ? 'Popular picks'
                                  : selectedCategory.categoryName)
                            : 'Search results',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF242A25),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${results.length} items',
                      style: const TextStyle(
                        color: Color(0xFF727A73),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_query.trim().isEmpty &&
                  selectedCategory.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    selectedCategory.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7A827B),
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: results.isEmpty
                    ? _buildEmptyResults(catalog)
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: results.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 276,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
    );
  }
}
