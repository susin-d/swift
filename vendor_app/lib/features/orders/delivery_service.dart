import 'package:vendor_app/core/api_service.dart';

class DeliveryService {
  final ApiService _api;

  DeliveryService(this._api);

  Future<void> updateLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    await _api.post(
      '/delivery/location',
      data: {
        'order_id': orderId,
        'lat': lat,
        'lng': lng,
      },
    );
  }
}
