import 'package:flutter/material.dart';
import 'package:pos_product/screens/product_detail.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../providers/favorite_provider.dart';
import 'food_image.dart';

class FoodCard extends StatelessWidget {
  final FoodItem food;

  final VoidCallback? onAddTap;

  const FoodCard({super.key, required this.food, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(food: food),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7EBE6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ColoredBox(
                    color: const Color(0xFFF4F6F3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: foodImage(food.imageUrl),
                        ),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFE2A52C),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  food.rating.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF343A35),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Consumer<FavoriteProvider>(
                            builder: (context, favorites, _) {
                              final isFavorite = favorites.isFavorite(food.id);
                              return Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: isFavorite
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                  constraints: const BoxConstraints.tightFor(
                                    width: 34,
                                    height: 34,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      favorites.toggleFavorite(food.id),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? const Color(0xFFD93B32)
                                        : const Color(0xFF58615A),
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 38,
                child: Text(
                  food.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF252B26),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                food.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF7A827B), fontSize: 11),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '\$${food.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF252B26),
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton.filled(
                      tooltip: 'Add to cart',
                      onPressed: onAddTap,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFD93B32),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.add, size: 19),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
