import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/order_model.dart';

void main() {
  group('OrderModel.fromJson', () {
    final baseJson = {
      'id': 'order-1',
      'user_id': 'user-1',
      'vendor_id': 'vendor-1',
      'vendors': {'name': 'Campus Canteen'},
      'total_amount': 150.0,
      'status': 'pending',
      'order_items': [
        {
          'id': 'oi-1',
          'menu_item_id': 'mi-1',
          'quantity': 2,
          'unit_price': 75.0,
          'menu_items': {'id': 'mi-1', 'menu_id': 'menu-1', 'name': 'Samosa', 'price': 75.0},
        }
      ],
      'created_at': '2025-01-01T10:00:00.000Z',
      'eta': {'min_minutes': 14, 'max_minutes': 24, 'confidence': 'high', 'note': 'Estimate'},
    };

    test('parses all fields correctly', () {
      final order = OrderModel.fromJson(baseJson);

      expect(order.id, equals('order-1'));
      expect(order.userId, equals('user-1'));
      expect(order.vendorId, equals('vendor-1'));
      expect(order.vendorName, equals('Campus Canteen'));
      expect(order.totalAmount, equals(150.0));
      expect(order.status, equals(OrderStatus.pending));
      expect(order.items.length, equals(1));
      expect(order.createdAt, equals(DateTime.parse('2025-01-01T10:00:00.000Z')));
    });

    test('parses order_items correctly', () {
      final order = OrderModel.fromJson(baseJson);
      final item = order.items.first;

      expect(item.id, equals('oi-1'));
      expect(item.menuItemId, equals('mi-1'));
      expect(item.quantity, equals(2));
      expect(item.unitPrice, equals(75.0));
      expect(item.menuItem?.name, equals('Samosa'));
    });

    test('parses eta from json when present', () {
      final order = OrderModel.fromJson(baseJson);

      expect(order.eta, isNotNull);
      expect(order.eta!.minMinutes, equals(14));
      expect(order.eta!.maxMinutes, equals(24));
      expect(order.eta!.confidence, equals('high'));
      expect(order.eta!.note, equals('Estimate'));
    });

    test('derives eta from status when eta field absent', () {
      final jsonNoEta = Map<String, dynamic>.from(baseJson)..remove('eta');
      final order = OrderModel.fromJson(jsonNoEta);

      expect(order.eta, isNotNull);
      expect(order.eta!.confidence, equals('high')); // pending → high
    });

    test('vendorName is null when vendors field absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('vendors');
      final order = OrderModel.fromJson(json);

      expect(order.vendorName, isNull);
    });

    test('empty order_items when field is null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['order_items'] = null;
      final order = OrderModel.fromJson(json);

      expect(order.items, isEmpty);
    });
  });

  group('OrderModel status string mapping', () {
    final statusCases = {
      'pending': OrderStatus.pending,
      'accepted': OrderStatus.accepted,
      'preparing': OrderStatus.preparing,
      'ready': OrderStatus.ready,
      'completed': OrderStatus.completed,
      'cancelled': OrderStatus.cancelled,
    };

    for (final entry in statusCases.entries) {
      test('maps "${entry.key}" to ${entry.value}', () {
        final json = {
          'id': 'o', 'user_id': 'u', 'vendor_id': 'v',
          'total_amount': 0.0, 'status': entry.key,
          'created_at': '2025-01-01T10:00:00.000Z',
        };
        final order = OrderModel.fromJson(json);
        expect(order.status, equals(entry.value));
      });
    }

    test('unknown status defaults to pending', () {
      final json = {
        'id': 'o', 'user_id': 'u', 'vendor_id': 'v',
        'total_amount': 0.0, 'status': 'unknown_value',
        'created_at': '2025-01-01T10:00:00.000Z',
      };
      final order = OrderModel.fromJson(json);
      expect(order.status, equals(OrderStatus.pending));
    });

    test('statusText returns uppercase status name', () {
      final json = {
        'id': 'o', 'user_id': 'u', 'vendor_id': 'v',
        'total_amount': 0.0, 'status': 'preparing',
        'created_at': '2025-01-01T10:00:00.000Z',
      };
      expect(OrderModel.fromJson(json).statusText, equals('PREPARING'));
    });
  });

  group('OrderEta.fromJson', () {
    test('parses all fields', () {
      final eta = OrderEta.fromJson({
        'min_minutes': 6,
        'max_minutes': 14,
        'confidence': 'medium',
        'note': 'Preparing your food.',
      });

      expect(eta.minMinutes, equals(6));
      expect(eta.maxMinutes, equals(14));
      expect(eta.confidence, equals('medium'));
      expect(eta.note, equals('Preparing your food.'));
    });

    test('defaults to 0/0/medium when fields absent', () {
      final eta = OrderEta.fromJson({});

      expect(eta.minMinutes, equals(0));
      expect(eta.maxMinutes, equals(0));
      expect(eta.confidence, equals('medium'));
      expect(eta.note, isNull);
    });
  });

  group('OrderEta.derivedFromStatus', () {
    final now = DateTime.now();

    test('pending status yields high confidence', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.pending, createdAt: now);
      expect(eta.confidence, equals('high'));
      expect(eta.minMinutes, greaterThanOrEqualTo(0));
      expect(eta.maxMinutes, greaterThanOrEqualTo(eta.minMinutes));
    });

    test('accepted status yields high confidence', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.accepted, createdAt: now);
      expect(eta.confidence, equals('high'));
    });

    test('preparing status yields medium confidence', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.preparing, createdAt: now);
      expect(eta.confidence, equals('medium'));
    });

    test('ready status yields high confidence with short window', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.ready, createdAt: now);
      expect(eta.confidence, equals('high'));
      expect(eta.maxMinutes, lessThanOrEqualTo(6));
    });

    test('completed status yields 0/0 with high confidence', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.completed, createdAt: now);
      expect(eta.confidence, equals('high'));
      expect(eta.minMinutes, equals(0));
      expect(eta.maxMinutes, equals(0));
    });

    test('cancelled status yields low confidence', () {
      final eta = OrderEta.derivedFromStatus(status: OrderStatus.cancelled, createdAt: now);
      expect(eta.confidence, equals('low'));
      expect(eta.minMinutes, equals(0));
      expect(eta.maxMinutes, equals(0));
    });

    test('older orders have lower ETA than fresh orders for same status', () {
      final fresh = OrderEta.derivedFromStatus(status: OrderStatus.pending, createdAt: now);
      final old = OrderEta.derivedFromStatus(
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );
      // Rolling ETA decreases as order ages
      expect(old.maxMinutes, lessThanOrEqualTo(fresh.maxMinutes));
    });
  });
}
