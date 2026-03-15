import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  factory ApiException.fromDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    final statusCode = error.response?.statusCode ?? 500;
    final data = error.response?.data;

    String? message;
    if (data is Map) {
      final map = data.cast<dynamic, dynamic>();
      final envelopeMessage = map['message'];
      final envelopeError = map['error'];
      if (envelopeMessage is String && envelopeMessage.trim().isNotEmpty) {
        message = envelopeMessage;
      } else if (envelopeError is String && envelopeError.trim().isNotEmpty) {
        message = envelopeError;
      }
    }

    return ApiException(
      message: message ?? error.message ?? fallbackMessage,
      statusCode: statusCode,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
