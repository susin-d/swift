import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'api_exception.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();
  final Map<String, CancelToken> _inFlightRequests = {};

  static const int _maxGetRetries = 2;
  static const int _baseRetryDelayMs = 300;

  static const String baseUrl = 'https://swift-tsbi.vercel.app/api/v1';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
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

  Future<Response> delete(String path, {String? cancelKey}) async {
    final cancelToken = _prepareCancelToken(cancelKey);
    try {
      return await _dio.delete(path, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to delete data');
    } finally {
      _releaseCancelToken(cancelKey, cancelToken);
    }
  }
}
