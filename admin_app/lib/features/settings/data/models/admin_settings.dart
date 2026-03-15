class AdminSettings {
  const AdminSettings({
    required this.commissionRate,
    required this.deliveryFee,
  });

  final double commissionRate;
  final double deliveryFee;

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      commissionRate: _toDouble(json['commission_rate']),
      deliveryFee: _toDouble(json['delivery_fee']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commission_rate': commissionRate,
      'delivery_fee': deliveryFee,
    };
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
