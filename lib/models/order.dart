class Order {
  final String id;
  final double total;
  final String orderType;
  final String paymentMethod;
  final String address;
  final int itemCount;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.total,
    required this.orderType,
    required this.paymentMethod,
    required this.address,
    required this.itemCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'orderType': orderType,
        'paymentMethod': paymentMethod,
        'address': address,
        'itemCount': itemCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      total: (json['total'] as num).toDouble(),
      orderType: json['orderType'] as String,
      paymentMethod: json['paymentMethod'] as String,
      address: json['address'] as String? ?? '',
      itemCount: json['itemCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
