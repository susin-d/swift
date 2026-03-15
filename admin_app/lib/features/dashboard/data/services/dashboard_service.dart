import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/chart_data_point.dart';
import '../models/dashboard_snapshot.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<DashboardSnapshot> fetchSnapshot() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/admin/dashboard/summary'),
        _dio.get<Map<String, dynamic>>('/admin/charts'),
        _dio.get<Map<String, dynamic>>('/admin/vendors/pending'),
      ]);

      final summaryJson = (responses[0].data?['summary'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final chartJson = (responses[1].data?['chartData'] as List?) ?? const [];
      final vendorsJson = (responses[2].data?['vendors'] as List?) ?? const [];

      final summary = DashboardSummary.fromJson(summaryJson);
      final chartData = chartJson
          .map((e) => ChartDataPoint.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      return DashboardSnapshot(
        summary: summary,
        chartData: chartData,
        pendingVendorCount: vendorsJson.length,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load dashboard',
      );
    }
  }
}
