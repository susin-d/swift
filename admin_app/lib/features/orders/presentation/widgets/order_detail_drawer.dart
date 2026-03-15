import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_order.dart';

class OrderDetailDrawer extends StatelessWidget {
  const OrderDetailDrawer({
    super.key,
    required this.order,
    required this.onCancel,
  });

  final AdminOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt == null
        ? 'N/A'
        : DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order details', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              _KeyVal(label: 'Status', value: order.status.toUpperCase()),
              _KeyVal(label: 'Vendor', value: order.vendorName),
              _KeyVal(label: 'Customer', value: '${order.userName} (${order.userEmail})'),
              _KeyVal(label: 'Placed at', value: date),
              _KeyVal(label: 'Items', value: '${order.itemCount}'),
              _KeyVal(label: 'Total', value: _currency(order.totalAmount)),
              const Spacer(),
              if (order.status != 'cancelled' && order.status != 'completed')
                FilledButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
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
