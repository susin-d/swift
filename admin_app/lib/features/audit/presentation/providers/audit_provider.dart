import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/audit_log_item.dart';
import '../../data/services/audit_service.dart';

class AuditState {
  const AuditState({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.action,
  });

  final List<AuditLogItem> logs;
  final int page;
  final int limit;
  final int total;
  final String action;

  bool get hasMore => page * limit < total;

  AuditState copyWith({
    List<AuditLogItem>? logs,
    int? page,
    int? limit,
    int? total,
    String? action,
  }) {
    return AuditState(
      logs: logs ?? this.logs,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      action: action ?? this.action,
    );
  }
}

class AuditNotifier extends AsyncNotifier<AuditState> {
  static const int defaultPageSize = 20;

  @override
  Future<AuditState> build() async {
    final response = await AuditService.instance.fetchLogs(page: 1, limit: defaultPageSize);
    return AuditState(
      logs: response.logs,
      page: response.page,
      limit: response.limit,
      total: response.total,
      action: 'all',
    );
  }

  Future<void> refresh() async {
    final action = state.valueOrNull?.action ?? 'all';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await AuditService.instance.fetchLogs(
        page: 1,
        limit: defaultPageSize,
        action: action,
      );
      return AuditState(
        logs: response.logs,
        page: response.page,
        limit: response.limit,
        total: response.total,
        action: action,
      );
    });
  }

  Future<void> applyActionFilter(String action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await AuditService.instance.fetchLogs(
        page: 1,
        limit: defaultPageSize,
        action: action,
      );
      return AuditState(
        logs: response.logs,
        page: response.page,
        limit: response.limit,
        total: response.total,
        action: action,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final nextPage = current.page + 1;
    final response = await AuditService.instance.fetchLogs(
      page: nextPage,
      limit: current.limit,
      action: current.action,
    );

    state = AsyncData(current.copyWith(
      logs: [...current.logs, ...response.logs],
      page: response.page,
      total: response.total,
    ));
  }
}

final auditProvider = AsyncNotifierProvider<AuditNotifier, AuditState>(
  AuditNotifier.new,
);
