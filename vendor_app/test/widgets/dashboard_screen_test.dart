import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/dashboard/dashboard_screen.dart';

class _DashboardFakeApiService extends ApiService {
  _DashboardFakeApiService({
    required List<Map<String, dynamic>> initialOrders,
    this.failPatch = false,
  }) : _orders = initialOrders
           .map((order) => Map<String, dynamic>.from(order))
           .toList();

  final List<Map<String, dynamic>> _orders;
  final List<Map<String, dynamic>> patchCalls = [];
  bool failPatch;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelKey,
  }) async {
    return Response<dynamic>(
      data: _orders.map((order) => Map<String, dynamic>.from(order)).toList(),
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    String? cancelKey,
  }) async {
    patchCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});

    if (failPatch) {
      throw Exception('Patch failed');
    }

    final status = (data as Map<String, dynamic>)['status'] as String;
    final orderId = path.split('/')[2];
    final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex] = {..._orders[orderIndex], 'status': status};
    }

    return Response<dynamic>(
      data: {'status': status},
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

Map<String, dynamic> _order({
  required String id,
  required String status,
  num totalAmount = 100,
  String slaRisk = 'low',
  int elapsedMinutes = 4,
  int recommendedPrepMinutes = 12,
}) {
  return {
    'id': id,
    'status': status,
    'total_amount': totalAmount,
    'created_at': '2026-03-17T10:00:00.000Z',
    'pacing': {
      'sla_risk': slaRisk,
      'elapsed_minutes': elapsedMinutes,
      'recommended_prep_minutes': recommendedPrepMinutes,
    },
  };
}

Future<void> _pumpDashboard(WidgetTester tester, ApiService apiService) async {
  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(apiService)],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'updates order status from popup menu and shows success feedback',
    (tester) async {
      final api = _DashboardFakeApiService(
        initialOrders: [_order(id: 'ord-12345678', status: 'accepted')],
      );

      await _pumpDashboard(tester, api);

      expect(find.textContaining('ACCEPTED'), findsOneWidget);

      await tester.ensureVisible(find.text('Update').first);
      await tester.tap(find.text('Update').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('PREPARING').last);
      await tester.pumpAndSettle();

      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/orders/ord-12345678/status');
      expect(api.patchCalls.first['data'], {'status': 'preparing'});
      expect(find.text('Order updated to PREPARING'), findsOneWidget);
      expect(find.textContaining('PREPARING - Rs 100'), findsOneWidget);
    },
  );

  testWidgets('shows failure feedback when 86 hold confirmation patch fails', (
    tester,
  ) async {
    final api = _DashboardFakeApiService(
      initialOrders: [
        _order(
          id: 'ord-87654321',
          status: 'accepted',
          slaRisk: 'high',
          elapsedMinutes: 18,
          recommendedPrepMinutes: 10,
        ),
      ],
      failPatch: true,
    );

    await _pumpDashboard(tester, api);

    await tester.ensureVisible(find.text('Order #ORD-8765'));
    await tester.drag(find.byType(Dismissible).first, const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm 86 Hold'), findsOneWidget);

    await tester.tap(find.text('Confirm 86'));
    await tester.pumpAndSettle();

    expect(api.patchCalls, hasLength(1));
    expect(api.patchCalls.first['data'], {'status': 'cancelled'});
    expect(find.text('Failed to move order to 86 HOLD'), findsOneWidget);
  });
}
