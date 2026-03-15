class DashboardSummary {
  const DashboardSummary({
    required this.totalUsers,
    required this.totalVendors,
    required this.activeOrders,
    required this.completedOrders,
    required this.revenue,
  });

  final int totalUsers;
  final int totalVendors;
  final int activeOrders;
  final int completedOrders;
  final double revenue;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalVendors: (json['total_vendors'] as num?)?.toInt() ?? 0,
      activeOrders: (json['active_orders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
