import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/promo.dart';
import '../providers/promos_provider.dart';

class PromosScreen extends ConsumerWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promosProvider);

    return promosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _PromosError(
        message: error.toString(),
        onRetry: () => ref.read(promosProvider.notifier).refresh(),
      ),
      data: (promos) => _PromosBody(promos: promos),
    );
  }
}

class _PromosBody extends ConsumerWidget {
  const _PromosBody({required this.promos});

  final List<Promo> promos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(promosProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Promotions', style: Theme.of(context).textTheme.titleLarge),
              FilledButton.icon(
                onPressed: () => _showCreatePromo(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create promo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (promos.isEmpty)
            const _EmptyState()
          else
            ...promos.map((promo) => _PromoCard(promo: promo)),
        ],
      ),
    );
  }

  Future<void> _showCreatePromo(BuildContext context, WidgetRef ref) async {
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final valueController = TextEditingController();
    final minController = TextEditingController(text: '0');
    final maxController = TextEditingController();
    final usageController = TextEditingController();
    var discountType = 'percent';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create promo'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: const InputDecoration(labelText: 'Discount type'),
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Percent')),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed amount'),
                    ),
                  ],
                  onChanged: (value) => discountType = value ?? 'percent',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount value',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Min order amount',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Max discount (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (result != true) return;

    final value = double.tryParse(valueController.text.trim());
    if (value == null) {
      _showSnack(context, 'Enter a valid discount value', isError: true);
      return;
    }

    final minOrderAmount = double.tryParse(minController.text.trim()) ?? 0;
    final maxDiscountAmount = maxController.text.trim().isEmpty
        ? null
        : double.tryParse(maxController.text.trim());
    final usageLimit = usageController.text.trim().isEmpty
        ? null
        : int.tryParse(usageController.text.trim());

    final error = await ref
        .read(promosProvider.notifier)
        .createPromo(
          code: codeController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          discountType: discountType,
          discountValue: value,
          minOrderAmount: minOrderAmount,
          maxDiscountAmount: maxDiscountAmount,
          usageLimit: usageLimit,
        );

    if (!context.mounted) return;
    _showSnack(context, error ?? 'Promo created');
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB91C1C) : null,
      ),
    );
  }
}

class _PromoCard extends ConsumerWidget {
  const _PromoCard({required this.promo});

  final Promo promo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    final discountLabel = promo.discountType == 'percent'
        ? '${promo.discountValue.toInt()}% off'
        : '${currency.format(promo.discountValue)} off';
    final windowLabel = _window(promo.startsAt, promo.endsAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          promo.code,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(discountLabel),
            if (promo.description != null && promo.description!.isNotEmpty)
              Text(
                promo.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (windowLabel != null)
              Text(windowLabel, style: Theme.of(context).textTheme.bodySmall),
            Text(
              'Usage ${promo.usageCount}${promo.usageLimit == null ? '' : ' / ${promo.usageLimit}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Switch(
          value: promo.isActive,
          onChanged: (value) async {
            final error = await ref
                .read(promosProvider.notifier)
                .toggleActive(promo, value);
            if (!context.mounted) return;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: const Color(0xFFB91C1C),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 36,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              'No promos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Create a promo code to boost conversions.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromosError extends StatelessWidget {
  const _PromosError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFB91C1C),
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load promos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _window(DateTime? start, DateTime? end) {
  if (start == null && end == null) return null;
  final fmt = DateFormat('dd MMM');
  final startLabel = start == null ? 'Now' : fmt.format(start);
  final endLabel = end == null ? 'No end' : fmt.format(end);
  return 'Window: $startLabel - $endLabel';
}
