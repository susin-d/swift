import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_order.dart';
import '../../data/services/orders_service.dart';

class OrdersState {
  const OrdersState({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
    required this.filter,
  });

  final List<AdminOrder> orders;
  final int page;
  final int limit;
  final int total;
  final String filter;

  bool get hasMore => page * limit < total;

  OrdersState copyWith({
    List<AdminOrder>? orders,
    int? page,
    int? limit,
    int? total,
    String? filter,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      filter: filter ?? this.filter,
    );
  }
}

class OrdersNotifier extends AsyncNotifier<OrdersState> {
  static const int defaultPageSize = 20;

  @override
  Future<OrdersState> build() async {
    final response = await OrdersService.instance.fetchOrders(page: 1, limit: defaultPageSize);
    return OrdersState(
      orders: response.orders,
      page: response.page,
      limit: response.limit,
      total: response.total,
      filter: 'all',
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filter = current?.filter ?? 'all';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await OrdersService.instance.fetchOrders(
        page: 1,
        limit: defaultPageSize,
        status: filter,
      );
      return OrdersState(
        orders: response.orders,
        page: response.page,
        limit: response.limit,
        total: response.total,
        filter: filter,
      );
    });
  }

  Future<void> applyFilter(String filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await OrdersService.instance.fetchOrders(
        page: 1,
        limit: defaultPageSize,
        status: filter,
      );
      return OrdersState(
        orders: response.orders,
        page: response.page,
        limit: response.limit,
        total: response.total,
        filter: filter,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final nextPage = current.page + 1;
    final response = await OrdersService.instance.fetchOrders(
      page: nextPage,
      limit: current.limit,
      status: current.filter,
    );

    state = AsyncData(current.copyWith(
      page: response.page,
      total: response.total,
      orders: [...current.orders, ...response.orders],
    ));
  }

  Future<String?> cancelOrder(String orderId, {required String reason}) async {
    try {
      await OrdersService.instance.cancelOrder(orderId, reason: reason);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final ordersProvider = AsyncNotifierProvider<OrdersNotifier, OrdersState>(
  OrdersNotifier.new,
);
