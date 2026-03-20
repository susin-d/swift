import '../models/notification_model.dart';
import 'api_exception.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _api.get('/notifications');
      final data = response.data as List? ?? [];
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode >= 500) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> registerDeviceToken(String token, {String platform = 'unknown'}) async {
    await _api.post('/notifications/device', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> removeDeviceToken(String token) async {
    await _api.delete('/notifications/device', data: {
      'token': token,
    });
  }
}
