import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_location.dart';
import '../../providers/order_provider.dart';
import '../../providers/delivery_provider.dart';
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
        data: (order) => _buildTrackingContent(context, ref, order),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error tracking order: $e')),
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, WidgetRef ref, OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Giant Status Icon
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
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
          const SizedBox(height: 20),
          _buildEtaTrustCard(order),
          const SizedBox(height: 28),
          _buildLiveMapSection(context, ref, order),
          const SizedBox(height: 48),
          
          // Stepper-like visualization
          _buildStatusStep(context, 'Order Placed', 'We have received your order.', order.status.index >= 0),
          _buildStatusStep(context, 'Preparing', 'The kitchen is working on your meal.', order.status.index >= 2),
          _buildStatusStep(context, 'Ready for Pickup', 'Your meal is hot and ready!', order.status.index >= 3),
          _buildStatusStep(context, 'Completed', 'Enjoy your meal!', order.status.index >= 4),
          
          const SizedBox(height: 60),
          if (_canCancel(order))
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, ref, order),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
              ),
            ),
          if (_canCancel(order)) const SizedBox(height: 40),
          
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
                
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scheduled', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text(
                      order.scheduledFor == null
                          ? 'ASAP'
                          : '${order.scheduledFor!.toLocal()}'.split('.').first,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (order.deliveryMode == 'class') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Class delivery', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text(
                        '${order.deliveryBuildingName ?? 'Building'}${order.deliveryRoom == null ? '' : ' • ${order.deliveryRoom}'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (order.handoffCode != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Handoff code', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        Text(order.handoffCode!, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ],
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

  bool _canCancel(OrderModel order) {
    return order.status == OrderStatus.pending || order.status == OrderStatus.accepted;
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order'),
        content: const Text('Cancel this order before it reaches the kitchen?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep order')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel order')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(orderServiceProvider).cancelOrder(order.id);
      if (!context.mounted) return;
      ref.invalidate(userOrdersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildLiveMapSection(BuildContext context, WidgetRef ref, OrderModel order) {
    final locationAsync = ref.watch(deliveryLocationProvider(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Courier Tracking',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        locationAsync.when(
          data: (location) {
            if (location == null) {
              return _buildMapPlaceholder();
            }
            return _buildMapCard(location);
          },
          loading: () => _buildMapLoading(),
          error: (e, _) => _buildMapError(e),
        ),
      ],
    );
  }

  Widget _buildMapCard(DeliveryLocation location) {
    final point = LatLng(location.lat, location.lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.campusfood.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 46,
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatUpdatedAt(location.updatedAt),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.location_searching_rounded, size: 32, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Waiting for courier location',
            style: TextStyle(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Live tracking begins once delivery is in motion.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLoading() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(height: 12),
          Text(
            'Loading live courier location...',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMapError(Object error) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Unable to load courier location',
            style: TextStyle(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) {
      return 'Updated just now';
    }

    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) {
      return 'Updated just now';
    }
    if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return 'Updated ${diff.inHours} hr ago';
    }
    final days = diff.inDays;
    return 'Updated ${days}d ago';
  }

  Widget _buildEtaTrustCard(OrderModel order) {
    final eta = order.eta;
    final minMinutes = eta?.minMinutes ?? 0;
    final maxMinutes = eta?.maxMinutes ?? 0;
    final confidence = (eta?.confidence ?? 'medium').toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              minMinutes == 0 && maxMinutes == 0
                  ? 'ETA confidence $confidence • status settled'
                  : 'ETA $minMinutes-$maxMinutes min • confidence $confidence',
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
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
                    color: isDone ? AppColors.textSecondary : AppColors.textMuted.withValues(alpha: 0.5),
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
