import '../../core/api_service.dart';
import 'notification_model.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<AppNotification>> getNotifications() async {
    final response = await _api.get('/notifications');
    final data = response.data as List? ?? [];
    return data.map((json) => AppNotification.fromJson(json)).toList();
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
}
