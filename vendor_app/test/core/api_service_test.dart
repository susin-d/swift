import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor_app/core/api_exception.dart';
import 'package:vendor_app/core/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService', () {
    test('retries retryable GET failures and eventually succeeds', () async {
      final service = ApiService();
      var attempts = 0;

      service.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            attempts += 1;
            if (attempts < 3) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionTimeout,
                  message: 'timeout',
                ),
              );
              return;
            }

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      final response = await service.get('/health');

      expect(response.statusCode, 200);
      expect(response.data['ok'], true);
      expect(attempts, 3);
    });

    test('maps non-retryable response into ApiException with envelope message', () async {
      final service = ApiService();

      service.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 422,
                  data: {'message': 'Validation failed'},
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        service.get('/orders'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Validation failed'),
        ),
      );
    });

    test('cancels an in-flight GET when a newer request uses the same cancelKey', () async {
      final service = ApiService();
      var requestCount = 0;

      service.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            requestCount += 1;

            if (requestCount == 1) {
              await Future<void>.delayed(const Duration(milliseconds: 80));
              if (options.cancelToken?.isCancelled ?? false) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.cancel,
                    message: 'cancelled by newer request',
                  ),
                );
                return;
              }
            }

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'request': requestCount},
              ),
            );
          },
        ),
      );

        final first = service
          .get('/orders', cancelKey: 'orders-list')
          .then<dynamic>((value) => value)
          .catchError((Object error) => error);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await service.get('/orders', cancelKey: 'orders-list');

      expect(second.statusCode, 200);
      expect(second.data['request'], 2);

      final firstResult = await first;
      expect(
        firstResult,
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('cancelled'),
        ),
      );
    });
  });
}
