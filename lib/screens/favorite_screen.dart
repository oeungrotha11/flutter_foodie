import 'package:flutter/material.dart';
import 'package:pos_product/helpers/mock_data.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';
import '../widgets/food_card.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>();
    final foodItems = MockData.foodItems
        .where((food) => favorites.isFavorite(food.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Favorites'),
      body: foodItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap the heart on a food item to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: foodItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (context, index) {
                final food = foodItems[index];
                return FoodCard(
                  food: food,
                  onAddTap: () {
                    context.read<CartProvider>().addToCart(
                      food: food,
                      quantity: 1,
                      selectedSize: 0,
                      cheese: false,
                      bacon: false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${food.name} added to cart')),
                    );
                  },
                );
              },
            ),
    );
  }
}
