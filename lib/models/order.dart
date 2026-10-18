enum OrderStatus { processing, purchased, cancelled }

class OrderItem {
  final String name;
  final String productId;
  final String imageUrl;
  final int quantity;
  final String size;
  final List<String> addOns;
  final double unitPrice;
  final double? subtotal;

  const OrderItem({
    required this.name,
    this.productId = '',
    this.imageUrl = '',
    required this.quantity,
    required this.size,
    required this.addOns,
    required this.unitPrice,
    this.subtotal,
  });

  double get totalPrice => subtotal ?? unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'name': name,
    'productId': productId,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'size': size,
    'addOns': addOns,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : null;
    return OrderItem(
      name:
          (json['name'] ??
                  json['productName'] ??
                  product?['productName'] ??
                  product?['name'] ??
                  'Item')
              .toString(),
      productId:
          (json['productId'] ??
                  json['product_id'] ??
                  product?['productId'] ??
                  product?['id'] ??
                  '')
              .toString(),
      imageUrl:
          (json['imageUrl'] ??
                  json['productImageUrl'] ??
                  json['image'] ??
                  product?['imageUrl'] ??
                  product?['productImageUrl'] ??
                  product?['image'] ??
                  '')
              .toString(),
      quantity: _asInt(json['quantity']),
      size: (json['size'] ?? '').toString(),
      addOns: (json['addOns'] as List<dynamic>? ?? []).cast<String>(),
      unitPrice: _asDouble(json['unitPrice'] ?? json['price']),
      subtotal: json['subtotal'] == null ? null : _asDouble(json['subtotal']),
    );
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class Order {
  final String id;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final String orderType;
  final String paymentMethod;
  final String address;
  final int itemCount;
  final DateTime createdAt;
  final OrderStatus status;
  final double discount;
  final int? rewardId;
  final String rewardTitle;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.total,
    this.subtotal = 0,
    this.deliveryFee = 0,
    required this.orderType,
    required this.paymentMethod,
    required this.address,
    required this.itemCount,
    required this.createdAt,
    this.status = OrderStatus.processing,
    this.discount = 0,
    this.rewardId,
    this.rewardTitle = '',
    this.items = const [],
  });

  Order copyWith({
    OrderStatus? status,
    double? discount,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      total: total,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      orderType: orderType,
      paymentMethod: paymentMethod,
      address: address,
      itemCount: itemCount,
      createdAt: createdAt,
      status: status ?? this.status,
      discount: discount ?? this.discount,
      rewardId: rewardId,
      rewardTitle: rewardTitle,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'orderType': orderType,
    'paymentMethod': paymentMethod,
    'address': address,
    'itemCount': itemCount,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'discount': discount,
    'rewardId': rewardId,
    'rewardTitle': rewardTitle,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString().toLowerCase();
    return Order(
      id: (json['id'] ?? json['orderId'] ?? '').toString(),
      total: _number(json['total'] ?? json['totalAmount']),
      subtotal: _number(json['subtotal']),
      deliveryFee: _number(json['deliveryFee']),
      orderType: (json['orderType'] ?? 'Takeaway').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'Cash').toString(),
      address: (json['address'] ?? json['deliveryAddress'] ?? '').toString(),
      itemCount: json['itemCount'] is num ? (json['itemCount'] as num).toInt() : int.tryParse('${json['itemCount']}') ?? 0,
      createdAt: _date(json['createdAt']),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => OrderStatus.processing,
      ),
      discount: _number(json['discount']),
      rewardId: json['rewardId'] is num ? (json['rewardId'] as num).toInt() : int.tryParse('${json['rewardId']}'),
      rewardTitle: (json['rewardTitle'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
