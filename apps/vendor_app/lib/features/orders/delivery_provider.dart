import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';
import 'delivery_service.dart';

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService(ref.watch(apiServiceProvider));
});
