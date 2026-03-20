import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/finance_summary.dart';

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.summary,
    required this.payouts,
    required this.chart,
  });

  final FinanceSummary summary;
  final List<PayoutItem> payouts;
  final List<FinanceChartPoint> chart;
}

class FinanceService {
  FinanceService._();
  static final FinanceService instance = FinanceService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<FinanceSnapshot> fetchSnapshot() async {
    try {
      final results = await Future.wait([
        _dio.get<Map<String, dynamic>>('/admin/finance/summary'),
        _dio.get<Map<String, dynamic>>('/admin/finance/payouts'),
        _dio.get<Map<String, dynamic>>('/admin/charts'),
      ]);

      final summaryData = results[0].data?['summary'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final payoutsJson = (results[1].data?['payouts'] as List?) ?? const [];
      final chartJson = (results[2].data?['chartData'] as List?) ?? const [];

      return FinanceSnapshot(
        summary: FinanceSummary.fromJson(summaryData),
        payouts: payoutsJson
            .map((e) => PayoutItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        chart: chartJson
            .map((e) => FinanceChartPoint.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load finance data',
      );
    }
  }

  Future<String> exportPayoutsCsv() async {
    try {
      final response = await _dio.get<String>(
        '/admin/finance/payouts/export',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to export payouts',
      );
    }
  }
}
