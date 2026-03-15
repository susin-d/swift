import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';

class FakeApiService extends ApiService {
  FakeApiService({this.getHandler, this.postHandler});

  final Future<Response> Function(String path)? getHandler;
  final Future<Response> Function(String path, dynamic data)? postHandler;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelKey,
  }) async {
    return getHandler!(path);
  }

  @override
  Future<Response> post(String path, {dynamic data, String? cancelKey}) async {
    return postHandler!(path, data);
  }
}

Response<dynamic> jsonResponse(dynamic data, {int statusCode = 200}) {
  return Response<dynamic>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: '/'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login rejects non-vendor roles and does not persist token', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          FakeApiService(
            postHandler: (path, data) async => jsonResponse({
              'user': {'role': 'user'},
              'session': {'access_token': 'token-123'}
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.login('user@campus.edu', 'password123');

    final state = container.read(authProvider);
    final prefs = await SharedPreferences.getInstance();

    expect(state.isAuthenticated, isFalse);
    expect(state.error, 'Access denied. Vendor role required.');
    expect(prefs.getString('auth_token'), isNull);
  });

  test('restore clears stored token when auth/me resolves to a non-vendor role', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'token-123'});

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          FakeApiService(
            getHandler: (path) async => jsonResponse({
              'user': {'role': 'admin'}
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(authProvider);
    final prefs = await SharedPreferences.getInstance();

    expect(state.isAuthenticated, isFalse);
    expect(state.error, 'Access denied. Vendor role required.');
    expect(prefs.getString('auth_token'), isNull);
  });
}