import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_content.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/review_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/order_status_widget.dart';

const String orderHistoryEmptyActionLabel = 'Start ordering';
const String orderHistoryErrorActionLabel = 'Retry';
const String orderHistoryCardSemanticPrefix = 'Order card';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order History'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveContent(
        child: ordersAsync.when(
          data: (orders) => orders.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                ),
          loading: () => const LoadingWidget(),
          error: (e, _) => _buildErrorState(
            e.toString(),
            () => ref.invalidate(userOrdersProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'No orders yet',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order history will appear here\nonce you place your first meal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text(orderHistoryEmptyActionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 58,
              color: AppColors.error.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load order history',
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
              child: const Text(orderHistoryErrorActionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final vendorName = order.vendorName ?? 'Campus Vendor';
    final placedAt = DateFormat('MMM dd, hh:mm a').format(order.createdAt);
    final orderTotal = order.totalAmount.toInt();

    return Semantics(
      container: true,
      label:
          '$orderHistoryCardSemanticPrefix. $vendorName. ${order.status.name}. Rs $orderTotal. Placed $placedAt',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vendorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                OrderStatusWidget(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  placedAt,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '\u20B9$orderTotal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (order.scheduledFor != null ||
                (order.promoCode?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.scheduledFor == null
                        ? 'ASAP'
                        : 'Scheduled: ${DateFormat('MMM dd, hh:mm a').format(order.scheduledFor!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (order.promoCode != null && order.promoCode!.isNotEmpty)
                    Text(
                      'Promo: ${order.promoCode}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/order-status/${order.id}'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('TRACK ORDER'),
                  ),
                ),
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openReviewSheet(context, order),
                      child: const Text('LEAVE REVIEW'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewSheet(BuildContext context, OrderModel order) async {
    final ratingController = ValueNotifier<int>(5);
    final commentController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate your order',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: ratingController,
                builder: (_, rating, _) => Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: 'Rate $value star${value > 1 ? 's' : ''}',
                      onPressed: () => ratingController.value = value,
                      icon: Icon(
                        value <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Share feedback (optional)',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('SUBMIT REVIEW'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (submitted != true) return;

    try {
      await ReviewService().submitReview(
        orderId: order.id,
        rating: ratingController.value,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanks for the review!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
