import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref.watch(orderServiceProvider).getUserOrders();
});

// Poll backend for order status to avoid direct DB permission issues in app clients.
final orderTrackingProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  final service = ref.read(orderServiceProvider);

  return Stream.periodic(const Duration(seconds: 3))
      .asyncMap((_) => service.getOrderDetails(orderId));
});
