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
    String? promoCode,
    DateTime? scheduledFor,
    String? deliveryMode,
    String? deliveryBuildingId,
    String? deliveryRoom,
    String? deliveryZoneId,
    bool? quietMode,
    String? deliveryInstructions,
    String? deliveryLocationLabel,
    DateTime? classStartAt,
    DateTime? classEndAt,
  }) async {
    final response = await _api.post('/orders', data: {
      'vendor_id': vendorId,
      'items': items,
      'total_amount': totalAmount,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      if (scheduledFor != null) 'scheduled_for': scheduledFor.toIso8601String(),
      if (deliveryMode != null) 'delivery_mode': deliveryMode,
      if (deliveryBuildingId != null) 'delivery_building_id': deliveryBuildingId,
      if (deliveryRoom != null) 'delivery_room': deliveryRoom,
      if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
      if (quietMode != null) 'quiet_mode': quietMode,
      if (deliveryInstructions != null) 'delivery_instructions': deliveryInstructions,
      if (deliveryLocationLabel != null) 'delivery_location_label': deliveryLocationLabel,
      if (classStartAt != null) 'class_start_at': classStartAt.toIso8601String(),
      if (classEndAt != null) 'class_end_at': classEndAt.toIso8601String(),
    });

    // Backend returns the created order object directly.
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderModel> getOrderDetails(String orderId) async {
    // There is no dedicated GET /orders/:id route.
    final orders = await getUserOrders();
    return orders.firstWhere((o) => o.id == orderId);
  }

  Future<OrderModel> cancelOrder(String orderId) async {
    final response = await _api.patch('/orders/$orderId/cancel');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getOrderSlots({int days = 3}) async {
    final response = await _api.get('/orders/slots', queryParameters: {
      'days': days,
    });
    final data = response.data as Map<String, dynamic>? ?? {};
    final slots = data['slots'] as List? ?? [];
    return slots.cast<Map<String, dynamic>>();
  }
}
