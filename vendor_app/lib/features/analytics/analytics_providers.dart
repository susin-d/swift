import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(apiServiceProvider));
});

final analyticsSalesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(analyticsServiceProvider).fetchSales();
});

final analyticsPerformanceProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(analyticsServiceProvider).fetchPerformance();
});

final analyticsPeakHoursProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(analyticsServiceProvider).fetchPeakHours();
});

final analyticsTopItemsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(analyticsServiceProvider).fetchTopItems();
});

class AnalyticsService {
  AnalyticsService(this._api);

  final ApiService _api;

  Future<List<dynamic>> fetchSales() async {
    final response = await _api.get('/vendor-ops/analytics/sales');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['metrics'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<Map<String, dynamic>> fetchPerformance() async {
    final response = await _api.get('/vendor-ops/analytics/performance');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['metrics'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<List<dynamic>> fetchPeakHours() async {
    final response = await _api.get('/vendor-ops/analytics/peak-hours');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['peak_hours'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<List<dynamic>> fetchTopItems() async {
    final response = await _api.get('/vendor-ops/analytics/top-items');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['top_items'] as List?)?.cast<dynamic>() ?? const [];
  }
}
