import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(ref.watch(apiServiceProvider));
});

final reportsDownloadProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(reportsServiceProvider).fetchDownload();
});

final reportsSalesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(reportsServiceProvider).fetchSales();
});

final reportsOrdersProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(reportsServiceProvider).fetchOrders();
});

class ReportsService {
  ReportsService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>> fetchDownload() async {
    final response = await _api.get('/vendor-ops/reports/download');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['export'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<List<dynamic>> fetchSales() async {
    final response = await _api.get('/vendor-ops/reports/sales');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['metrics'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<Map<String, dynamic>> fetchOrders() async {
    final response = await _api.get('/vendor-ops/reports/orders');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['orders_report'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
