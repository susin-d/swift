import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/finance_summary.dart';
import '../../data/services/finance_service.dart';
import '../providers/finance_provider.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeProvider);

    return financeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FinanceError(
        message: error.toString(),
        onRetry: () => ref.read(financeProvider.notifier).refresh(),
      ),
      data: (snapshot) => RefreshIndicator(
        onRefresh: () => ref.read(financeProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _FinanceHero(snapshot: snapshot),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _StatCard(label: 'Today', value: _currency(snapshot.summary.todayRevenue)),
                    _StatCard(label: 'This Week', value: _currency(snapshot.summary.weekRevenue)),
                    _StatCard(label: 'This Month', value: _currency(snapshot.summary.monthRevenue)),
                    _StatCard(label: 'Total', value: _currency(snapshot.summary.totalRevenue)),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _ChartPanel(points: snapshot.chart),
            const SizedBox(height: 16),
            _PayoutHealthPanel(items: snapshot.payouts),
            const SizedBox(height: 16),
            _PayoutPanel(items: snapshot.payouts),
          ],
        ),
      ),
    );
  }
}

class _FinanceHero extends StatelessWidget {
  const _FinanceHero({required this.snapshot});

  final FinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final pendingPayouts = snapshot.payouts.where((item) => item.status.toLowerCase() != 'paid').length;
    final topVendor = snapshot.payouts.isEmpty
        ? null
        : (snapshot.payouts.toList()..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue))).first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF102A2A), Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finance visibility',
                  style: TextStyle(color: Color(0xFFDDF7F2), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Today is tracking ${_currency(snapshot.summary.todayRevenue)} with $pendingPayouts payout items still needing attention.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (topVendor != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top vendor this window', style: TextStyle(color: Color(0xFFDDF7F2))),
                  const SizedBox(height: 8),
                  Text(
                    topVendor.vendorName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currency(topVendor.totalRevenue)} across ${topVendor.totalOrders} orders',
                    style: const TextStyle(color: Color(0xFFDDF7F2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.points});

  final List<FinanceChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('7-day trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (points.isEmpty)
              Text('No chart data available.', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...points.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: Text(p.day, style: Theme.of(context).textTheme.bodyMedium)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: points.isEmpty ? 0 : (p.revenue / _maxRevenue(points)).clamp(0, 1),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: Text('${_currency(p.revenue)} • ${p.orders} orders', textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  double _maxRevenue(List<FinanceChartPoint> points) {
    final max = points.fold<double>(0, (prev, point) => point.revenue > prev ? point.revenue : prev);
    return max <= 0 ? 1 : max;
  }
}

class _PayoutHealthPanel extends StatelessWidget {
  const _PayoutHealthPanel({required this.items});

  final List<PayoutItem> items;

  @override
  Widget build(BuildContext context) {
    final pending = items.where((item) => item.status.toLowerCase() == 'pending').length;
    final processing = items.where((item) => item.status.toLowerCase() == 'processing').length;
    final paid = items.where((item) => item.status.toLowerCase() == 'paid').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payout health', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PayoutStatusTile(label: 'Pending', value: '$pending', background: const Color(0xFFFFF7E8), foreground: const Color(0xFF9A6200)),
                _PayoutStatusTile(label: 'Processing', value: '$processing', background: const Color(0xFFE0F2FE), foreground: const Color(0xFF1D4ED8)),
                _PayoutStatusTile(label: 'Paid', value: '$paid', background: const Color(0xFFE9F7F3), foreground: const Color(0xFF0F766E)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutStatusTile extends StatelessWidget {
  const _PayoutStatusTile({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 24)),
        ],
      ),
    );
  }
}

class _PayoutPanel extends StatelessWidget {
  const _PayoutPanel({required this.items});

  final List<PayoutItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor payouts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text('No payouts available.', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.vendorName, style: Theme.of(context).textTheme.titleMedium),
                              Text('${item.totalOrders} orders', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF9A6200), fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_currency(item.totalRevenue)),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV export placeholder. Endpoint will be wired in next sprint.')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceError extends StatelessWidget {
  const _FinanceError({required this.message, required this.onRetry});

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
                Text('Failed to load finance data', style: Theme.of(context).textTheme.titleLarge),
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
