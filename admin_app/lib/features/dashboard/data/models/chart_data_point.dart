class ChartDataPoint {
  const ChartDataPoint({
    required this.day,
    required this.orders,
    required this.revenue,
  });

  final String day;
  final int orders;
  final double revenue;

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      day: (json['name'] as String?) ?? 'N/A',
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
