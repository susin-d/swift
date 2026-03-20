import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref.watch(notificationServiceProvider).getNotifications();
});
