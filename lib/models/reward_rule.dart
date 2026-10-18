class RewardRule {
  final int id;
  final String name;
  final String? description;
  final double minimumQualifyingSubtotal;
  final double discountRate;
  final double minimumRedemptionSubtotal;
  final int validityDays;
  final bool active;

  const RewardRule({
    required this.id,
    required this.name,
    this.description,
    required this.minimumQualifyingSubtotal,
    required this.discountRate,
    required this.minimumRedemptionSubtotal,
    required this.validityDays,
    required this.active,
  });

  factory RewardRule.fromJson(Map<String, dynamic> json) => RewardRule(
    id: _asInt(json['rewardRuleId'] ?? json['id']),
    name: (json['name'] ?? 'Shop reward').toString(),
    description: json['description']?.toString(),
    minimumQualifyingSubtotal: _asDouble(json['minimumQualifyingSubtotal']),
    discountRate: _asDouble(json['discountRate']),
    minimumRedemptionSubtotal: _asDouble(json['minimumRedemptionSubtotal']),
    validityDays: _asInt(json['validityDays']),
    active: json['active'] == true || json['active'].toString().toLowerCase() == 'true',
  );

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
