enum OrderStatus { processing, purchased, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final String size;
  final List<String> addOns;
  final double unitPrice;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.size,
    required this.addOns,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'size': size,
    'addOns': addOns,
    'unitPrice': unitPrice,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    size: json['size'] as String,
    addOns: (json['addOns'] as List<dynamic>? ?? []).cast<String>(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );
}

class Order {
  final String id;
  final double total;
  final String orderType;
  final String paymentMethod;
  final String address;
  final int itemCount;
  final DateTime createdAt;
  final OrderStatus status;
  final String promoCode;
  final double discount;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.total,
    required this.orderType,
    required this.paymentMethod,
    required this.address,
    required this.itemCount,
    required this.createdAt,
    this.status = OrderStatus.processing,
    this.promoCode = '',
    this.discount = 0,
    this.items = const [],
  });

  Order copyWith({
    OrderStatus? status,
    String? promoCode,
    double? discount,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      total: total,
      orderType: orderType,
      paymentMethod: paymentMethod,
      address: address,
      itemCount: itemCount,
      createdAt: createdAt,
      status: status ?? this.status,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'orderType': orderType,
    'paymentMethod': paymentMethod,
    'address': address,
    'itemCount': itemCount,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'promoCode': promoCode,
    'discount': discount,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    return Order(
      id: json['id'] as String,
      total: (json['total'] as num).toDouble(),
      orderType: json['orderType'] as String,
      paymentMethod: json['paymentMethod'] as String,
      address: json['address'] as String? ?? '',
      itemCount: json['itemCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => OrderStatus.processing,
      ),
      promoCode: json['promoCode'] as String? ?? '',
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
