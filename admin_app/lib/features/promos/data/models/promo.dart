class Promo {
  const Promo({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.isActive,
    required this.usageLimit,
    required this.usageCount,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final bool isActive;
  final int? usageLimit;
  final int usageCount;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'percent',
      discountValue: _toDouble(json['discount_value']),
      minOrderAmount: _toDouble(json['min_order_amount']),
      maxDiscountAmount: json['max_discount_amount'] == null ? null : _toDouble(json['max_discount_amount']),
      isActive: json['is_active'] ?? true,
      usageLimit: json['usage_limit'] == null ? null : int.tryParse(json['usage_limit'].toString()),
      usageCount: int.tryParse(json['usage_count']?.toString() ?? '0') ?? 0,
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
