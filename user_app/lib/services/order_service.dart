import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  Future<List<OrderModel>> getUserOrders() async {
    final response = await _api.get('/orders/me');
    final List data = response.data ?? [];
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  Future<OrderModel> placeOrder({
    required String vendorId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final response = await _api.post('/orders', data: {
      'vendor_id': vendorId,
      'items': items,
      'total_amount': totalAmount,
    });

    // Backend returns the created order object directly.
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderModel> getOrderDetails(String orderId) async {
    // There is no dedicated GET /orders/:id route.
    final orders = await getUserOrders();
    return orders.firstWhere((o) => o.id == orderId);
  }
}
