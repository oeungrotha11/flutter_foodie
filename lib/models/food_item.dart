class FoodItem {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final double rating;
  final String imageUrl;
  final String category;

  FoodItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.category = 'All',
  });
}
