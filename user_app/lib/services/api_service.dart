import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_exception.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();
  final Map<String, CancelToken> _inFlightRequests = {};

  static const int _maxGetRetries = 2;
  static const int _baseRetryDelayMs = 300;
  static const String _authRetryKey = 'authRetryAttempted';

  static const String baseUrl = 'https://swift-campus.vercel.app/api/v1';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _resolveAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final statusCode = e.response?.statusCode ?? 0;
        final isExpectedRecommendationsFallback =
            statusCode == 404 && path == '/public/recommendations';
        final isExpectedRecommendationsServerFallback =
            statusCode == 500 && path == '/public/recommendations';
        final isExpectedOrdersFallback =
            statusCode == 500 && path == '/orders/me';

        if (isExpectedRecommendationsFallback) {
          _logger.w('FALLBACK[404] => PATH: $path');
        } else if (isExpectedRecommendationsServerFallback) {
          _logger.w('FALLBACK[500] => PATH: $path');
        } else if (isExpectedOrdersFallback) {
          _logger.w('FALLBACK[500] => PATH: $path');
        } else {
          _logger.e('ERROR[$statusCode] => PATH: $path');
        }

        final requestOptions = e.requestOptions;
        final alreadyRetried = requestOptions.extra[_authRetryKey] == true;

        if (statusCode == 401 && !alreadyRetried) {
          final refreshedToken = await _refreshAndPersistAccessToken();
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
            requestOptions.extra[_authRetryKey] = true;

            try {
              final retryResponse = await _dio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
        }

        return handler.next(e);
      },
    ));
  }

  Future<String?> _resolveAccessToken() async {
    final sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (sessionToken != null && sessionToken.isNotEmpty) {
      return sessionToken;
    }

    final persisted = await _storage.read(key: 'jwt');
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }

    return null;
  }

  Future<String?> _refreshAndPersistAccessToken() async {
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      final newToken = response.session?.accessToken;
      if (newToken != null && newToken.isNotEmpty) {
        await _storage.write(key: 'jwt', value: newToken);
        return newToken;
      }
    } catch (_) {
      // Keep original 401 behavior when refresh is unavailable.
    }
    return null;
  }

  ApiException _mapError(DioException e, String fallbackMessage) {
    final statusCode = e.response?.statusCode ?? 500;
    final data = e.response?.data;

    String? message;
    if (data is Map) {
      final payload = data.cast<dynamic, dynamic>();
      final envelopeMessage = payload['message'];
      final envelopeError = payload['error'];
      if (envelopeMessage is String && envelopeMessage.trim().isNotEmpty) {
        message = envelopeMessage;
      } else if (envelopeError is String && envelopeError.trim().isNotEmpty) {
        message = envelopeError;
      }
    }

    return ApiException(
      message: message ?? e.message ?? fallbackMessage,
      statusCode: statusCode,
    );
  }

  bool _isRetryable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = e.response?.statusCode ?? 0;
    return statusCode >= 500 && statusCode < 600;
  }

  CancelToken? _prepareCancelToken(String? cancelKey) {
    if (cancelKey == null || cancelKey.isEmpty) {
      return null;
    }

    _inFlightRequests[cancelKey]?.cancel('Superseded by a newer request');
    final token = CancelToken();
    _inFlightRequests[cancelKey] = token;
    return token;
  }

  void _releaseCancelToken(String? cancelKey, CancelToken? token) {
    if (cancelKey == null || cancelKey.isEmpty || token == null) {
      return;
    }

    if (identical(_inFlightRequests[cancelKey], token)) {
      _inFlightRequests.remove(cancelKey);
    }
  }

  void cancelRequest(String cancelKey, {String reason = 'Request cancelled'}) {
    final token = _inFlightRequests.remove(cancelKey);
    token?.cancel(reason);
  }

  void cancelAllRequests({String reason = 'All requests cancelled'}) {
    for (final token in _inFlightRequests.values) {
      token.cancel(reason);
    }
    _inFlightRequests.clear();
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelKey,
  }) async {
    final cancelToken = _prepareCancelToken(cancelKey);
    var attempt = 0;

    try {
      while (true) {
        try {
          return await _dio.get(
            path,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            rethrow;
          }

          if (attempt >= _maxGetRetries || !_isRetryable(e)) {
            throw _mapError(e, 'Failed to fetch data');
          }

          attempt += 1;
          await Future.delayed(Duration(milliseconds: _baseRetryDelayMs * attempt));
        }
      }
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to fetch data');
    } finally {
      _releaseCancelToken(cancelKey, cancelToken);
    }
  }

  Future<Response> post(String path, {dynamic data, String? cancelKey}) async {
    final cancelToken = _prepareCancelToken(cancelKey);
    try {
      return await _dio.post(path, data: data, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to submit request');
    } finally {
      _releaseCancelToken(cancelKey, cancelToken);
    }
  }

  Future<Response> patch(String path, {dynamic data, String? cancelKey}) async {
    final cancelToken = _prepareCancelToken(cancelKey);
    try {
      return await _dio.patch(path, data: data, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update data');
    } finally {
      _releaseCancelToken(cancelKey, cancelToken);
    }
  }

  Future<Response> delete(String path, {dynamic data, String? cancelKey}) async {
    final cancelToken = _prepareCancelToken(cancelKey);
    try {
      return await _dio.delete(path, data: data, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to delete data');
    } finally {
      _releaseCancelToken(cancelKey, cancelToken);
    }
  }
}
