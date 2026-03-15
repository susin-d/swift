import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/admin_user.dart';

class UsersResponse {
  const UsersResponse({required this.users, required this.page, required this.limit, required this.total});

  final List<AdminUser> users;
  final int page;
  final int limit;
  final int total;
}

class UsersService {
  UsersService._();
  static final UsersService instance = UsersService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<UsersResponse> fetchUsers({required int page, required int limit}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/users', queryParameters: {
        'page': page,
        'limit': limit,
      });

      final data = response.data ?? const <String, dynamic>{};
      final usersJson = (data['users'] as List?) ?? const [];

      return UsersResponse(
        users: usersJson
            .map((e) => AdminUser.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
        total: (data['total'] as num?)?.toInt() ?? usersJson.length,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load users',
      );
    }
  }

  Future<void> setBlocked(String userId, bool blocked, {String? reason}) async {
    try {
      await _dio.patch('/admin/users/$userId/block', data: {
        'blocked': blocked,
        if (reason != null) 'reason': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update block status',
      );
    }
  }

  Future<void> updateRole(String userId, String role) async {
    try {
      await _dio.patch('/admin/users/$userId/role', data: {'role': role});
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update role',
      );
    }
  }
}
