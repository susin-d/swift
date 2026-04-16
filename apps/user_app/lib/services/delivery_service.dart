import '../models/delivery_location.dart';
import 'api_service.dart';

class DeliveryService {
  final ApiService _api = ApiService();

  Future<DeliveryLocation?> getLocation(String orderId) async {
    if (orderId.isEmpty) return null;
    final response = await _api.get(
      '/delivery/$orderId/location',
      cancelKey: 'delivery:$orderId',
    );

    final payload = response.data;
    if (payload == null) return null;
    if (payload is! Map) return null;

    final map = payload.cast<String, dynamic>();
    final data = map['data'];
    final target = data is Map ? data.cast<String, dynamic>() : map;

    if (!target.containsKey('lat') || !target.containsKey('lng')) {
      return null;
    }

    return DeliveryLocation.fromJson(target);
  }
}
