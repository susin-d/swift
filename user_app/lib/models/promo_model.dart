class PromoModel {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const PromoModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    required this.isActive,
    this.startsAt,
    this.endsAt,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'percent',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      minOrderAmount: (json['min_order_amount'] ?? 0).toDouble(),
      maxDiscountAmount: json['max_discount_amount'] != null ? (json['max_discount_amount'] as num).toDouble() : null,
      isActive: json['is_active'] ?? true,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
    );
  }
}
