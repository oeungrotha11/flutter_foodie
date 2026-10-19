import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../models/food_item.dart';
import '../models/reward_rule.dart';
import '../services/foodie_api.dart';
import 'product_detail.dart';
import '../widgets/food_card.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int selectedCategoryIndex = 0;
  final ScrollController _categoryScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryChipKeys = {};

  final List<String> _slider = [
    'assets/images/a1.png',
    'assets/images/a2.png',
    'assets/images/a3.png',
  ];

  int currentSlideIndex = 0;
  late Future<List<RewardRule>> _rewardRulesFuture;

  @override
  void initState() {
    super.initState();
    _rewardRulesFuture = FoodieApi.instance.rewardRules();
  }

  List<String> get _categories => context
      .read<CatalogProvider>()
      .categories
      .map((category) => category.categoryName)
      .toList(growable: false);
  List<FoodItem> get _products => context.read<CatalogProvider>().products;

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  GlobalKey _chipKey(String category) {
    return _categoryChipKeys.putIfAbsent(category, GlobalKey.new);
  }

  void _scheduleSelectedCategoryReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _categories.isEmpty) return;

      final index = selectedCategoryIndex.clamp(0, _categories.length - 1);
      final key = _chipKey(_categories[index]);
      final targetContext = key.currentContext;
      if (targetContext == null) return;

      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5,
        ),
      );
    });
  }

  Future<void> _selectCategory(int index) async {
    if (index < 0 || index >= _categories.length) return;
    setState(() {
      selectedCategoryIndex = index;
    });
    _scheduleSelectedCategoryReveal();
  }

  List<FoodItem> _visibleProducts() {
    if (_categories.isEmpty || selectedCategoryIndex == 0) return _products;

    final category = _categories[selectedCategoryIndex];
    if (category == 'All') return _products;
    return _products.where((food) => food.category == category).toList();
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        controller: _categoryScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategoryIndex == index;

          return ChoiceChip(
            key: _chipKey(category),
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => _selectCategory(index),
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


  Widget _buildShopRewardCard() {
    return FutureBuilder<List<RewardRule>>(
      future: _rewardRulesFuture,
      builder: (context, snapshot) {
        final rules = snapshot.data;
        if (rules == null || rules.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 300,
              child: _buildSingleShopRewardCard(rules[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleShopRewardCard(RewardRule rule) {
    final percent = (rule.discountRate * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF292F2A), Color(0xFF414A40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Color(0xFFFFD782),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SHOP REWARD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFFFD782),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      percent.toString() + '% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rule.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Earn after spending ' + r'$' +
                      rule.minimumQualifyingSubtotal.toStringAsFixed(2) + '+',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Redeem at ' + r'$' +
                      rule.minimumRedemptionSubtotal.toStringAsFixed(2) +
                      '+ · ' + rule.validityDays.toString() + ' days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
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
    final foods = _visibleProducts();
    final selectedIndex = catalog.categories.isEmpty
        ? 0
        : selectedCategoryIndex.clamp(0, catalog.categories.length - 1);
    final selectedCategory = catalog.categories.isEmpty
        ? 'All dishes'
        : catalog.categories[selectedIndex].categoryName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      extendBody: true,
      appBar: const FoodieAppBar(title: 'F o o d i e'),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What are you craving?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF242A25),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Fresh picks, ready when you are.',
                    style: TextStyle(color: Color(0xFF727A73), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        items: [
                          for (final item in _slider)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                item,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                        options: CarouselOptions(
                          height: 158,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          viewportFraction: 1,
                          onPageChanged: (index, reason) {
                            setState(() => currentSlideIndex = index);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var index = 0; index < _slider.length; index++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: currentSlideIndex == index ? 18 : 6,
                                height: 6,
                                margin: EdgeInsets.only(
                                  right: index == _slider.length - 1 ? 0 : 5,
                                ),
                                decoration: BoxDecoration(
                                  color: currentSlideIndex == index
                                      ? const Color(0xFFD93B32)
                                      : Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildShopRewardCard(),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(child: _buildCategoryChips()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      selectedCategory == 'All'
                          ? 'Popular picks'
                          : selectedCategory,
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
                    '${foods.length} items',
                    style: const TextStyle(
                      color: Color(0xFF727A73),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: catalog.loading
                    ? const CircularProgressIndicator(color: Color(0xFFD93B32))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            catalog.error ?? 'No products are available.',
                            style: const TextStyle(color: Color(0xFF727A73)),
                          ),
                          if (catalog.error != null)
                            TextButton(
                              onPressed: catalog.load,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
              ),
            )
          else if (foods.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No items in this category yet.',
                  style: TextStyle(color: Color(0xFF727A73)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FoodCard(
                    food: foods[index],
                    onAddTap: () => _addFoodToCart(foods[index]),
                  ),
                  childCount: foods.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 276,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: const Color(0xFFF5F7F4), child: child);
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
