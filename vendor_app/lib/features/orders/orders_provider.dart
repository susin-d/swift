import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
  return OrdersNotifier(ref.watch(apiServiceProvider));
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ApiService _api;

  OrdersNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/vendor-ops/orders');
      if (response.statusCode == 200) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error('Failed to fetch orders', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      await _api.patch('/orders/$orderId/status', data: {'status': status});
      await fetchOrders();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}
