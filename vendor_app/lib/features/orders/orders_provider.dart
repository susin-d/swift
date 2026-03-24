import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_exception.dart';
import 'package:vendor_app/core/api_service.dart';

final incomingOrderProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
  return OrdersNotifier(ref.watch(apiServiceProvider), ref);
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ApiService _api;
  final Ref _ref;
  Timer? _pollingTimer;
  final Set<String> _knownOrderIds = <String>{};

  OrdersNotifier(this._api, this._ref) : super(const AsyncValue.loading()) {
    fetchOrders();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      fetchOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      Response<dynamic> response;
      try {
        response = await _api.get('/vendor-ops/orders/active');
      } catch (e) {
        // Backward compatibility for environments that have not rolled out the
        // active-only endpoint yet.
        if (e is ApiException && e.statusCode == 404) {
          response = await _api.get('/vendor-ops/orders');
        } else {
          rethrow;
        }
      }
      if (response.statusCode == 200) {
        final rows = (response.data as List?)?.cast<dynamic>() ?? const [];
        final knownBefore = Set<String>.from(_knownOrderIds);
        for (final row in rows) {
          final id = row['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            _knownOrderIds.add(id);
          }
        }

        final firstIncoming = rows.cast<Map>().map((e) => e.cast<String, dynamic>()).firstWhere(
              (row) => row['status']?.toString().toLowerCase() == 'pending' &&
                  !knownBefore.contains(row['id']?.toString() ?? ''),
              orElse: () => <String, dynamic>{},
            );

        if (firstIncoming.isNotEmpty) {
          _ref.read(incomingOrderProvider.notifier).state = firstIncoming;
        }

        state = AsyncValue.data(rows);
      } else {
        state = AsyncValue.error('Failed to fetch orders', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      await _api.post('/vendor-ops/orders/$orderId/status',
          data: {'status': status});
      await fetchOrders();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      await _api.post('/vendor-ops/orders/$orderId/accept');
      await fetchOrders();
      _ref.read(incomingOrderProvider.notifier).state = null;
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    try {
      await _api.post('/vendor-ops/orders/$orderId/reject');
      await fetchOrders();
      _ref.read(incomingOrderProvider.notifier).state = null;
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}
