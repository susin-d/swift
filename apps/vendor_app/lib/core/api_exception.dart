class ApiException implements Exception {
  const ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
