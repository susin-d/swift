import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_model.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationServiceProvider).getNotifications();
});
