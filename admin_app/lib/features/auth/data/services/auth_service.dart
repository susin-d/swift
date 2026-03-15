import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/admin_session.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'admin_token';

  Dio get _dio => ApiClient.instance.dio;

  Future<AdminSession> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final session = AdminSession.fromJson(response.data!);

      if (!session.isAdmin) {
        throw const ApiException(
          message: 'Access denied. Admin role required.',
          statusCode: 403,
        );
      }

      await _storage.write(key: _tokenKey, value: session.token);
      return session;
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Login failed',
      );
    }
  }

  Future<AdminSession?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data!;
      final user = data['user'] as Map<String, dynamic>;
      final role = user['role'] as String? ?? 'user';
      if (role != 'admin') return null;

      return AdminSession(
        token: token,
        userId: (user['id'] as String?) ?? '',
        email: (user['email'] as String?) ?? '',
        role: role,
      );
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}
