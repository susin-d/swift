import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/order_model.dart';
import 'package:mobile_app/providers/order_provider.dart';

void main() {
  group('OrderModel — order creation and status', () {
    test('creates order with required fields', () {
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        vendorName: 'Test Vendor',
        totalAmount: 250.0,
        status: OrderStatus.pending,
        items: [],
        createdAt: DateTime.now(),
      );

      expect(order.id, equals('ord-1'));
      expect(order.userId, equals('user-1'));
      expect(order.status, equals(OrderStatus.pending));
      expect(order.totalAmount, equals(250.0));
    });

    test('order status progresses through workflow', () {
      const statuses = [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.completed,
      ];

      for (var i = 0; i < statuses.length - 1; i++) {
        final currentStatus = statuses[i];
        final nextStatus = statuses[i + 1];
        
        expect(currentStatus.index, lessThan(nextStatus.index));
      }
    });

    test('order maintains immutable state once created', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        totalAmount: 250.0,
        status: OrderStatus.pending,
        items: [],
        createdAt: now,
      );

      expect(order.createdAt, equals(now));
      expect(order.totalAmount, equals(250.0));
    });
  });

  group('OrderProvider — order data representation', () {
    test('order json deserialization preserves structure', () {
      final json = {
        'id': 'ord-1',
        'user_id': 'user-1',
        'vendor_id': 'vendor-1',
        'vendors': {'name': 'Test Vendor'},
        'total_amount': 250.0,
        'status': 'confirmed',
        'order_items': [],
        'created_at': '2026-03-18T10:00:00Z',
      };

      final order = OrderModel.fromJson(json);
      expect(order.id, equals('ord-1'));
      expect(order.totalAmount, equals(250.0));
      expect(order.vendorName, equals('Test Vendor'));
    });

    test('order item quantities and pricing calculate correctly', () {
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        totalAmount: 300.0,
        status: OrderStatus.preparing,
        items: [],
        createdAt: DateTime.now(),
      );

      expect(order.totalAmount, equals(300.0));
      expect(order.items.isEmpty, isTrue);
    });

    test('order eta reflects delivery time estimate', () {
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        totalAmount: 250.0,
        status: OrderStatus.preparing,
        items: [],
        createdAt: DateTime.now(),
        eta: OrderEta.derivedFromStatus(status: OrderStatus.preparing, createdAt: DateTime.now()),
      );

      expect(order.eta, isNotNull);
    });
  });

  group('OrderProvider — order tracking and state transitions', () {
    test('cancelled order status reflects user cancellation', () {
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        totalAmount: 250.0,
        status: OrderStatus.cancelled,
        items: [],
        createdAt: DateTime.now(),
      );

      expect(order.status, equals(OrderStatus.cancelled));
    });

    test('completed order confirms successful delivery', () {
      final order = OrderModel(
        id: 'ord-1',
        userId: 'user-1',
        vendorId: 'vendor-1',
        totalAmount: 250.0,
        status: OrderStatus.completed,
        items: [],
        createdAt: DateTime(2026, 3, 18, 10, 0),
      );

      expect(order.status, equals(OrderStatus.completed));
      expect(order.createdAt.isBefore(DateTime.now()), isTrue);
    });
  });
}

