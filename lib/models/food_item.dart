class FoodItem {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final double rating;
  final String imageUrl;
  final String category;
  final int? categoryId;

  FoodItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.category = 'All',
    this.categoryId,
  });

  factory FoodItem.fromApi(Map<String, dynamic> json) {
    final categoryValue = json['categoryName'] ?? json['category'];
    final category = categoryValue is Map
        ? (categoryValue['name'] ?? categoryValue['categoryName'] ?? 'All').toString()
        : (categoryValue ?? 'All').toString();
    return FoodItem(
      id: (json['productId'] ?? json['id'] ?? '').toString(),
      name: (json['productName'] ?? json['name'] ?? 'Unnamed product').toString(),
      subtitle: (json['description'] ?? json['subtitle'] ?? '').toString(),
      price: _number(json['unitPrice'] ?? json['price'] ?? json['basePrice']),
      rating: _number(json['rating'] ?? json['averageRating']),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      category: category,
      categoryId: _integer(json['categoryId']),
    );
  }

  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int? _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
