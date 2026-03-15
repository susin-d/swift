import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  bool _seededDraft = false;

  @override
  void dispose() {
    _commissionController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _SettingsError(
        message: error.toString(),
        onRetry: () => ref.read(settingsProvider.notifier).refresh(),
      ),
      data: (settings) {
        if (!_seededDraft) {
          _commissionController.text = settings.commissionRate.toStringAsFixed(1);
          _deliveryController.text = settings.deliveryFee.toStringAsFixed(1);
          _seededDraft = true;
        }

        final commissionDraft = double.tryParse(_commissionController.text.trim());
        final deliveryDraft = double.tryParse(_deliveryController.text.trim());
        final hasDraftChanges = commissionDraft != null &&
            deliveryDraft != null &&
            (commissionDraft != settings.commissionRate || deliveryDraft != settings.deliveryFee);
        final risk = _changeRisk(
          commissionCurrent: settings.commissionRate,
          commissionDraft: commissionDraft,
          deliveryCurrent: settings.deliveryFee,
          deliveryDraft: deliveryDraft,
        );

        return ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform settings', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _commissionController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Commission rate (%)',
                        hintText: '12',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _deliveryController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Delivery fee',
                        hintText: '25',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsPreview(
                      current: settings,
                      commissionDraft: commissionDraft,
                      deliveryDraft: deliveryDraft,
                      risk: risk,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: hasDraftChanges ? () => _save(context) : null,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save settings'),
                        ),
                        OutlinedButton.icon(
                          onPressed: hasDraftChanges ? () => _resetDraft(settings) : null,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reset draft'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasDraftChanges
                          ? 'Draft changes are staged locally until you save. Review the preview before persisting.'
                          : 'Only super admin can persist settings changes.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save(BuildContext context) async {
    final commission = double.tryParse(_commissionController.text.trim());
    final delivery = double.tryParse(_deliveryController.text.trim());

    if (commission == null || delivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numeric values.')),
      );
      return;
    }

    final error = await ref.read(settingsProvider.notifier).save(commission, delivery);
    if (!context.mounted) return;

    if (error == null) {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Settings updated successfully.'),
        backgroundColor: error == null ? null : const Color(0xFFB91C1C),
      ),
    );
  }

  void _resetDraft(AdminSettings settings) {
    setState(() {
      _commissionController.text = settings.commissionRate.toStringAsFixed(1);
      _deliveryController.text = settings.deliveryFee.toStringAsFixed(1);
    });
  }
}

class _SettingsPreview extends StatelessWidget {
  const _SettingsPreview({
    required this.current,
    required this.commissionDraft,
    required this.deliveryDraft,
    required this.risk,
  });

  final AdminSettings current;
  final double? commissionDraft;
  final double? deliveryDraft;
  final ({String label, Color background, Color foreground}) risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Decision preview', style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: risk.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  risk.label,
                  style: TextStyle(color: risk.foreground, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PreviewRow(
            label: 'Commission rate',
            current: '${current.commissionRate.toStringAsFixed(1)}%',
            draft: commissionDraft == null ? 'Invalid draft' : '${commissionDraft!.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 10),
          _PreviewRow(
            label: 'Delivery fee',
            current: current.deliveryFee.toStringAsFixed(1),
            draft: deliveryDraft == null ? 'Invalid draft' : deliveryDraft!.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.current, required this.draft});

  final String label;
  final String current;
  final String draft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text('Current $current', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text('Draft $draft', style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message, required this.onRetry});

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
                Text('Failed to load settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
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

({String label, Color background, Color foreground}) _changeRisk({
  required double commissionCurrent,
  required double? commissionDraft,
  required double deliveryCurrent,
  required double? deliveryDraft,
}) {
  if (commissionDraft == null || deliveryDraft == null) {
    return (
      label: 'Invalid draft',
      background: const Color(0xFFFEE2E2),
      foreground: const Color(0xFFB91C1C),
    );
  }

  final commissionDelta = (commissionDraft - commissionCurrent).abs();
  final deliveryDelta = (deliveryDraft - deliveryCurrent).abs();
  if (commissionDelta >= 3 || deliveryDelta >= 10) {
    return (
      label: 'High impact',
      background: const Color(0xFFFEE2E2),
      foreground: const Color(0xFFB91C1C),
    );
  }
  if (commissionDelta >= 1 || deliveryDelta >= 4) {
    return (
      label: 'Review before save',
      background: const Color(0xFFFFF7E8),
      foreground: const Color(0xFF9A6200),
    );
  }
  return (
    label: 'Low impact',
    background: const Color(0xFFE9F7F3),
    foreground: const Color(0xFF0F766E),
  );
}
