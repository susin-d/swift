import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery_location.dart';
import '../services/delivery_service.dart';

const Duration _deliveryPollInterval = Duration(seconds: 6);

final deliveryServiceProvider = Provider((ref) => DeliveryService());

final deliveryLocationProvider = StreamProvider.family<DeliveryLocation?, String>((ref, orderId) {
  final service = ref.watch(deliveryServiceProvider);
  final controller = StreamController<DeliveryLocation?>();
  DeliveryLocation? lastLocation;
  bool disposed = false;

  Future<void> fetchLocation() async {
    try {
      final next = await service.getLocation(orderId);
      if (disposed) return;
      if (next != null) {
        lastLocation = next;
      }
      controller.add(lastLocation);
    } catch (_) {
      if (!disposed) {
        controller.add(lastLocation);
      }
    }
  }

  fetchLocation();
  final timer = Timer.periodic(_deliveryPollInterval, (_) => fetchLocation());

  ref.onDispose(() {
    disposed = true;
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
