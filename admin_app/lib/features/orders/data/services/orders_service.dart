import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/admin_order.dart';

class OrdersResponse {
  const OrdersResponse({required this.orders, required this.page, required this.limit, required this.total});

  final List<AdminOrder> orders;
  final int page;
  final int limit;
  final int total;
}

class OrdersService {
  OrdersService._();
  static final OrdersService instance = OrdersService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<OrdersResponse> fetchOrders({
    required int page,
    required int limit,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/orders',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        },
      );

      final data = response.data ?? const <String, dynamic>{};
      final ordersJson = (data['orders'] as List?) ?? const [];

      return OrdersResponse(
        orders: ordersJson
            .map((e) => AdminOrder.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
        total: (data['total'] as num?)?.toInt() ?? ordersJson.length,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load orders',
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _dio.patch('/admin/orders/$orderId/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to cancel order',
      );
    }
  }
}
