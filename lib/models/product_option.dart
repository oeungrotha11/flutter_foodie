class ProductOption {
  final int id;
  final String name;
  final String type;
  final double? price;
  final double extraPrice;
  final bool active;

  const ProductOption({
    required this.id,
    required this.name,
    required this.type,
    this.price,
    required this.extraPrice,
    this.active = true,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) => ProductOption(
    id: int.tryParse((json['id'] ?? json['optionId']).toString()) ?? -1,
    name: (json['optionName'] ?? json['name'] ?? '').toString(),
    type: (json['optionType'] ?? json['type'] ?? '').toString().toUpperCase(),
    price: json['price'] == null ? null : _asDouble(json['price']),
    extraPrice: _asDouble(json['extraPrice']),
    active: json['active'] != false && json['isActive'] != false,
  );

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
