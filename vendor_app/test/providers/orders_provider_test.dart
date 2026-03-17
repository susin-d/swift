import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/orders/orders_provider.dart';

class _FakeApiService extends ApiService {
  final Future<Response<dynamic>> Function(String path)? getHandler;
  final Future<Response<dynamic>> Function(String path, dynamic data)? patchHandler;
  final List<Map<String, dynamic>> patchCalls = [];

  _FakeApiService({this.getHandler, this.patchHandler});

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelKey,
  }) async {
    return getHandler!(path);
  }

  @override
  Future<Response<dynamic>> patch(String path, {dynamic data, String? cancelKey}) async {
    patchCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});
    return patchHandler!(path, data);
  }
}

Response<dynamic> _jsonResponse(dynamic data, {int statusCode = 200}) => Response<dynamic>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: '/'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('OrdersNotifier — fetchOrders', () {
    test('transitions to data state on successful fetch', () async {
      final orders = [
        {'id': 'ord-1', 'status': 'pending', 'total_amount': 100},
        {'id': 'ord-2', 'status': 'accepted', 'total_amount': 200},
      ];

      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          _FakeApiService(getHandler: (_) async => _jsonResponse(orders)),
        ),
      ]);
      addTearDown(container.dispose);

      // Await explicit fetchOrders so we synchronize on completion
      await container.read(ordersProvider.notifier).fetchOrders();
      final state = container.read(ordersProvider);
      expect(state.value, isNotNull);
      expect(state.value!.length, equals(2));
      expect(state.value![0]['id'], equals('ord-1'));
    });

    test('transitions to loading then data state in sequence', () async {
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          _FakeApiService(
            getHandler: (_) async => _jsonResponse([{'id': 'ord-1'}]),
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(ordersProvider.notifier).fetchOrders();
      expect(container.read(ordersProvider).value, isNotNull);
    });

    test('transitions to error state on non-200 status', () async {
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          _FakeApiService(
            getHandler: (_) async => _jsonResponse({'error': 'Unauthorized'}, statusCode: 401),
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(ordersProvider.notifier).fetchOrders();
      final state = container.read(ordersProvider);
      expect(state.hasError, isTrue);
    });

    test('transitions to error state on thrown exception', () async {
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          _FakeApiService(
            getHandler: (_) async => throw Exception('Network error'),
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(ordersProvider.notifier).fetchOrders();
      final state = container.read(ordersProvider);
      expect(state.hasError, isTrue);
    });

    test('returns empty list when API returns empty array', () async {
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          _FakeApiService(getHandler: (_) async => _jsonResponse([])),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(ordersProvider.notifier).fetchOrders();
      expect(container.read(ordersProvider).value, isEmpty);
    });
  });

  group('OrdersNotifier — updateStatus', () {
    test('calls patch and then re-fetches orders', () async {
      int fetchCount = 0;

      final api = _FakeApiService(
        getHandler: (_) async {
          fetchCount++;
          return _jsonResponse([{'id': 'ord-1', 'status': 'preparing'}]);
        },
        patchHandler: (_, __) async => _jsonResponse({'status': 'preparing'}),
      );

      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(
          api,
        ),
      ]);
      addTearDown(container.dispose);

      // Initial fetch from constructor
      await container.read(ordersProvider.notifier).fetchOrders();
      final countAfterInit = fetchCount;

      // updateStatus calls fetchOrders internally (fire-and-forget)
      final didUpdate = await container.read(ordersProvider.notifier).updateStatus('ord-1', 'preparing');

      expect(didUpdate, isTrue);
      expect(fetchCount, greaterThan(countAfterInit));
      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/orders/ord-1/status');
      expect(api.patchCalls.first['data'], {'status': 'preparing'});
      expect(container.read(ordersProvider).value, isNotNull);
      expect(container.read(ordersProvider).value!.first['status'], 'preparing');
    });

    test('sets error state and returns false when status update fails', () async {
      final api = _FakeApiService(
        getHandler: (_) async => _jsonResponse([
          {'id': 'ord-1', 'status': 'accepted'}
        ]),
        patchHandler: (_, __) async => throw Exception('Patch failed'),
      );

      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(api),
      ]);
      addTearDown(container.dispose);

      await container.read(ordersProvider.notifier).fetchOrders();

      final didUpdate = await container.read(ordersProvider.notifier).updateStatus('ord-1', 'preparing');
      final state = container.read(ordersProvider);

      expect(didUpdate, isFalse);
      expect(api.patchCalls, hasLength(1));
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Patch failed'));
    });
  });
}
