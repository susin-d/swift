import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/audit_log_item.dart';

class AuditResponse {
  const AuditResponse({required this.logs, required this.page, required this.limit, required this.total});

  final List<AuditLogItem> logs;
  final int page;
  final int limit;
  final int total;
}

class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<AuditResponse> fetchLogs({required int page, required int limit, String? action}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/audit', queryParameters: {
        'page': page,
        'limit': limit,
        if (action != null && action.isNotEmpty && action != 'all') 'action': action,
      });

      final data = response.data ?? const <String, dynamic>{};
      final logsJson = (data['logs'] as List?) ?? const [];

      return AuditResponse(
        logs: logsJson
            .map((e) => AuditLogItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
        total: (data['total'] as num?)?.toInt() ?? logsJson.length,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load audit logs',
      );
    }
  }
}
