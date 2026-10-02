import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import '../helpers/mock_data.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, GlobalKey> _categoryKeys = {
    for (final category in MockData.categories.skip(1)) category: GlobalKey(),
  };

  final List<String> _slider = [
    'assets/images/a1.png',
    'assets/images/a2.png',
    'assets/images/a3.png',
  ];

  int currentSlideIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<FoodItem> _foodItemsForCategory(String category) {
    return MockData.foodItems
        .where((food) => food.category == category)
        .toList();
  }

  Future<void> _selectCategory(int index) async {
    setState(() {
      selectedCategoryIndex = index;
    });

    if (index == 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    final key = _categoryKeys[MockData.categories[index]];
    final targetContext = key?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  void _updateSelectedCategoryFromScroll() {
    if (!mounted) return;

    var closestIndex = 0;
    var closestDistance = double.infinity;
    final stickyHeaderBottom = MediaQuery.paddingOf(context).top + 112;

    for (var index = 1; index < MockData.categories.length; index++) {
      final key = _categoryKeys[MockData.categories[index]];
      final sectionContext = key?.currentContext;
      if (sectionContext == null) continue;

      final renderObject = sectionContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;

      final sectionTop = renderObject.localToGlobal(Offset.zero).dy;
      final distance = (sectionTop - stickyHeaderBottom).abs();
      if (sectionTop <= stickyHeaderBottom + 80 && distance < closestDistance) {
        closestDistance = distance;
        closestIndex = index;
      }
    }

    if (closestIndex != selectedCategoryIndex) {
      setState(() {
        selectedCategoryIndex = closestIndex;
      });
    }
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: MockData.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = selectedCategoryIndex == index;

            return GestureDetector(
              onTap: () => _selectCategory(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE53935) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  MockData.categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodGrid(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No food items in this category.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
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
      itemBuilder: (context, index) {
        return FoodCard(
          food: foods[index],
          onAddTap: () => _addFoodToCart(foods[index]),
        );
      },
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
        duration: const Duration(milliseconds: 5000),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            context.read<NavigationProvider>().setCurrentIndex(2);
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 5000), controller.close);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          stops: [0.1, 0.9],
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 225, 225, 225),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const FoodieAppBar(title: 'F o o d i e'),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              _updateSelectedCategoryFromScroll();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Order your\nfavourite food!',
                        style: TextStyle(
                          color: Color.fromARGB(255, 49, 49, 49),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Carousel
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CarouselSlider(
                            items: [
                              for (String item in _slider)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    item,
                                    width: 350,
                                    height: 230,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                            options: CarouselOptions(
                              height: 180,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              viewportFraction: 1.07,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  currentSlideIndex = index;
                                });
                              },
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (
                                  int index = 0;
                                  index < _slider.length;
                                  index++
                                )
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    width: currentSlideIndex == index ? 16 : 6,
                                    height: 6,
                                    margin: EdgeInsets.only(
                                      right: index == _slider.length - 1
                                          ? 0
                                          : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentSlideIndex == index
                                          ? const Color.fromARGB(
                                              255,
                                              239,
                                              43,
                                              1,
                                            )
                                          : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeaderDelegate(child: _buildCategoryChips()),
              ),
              for (final category in MockData.categories.skip(1))
                SliverToBoxAdapter(
                  child: Padding(
                    key: _categoryKeys[category],
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFoodGrid(_foodItemsForCategory(category)),
                        const SizedBox(height: 20),
                      ],
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

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: overlapsContent ? Colors.white : Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
