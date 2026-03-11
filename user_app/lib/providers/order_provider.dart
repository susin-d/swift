import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref.watch(orderServiceProvider).getUserOrders();
});

// Real-time Order Tracking Provider
final orderTrackingProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  
  // Listen to status changes for specific order
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .map((data) => OrderModel.fromJson(data.first));
});
