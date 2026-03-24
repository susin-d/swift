import 'package:admin_app/features/orders/data/models/admin_order.dart';
import 'package:admin_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:admin_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOrdersNotifier extends OrdersNotifier {
  final _allOrders = <AdminOrder>[
    AdminOrder(
      id: 'order-12345678',
      status: 'pending',
      totalAmount: 320.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 70)),
      updatedAt: null,
      vendorName: 'Campus Bites',
      userName: 'Alice',
      userEmail: 'alice@example.com',
      itemCount: 2,
      discountAmount: 0,
      promoCode: null,
      scheduledFor: null,
      deliveryMode: null,
      deliveryBuildingName: null,
      deliveryRoom: null,
      quietMode: false,
      handoffCode: null,
      handoffStatus: null,
    ),
    AdminOrder(
      id: 'order-87654321',
      status: 'completed',
      totalAmount: 210.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: null,
      vendorName: 'Juice Corner',
      userName: 'Bob',
      userEmail: 'bob@example.com',
      itemCount: 1,
      discountAmount: 0,
      promoCode: null,
      scheduledFor: null,
      deliveryMode: null,
      deliveryBuildingName: null,
      deliveryRoom: null,
      quietMode: false,
      handoffCode: null,
      handoffStatus: null,
    ),
  ];

  static String? lastFilter;
  static String? cancelledOrderId;
  static String? cancelledReason;

  @override
  Future<OrdersState> build() async {
    return OrdersState(
      orders: _allOrders,
      page: 1,
      limit: 20,
      total: _allOrders.length,
      filter: 'all',
    );
  }

  @override
  Future<void> applyFilter(String filter) async {
    lastFilter = filter;
    final filtered = filter == 'all'
        ? _allOrders
        : _allOrders.where((o) => o.status == filter).toList();

    state = AsyncData(
      OrdersState(
        orders: filtered,
        page: 1,
        limit: 20,
        total: filtered.length,
        filter: filter,
      ),
    );
  }

  @override
  Future<String?> cancelOrder(String orderId, {required String reason}) async {
    cancelledOrderId = orderId;
    cancelledReason = reason;
    return null;
  }
}

void main() {
  testWidgets('OrdersScreen filter chips update list via notifier', (
    tester,
  ) async {
    _FakeOrdersNotifier.lastFilter = null;
    _FakeOrdersNotifier.cancelledOrderId = null;
    _FakeOrdersNotifier.cancelledReason = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersProvider.overrideWith(_FakeOrdersNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: OrdersScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Order order-12'), findsOneWidget);
    expect(find.textContaining('Order order-87'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await tester.pumpAndSettle();

    expect(_FakeOrdersNotifier.lastFilter, 'completed');
    expect(find.textContaining('Order order-87'), findsOneWidget);
    expect(find.textContaining('Order order-12'), findsNothing);
  });

  testWidgets('OrdersScreen shows delayed badge for aged active order', (
    tester,
  ) async {
    _FakeOrdersNotifier.lastFilter = null;
    _FakeOrdersNotifier.cancelledOrderId = null;
    _FakeOrdersNotifier.cancelledReason = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersProvider.overrideWith(_FakeOrdersNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: OrdersScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Delayed'), findsOneWidget);
  });

  testWidgets('OrdersScreen opens details drawer and cancels with reason', (
    tester,
  ) async {
    _FakeOrdersNotifier.lastFilter = null;
    _FakeOrdersNotifier.cancelledOrderId = null;
    _FakeOrdersNotifier.cancelledReason = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersProvider.overrideWith(_FakeOrdersNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: OrdersScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Campus Bites • Alice').first);
    await tester.pumpAndSettle();

    expect(find.text('Order details'), findsOneWidget);

    await tester.tap(find.text('Cancel order').first);
    await tester.pumpAndSettle();

    expect(find.text('Cancel order'), findsWidgets);

    await tester.enterText(
      find.byType(TextField).first,
      'Kitchen issue and stock shortage for this order.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Cancel order').last);
    await tester.pumpAndSettle();

    expect(_FakeOrdersNotifier.cancelledOrderId, 'order-12345678');
    expect(_FakeOrdersNotifier.cancelledReason, isNotNull);
    expect(_FakeOrdersNotifier.cancelledReason!, contains('stock shortage'));
    expect(find.text('Order details'), findsNothing);
    expect(find.textContaining('cancelled successfully'), findsOneWidget);
  });
}
