class FinanceSummary {
  const FinanceSummary({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.totalRevenue,
  });

  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double totalRevenue;

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      todayRevenue: _toDouble(json['today_revenue']),
      weekRevenue: _toDouble(json['week_revenue']),
      monthRevenue: _toDouble(json['month_revenue']),
      totalRevenue: _toDouble(json['total_revenue']),
    );
  }
}

class PayoutItem {
  const PayoutItem({
    required this.vendorId,
    required this.vendorName,
    required this.totalRevenue,
    required this.totalOrders,
    required this.status,
  });

  final String vendorId;
  final String vendorName;
  final double totalRevenue;
  final int totalOrders;
  final String status;

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      vendorId: (json['vendor_id'] as String?) ?? '',
      vendorName: (json['vendor_name'] as String?) ?? 'Unknown vendor',
      totalRevenue: _toDouble(json['total_revenue']),
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}

class FinanceChartPoint {
  const FinanceChartPoint({required this.day, required this.orders, required this.revenue});

  final String day;
  final int orders;
  final double revenue;

  factory FinanceChartPoint.fromJson(Map<String, dynamic> json) {
    return FinanceChartPoint(
      day: (json['name'] as String?) ?? '-',
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: _toDouble(json['revenue']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
