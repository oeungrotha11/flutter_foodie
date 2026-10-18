class CustomerReward {
  final int id;
  final String title;
  final double discountRate;
  final double minimumRedemptionSubtotal;
  final String status;
  final DateTime? earnedAt;
  final DateTime? expiresAt;
  final DateTime? redeemedAt;

  const CustomerReward({
    required this.id,
    required this.title,
    required this.discountRate,
    required this.minimumRedemptionSubtotal,
    required this.status,
    this.earnedAt,
    this.expiresAt,
    this.redeemedAt,
  });

  bool get isAvailable =>
      status.toUpperCase() == 'AVAILABLE' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  String get displayStatus =>
      status.toUpperCase() == 'AVAILABLE' && !isAvailable ? 'EXPIRED' : status;

  factory CustomerReward.fromJson(Map<String, dynamic> json) => CustomerReward(
    id: _asInt(json['rewardId'] ?? json['id']),
    title: (json['title'] ?? 'Foodie reward').toString(),
    discountRate: _asDouble(json['discountRate']),
    minimumRedemptionSubtotal: _asDouble(json['minimumRedemptionSubtotal']),
    status: (json['status'] ?? 'UNKNOWN').toString().toUpperCase(),
    earnedAt: _asDate(json['earnedAt']),
    expiresAt: _asDate(json['expiresAt']),
    redeemedAt: _asDate(json['redeemedAt']),
  );

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static DateTime? _asDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
