import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_content.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_widget.dart';

const String notificationsEmptyActionLabel = 'Explore menu';
const String notificationsErrorActionLabel = 'Retry';
const String notificationsCardSemanticPrefix = 'Notification';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveContent(
        child: notificationsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => _NotificationsErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return _EmptyNotifications(onExplore: () => context.go('/'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationCard(
                  item: item,
                  onTap: () async {
                    await ref
                        .read(notificationServiceProvider)
                        .markRead(item.id);
                    ref.invalidate(notificationsProvider);
                    final orderId = item.metadata?['order_id']?.toString();
                    if (orderId != null &&
                        orderId.isNotEmpty &&
                        context.mounted) {
                      context.push('/order-status/$orderId');
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticStatus = item.isRead ? 'Read' : 'Unread';
    final semanticTime = DateFormat('MMM dd, hh:mm a').format(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Semantics(
        button: true,
        label:
            '$notificationsCardSemanticPrefix. $semanticStatus. ${item.title}. $semanticTime',
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    semanticTime,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text('Order updates will appear here as they happen.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onExplore,
            child: const Text(notificationsEmptyActionLabel),
          ),
        ],
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load notifications',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text(notificationsErrorActionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
