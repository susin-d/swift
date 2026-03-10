import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStream = ref.watch(orderTrackingProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: orderStream.when(
        data: (order) => _buildTrackingContent(context, order),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error tracking order: $e')),
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Giant Status Icon
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(order.status),
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 48),
          
          Text(
            _getStatusTitle(order.status),
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDescription(order.status),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Stepper-like visualization
          _buildStatusStep(context, 'Order Placed', 'We have received your order.', order.status.index >= 0),
          _buildStatusStep(context, 'Preparing', 'The kitchen is working on your meal.', order.status.index >= 2),
          _buildStatusStep(context, 'Ready for Pickup', 'Your meal is hot and ready!', order.status.index >= 3),
          _buildStatusStep(context, 'Completed', 'Enjoy your meal!', order.status.index >= 4),
          
          const SizedBox(height: 60),
          
          // Order Details Card
          Container(
            padding: const EdgeInsets.all(24),
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
                    const Text('Order ID', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text('#${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text('₹${order.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(BuildContext context, String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.timer_outlined;
      case OrderStatus.accepted: return Icons.thumb_up_alt_rounded;
      case OrderStatus.preparing: return Icons.restaurant_rounded;
      case OrderStatus.ready: return Icons.shopping_bag_rounded;
      case OrderStatus.completed: return Icons.check_circle_rounded;
      case OrderStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Awaiting Confirmation';
      case OrderStatus.accepted: return 'Order Confirmed';
      case OrderStatus.preparing: return 'Kitchen is Sizzling';
      case OrderStatus.ready: return 'Ready for Pickup!';
      case OrderStatus.completed: return 'Order Completed';
      case OrderStatus.cancelled: return 'Order Cancelled';
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'The vendor will accept your order shortly.';
      case OrderStatus.accepted: return 'Your order has been accepted and is in queue.';
      case OrderStatus.preparing: return 'Chef is preparing your delicious meal.';
      case OrderStatus.ready: return 'Head over to the counter to collect your food.';
      case OrderStatus.completed: return 'Thank you for ordering with Swift!';
      case OrderStatus.cancelled: return 'Your order was cancelled. Refund processed if applicable.';
    }
  }
}
