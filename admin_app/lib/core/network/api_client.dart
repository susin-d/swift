import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

const _baseUrl = 'https://swift-campus.vercel.app/api/v1';

class ApiClient {
  static const int _maxRetries = 2;
  static const int _baseRetryDelayMs = 300;
  static const _deviceTrustKey = 'admin_device_trust_id';

  final Map<String, CancelToken> _inFlightGetRequests = {};
  final Random _random = Random();
  String? _deviceTrustId;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'admin_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        options.headers['X-Client-Request-Id'] = _buildClientRequestId();
        options.headers['X-Device-Trust'] = await _resolveDeviceTrustId(storage);

        // Dedupe in-flight GET calls to the same path+query to avoid stale work.
        if (options.method.toUpperCase() == 'GET') {
          final key = _requestKey(options);
          options.extra['requestKey'] = key;

          _inFlightGetRequests[key]?.cancel('Superseded by a newer request');

          final token = options.cancelToken ?? CancelToken();
          options.cancelToken = token;
          _inFlightGetRequests[key] = token;
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        final requestKey = response.requestOptions.extra['requestKey'];
        if (requestKey is String && requestKey.isNotEmpty) {
          _inFlightGetRequests.remove(requestKey);
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final requestOptions = error.requestOptions;
        final requestKey = requestOptions.extra['requestKey'];
        if (requestKey is String && requestKey.isNotEmpty) {
          _inFlightGetRequests.remove(requestKey);
        }

        final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;
        final shouldRetry = _isRetryable(error) && retryCount < _maxRetries;

        if (!shouldRetry || CancelToken.isCancel(error)) {
          handler.next(error);
          return;
        }

        requestOptions.extra['retryCount'] = retryCount + 1;
        final delayMs = _baseRetryDelayMs * (retryCount + 1);

        Future<void>.delayed(Duration(milliseconds: delayMs)).then((_) async {
          try {
            final response = await _dio.fetch(requestOptions);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          } catch (retryError) {
            handler.next(
              DioException(
                requestOptions: requestOptions,
                error: retryError,
                type: DioExceptionType.unknown,
              ),
            );
          }
        });
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  bool _isRetryable(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = error.response?.statusCode ?? 0;
    return statusCode >= 500 && statusCode < 600;
  }

  String _requestKey(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = options.path;
    final query = options.queryParameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return '$method:$path?$query';
  }

  String _buildClientRequestId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 20).toRadixString(36);
    return 'adm-$now-$salt';
  }

  Future<String> _resolveDeviceTrustId(FlutterSecureStorage storage) async {
    if (_deviceTrustId != null && _deviceTrustId!.isNotEmpty) {
      return _deviceTrustId!;
    }

    final existing = await storage.read(key: _deviceTrustKey);
    if (existing != null && existing.isNotEmpty) {
      _deviceTrustId = existing;
      return existing;
    }

    final created = 'dev-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(1 << 24).toRadixString(36)}';
    await storage.write(key: _deviceTrustKey, value: created);
    _deviceTrustId = created;
    return created;
  }

  Dio get dio => _dio;
}
