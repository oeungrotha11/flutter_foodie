import 'food_item.dart';

class FoodCategory {
  final int categoryId;
  final String categoryName;
  final String description;
  final String imageUrl;
  final int productCount;
  final List<FoodItem> products;

  const FoodCategory({
    required this.categoryId,
    required this.categoryName,
    this.description = '',
    this.imageUrl = '',
    this.productCount = 0,
    this.products = const [],
  });

  static const all = FoodCategory(categoryId: 0, categoryName: 'All');

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map>()
              .map(
                (product) =>
                    FoodItem.fromApi(Map<String, dynamic>.from(product)),
              )
              .toList()
        : <FoodItem>[];
    final productCount = _asInt(json['productCount'], products.length);

    return FoodCategory(
      categoryId: _asInt(json['categoryId'] ?? json['id']),
      categoryName: (json['categoryName'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      productCount: productCount,
      products: List.unmodifiable(products),
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'description': description,
    'imageUrl': imageUrl,
    'productCount': productCount,
    'products': products
        .map(
          (product) => {
            'productId': product.id,
            'productName': product.name,
            'description': product.subtitle,
            'unitPrice': product.price,
            'rating': product.rating,
            'imageUrl': product.imageUrl,
            'categoryName': product.category,
            'categoryId': product.categoryId,
          },
        )
        .toList(),
  };

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
