import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_detail_drawer.dart';
import '../../../../shared/widgets/reason_capture_dialog.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _OrdersError(
        message: error.toString(),
        onRetry: () => ref.read(ordersProvider.notifier).refresh(),
      ),
      data: (state) => _OrdersBody(state: state),
    );
  }
}

class _OrdersBody extends ConsumerWidget {
  const _OrdersBody({required this.state});

  final OrdersState state;

  static const statuses = [
    'all',
    'pending',
    'accepted',
    'preparing',
    'ready',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .map((status) => FilterChip(
                      label: Text(_label(status)),
                      selected: state.filter == status,
                      onSelected: (_) => ref.read(ordersProvider.notifier).applyFilter(status),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (state.orders.isEmpty)
            const _OrdersEmpty()
          else ...[
            ...state.orders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderRow(order: order),
                )),
            if (state.hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(ordersProvider.notifier).loadMore(),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _label(String status) {
    if (status == 'all') return 'All';
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: order.status),
                  if (order.isDelayed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Delayed',
                        style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text('${order.vendorName} • ${order.userName}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                '${order.itemCount} items - ${_currency(order.totalAmount)} - ${_date(order.createdAt)} - ${_schedule(order.scheduledFor)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: OrderDetailDrawer(
            order: order,
            onCancel: () => _cancelOrder(sheetContext, ref),
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final reason = await ReasonCaptureDialog.show(
      context,
      title: 'Cancel order',
      actionLabel: 'Cancel order',
      warningText: 'Provide a reason for cancelling order ${order.id}. This will be logged.',
    );

    if (reason == null || !context.mounted) return;

    final error = await ref.read(ordersProvider.notifier).cancelOrder(order.id, reason: reason);
    if (!context.mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Order cancelled successfully.'),
        backgroundColor: error == null ? null : const Color(0xFFB91C1C),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'pending' => (const Color(0xFFFFF7E8), const Color(0xFF9A6200)),
      'accepted' => (const Color(0xFFE6F4F2), const Color(0xFF0F766E)),
      'preparing' => (const Color(0xFFEEF2FF), const Color(0xFF4338CA)),
      'ready' => (const Color(0xFFE7F8EE), const Color(0xFF166534)),
      'completed' => (const Color(0xFFE8F5FF), const Color(0xFF1D4ED8)),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 12),
                Text('No orders found', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'No orders match the selected filter right now.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 36),
                const SizedBox(height: 12),
                Text('Failed to load orders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _currency(double value) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 1);
  if (value >= 1000) {
    return '${formatter.format(value / 1000)}k';
  }
  return formatter.format(value);
}

String _date(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown time';
  return DateFormat('dd MMM, hh:mm a').format(dateTime);
}

String _schedule(DateTime? scheduledFor) {
  if (scheduledFor == null) return 'ASAP';
  return DateFormat('dd MMM, hh:mm a').format(scheduledFor);
}
