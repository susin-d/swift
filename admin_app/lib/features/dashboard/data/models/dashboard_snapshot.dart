import 'chart_data_point.dart';
import 'dashboard_summary.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.summary,
    required this.chartData,
    required this.pendingVendorCount,
  });

  final DashboardSummary summary;
  final List<ChartDataPoint> chartData;
  final int pendingVendorCount;

  double get todayRevenue => chartData.isEmpty ? 0 : chartData.last.revenue;

  double get yesterdayRevenue => chartData.length < 2 ? 0 : chartData[chartData.length - 2].revenue;

  int get todayOrders => chartData.isEmpty ? 0 : chartData.last.orders;

  int get yesterdayOrders => chartData.length < 2 ? 0 : chartData[chartData.length - 2].orders;

  int get criticalQueue => pendingVendorCount + (summary.activeOrders > 0 ? (summary.activeOrders / 6).ceil() : 0);
}
