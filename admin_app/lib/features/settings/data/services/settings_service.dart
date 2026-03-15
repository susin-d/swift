import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/admin_settings.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<AdminSettings> fetchSettings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/settings');
      final settings = response.data?['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      return AdminSettings.fromJson(settings);
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load settings',
      );
    }
  }

  Future<AdminSettings> updateSettings(AdminSettings settings) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/admin/settings', data: settings.toJson());
      final payload = response.data?['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      return AdminSettings.fromJson(payload);
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update settings',
      );
    }
  }
}
