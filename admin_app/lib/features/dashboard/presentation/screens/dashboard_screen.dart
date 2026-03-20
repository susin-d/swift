import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models/dashboard_snapshot.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardBody();
  }
}

// Exported so GoRouter can embed it directly in the shell.
class DashboardBody extends ConsumerWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const _DashboardLoading(),
      error: (error, _) => _DashboardError(
        message: error.toString(),
        onRetry: () => ref.invalidate(dashboardSnapshotProvider),
      ),
      data: (snapshot) => _DashboardContent(snapshot: snapshot),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1180;
        final cardCount = constraints.maxWidth > 1300
            ? 4
            : constraints.maxWidth > 820
                ? 2
                : 1;

        final revenueDelta = _percentChange(snapshot.todayRevenue, snapshot.yesterdayRevenue);
        final orderDelta = _percentChange(snapshot.todayOrders.toDouble(), snapshot.yesterdayOrders.toDouble());
        final vendorDelta = snapshot.pendingVendorCount == 0 ? '+0' : '+${snapshot.pendingVendorCount} pending';

        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(snapshot: snapshot),
                const SizedBox(height: 20),
                _QuickActionsRail(pendingVendorCount: snapshot.pendingVendorCount),
                const SizedBox(height: 20),
                _GovernanceDeckPanel(snapshot: snapshot),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: cardCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 820 ? 1.45 : 1.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      label: 'Users',
                      value: _compactNumber(snapshot.summary.totalUsers),
                      delta: _deltaLabel(0),
                      hint: 'Registered platform users',
                      icon: Icons.group_rounded,
                      accent: const Color(0xFF0F766E),
                    ),
                    _StatCard(
                      label: 'Vendors',
                      value: _compactNumber(snapshot.summary.totalVendors),
                      delta: vendorDelta,
                      hint: '${snapshot.pendingVendorCount} waiting approval',
                      icon: Icons.storefront_rounded,
                      accent: const Color(0xFFB45309),
                      isWarning: snapshot.pendingVendorCount > 0,
                    ),
                    _StatCard(
                      label: 'Active Orders',
                      value: _compactNumber(snapshot.summary.activeOrders),
                      delta: _deltaLabel(orderDelta),
                      hint: 'Based on last 7 day trend',
                      icon: Icons.receipt_long_rounded,
                      accent: const Color(0xFF7C3AED),
                      isNegative: orderDelta < 0,
                    ),
                    _StatCard(
                      label: 'Revenue',
                      value: _currency(snapshot.summary.revenue),
                      delta: _deltaLabel(revenueDelta),
                      hint: 'Completed orders total',
                      icon: Icons.payments_rounded,
                      accent: const Color(0xFF2563EB),
                      isNegative: revenueDelta < 0,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _OperationsPanel(snapshot: snapshot)),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _WatchlistPanel(snapshot: snapshot)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _OperationsPanel(snapshot: snapshot),
                      const SizedBox(height: 16),
                      _WatchlistPanel(snapshot: snapshot),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsRail extends StatelessWidget {
  const _QuickActionsRail({required this.pendingVendorCount});

  final int pendingVendorCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/vendors'),
              icon: const Icon(Icons.storefront_rounded),
              label: Text('Review Vendors ($pendingVendorCount)'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Escalation Queue'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings_suggest_rounded),
              label: const Text('Policy Controls'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/audit'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Audit Timeline'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/finance'),
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: const Text('Finance Watch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernanceDeckPanel extends StatelessWidget {
  const _GovernanceDeckPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GovernanceCardData(
        title: 'Vendor decisions',
        value: '${snapshot.pendingVendorCount}',
        subtitle: 'Applications waiting for approval or rejection.',
        route: '/vendors',
        icon: Icons.verified_user_rounded,
        accent: const Color(0xFFB45309),
      ),
      _GovernanceCardData(
        title: 'Escalation queue',
        value: '${snapshot.criticalQueue}',
        subtitle: 'Critical orders and operational follow-ups.',
        route: '/orders',
        icon: Icons.crisis_alert_rounded,
        accent: const Color(0xFFB91C1C),
      ),
      _GovernanceCardData(
        title: 'Policy review',
        value: '${snapshot.summary.totalUsers}',
        subtitle: 'Settings changes affect every active admin workflow.',
        route: '/settings',
        icon: Icons.rule_folder_rounded,
        accent: const Color(0xFF1D4ED8),
      ),
      _GovernanceCardData(
        title: 'Payout watch',
        value: _currency(snapshot.summary.revenue),
        subtitle: 'Use finance visibility to spot pending payout risk.',
        route: '/finance',
        icon: Icons.currency_rupee_rounded,
        accent: const Color(0xFF0F766E),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Governance Command Deck', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Fast routes for the highest-cost admin decisions this shift.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7F3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Sprint 7',
                    style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: 270,
                      child: _GovernanceCommandCard(card: card),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernanceCommandCard extends StatelessWidget {
  const _GovernanceCommandCard({required this.card});

  final _GovernanceCardData card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(card.route),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: card.accent.withValues(alpha: 0.16)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: card.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(card.icon, color: card.accent),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 16),
            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              card.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(card.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _GovernanceCardData {
  const _GovernanceCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color accent;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingForNow();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143A39), Color(0xFF0F766E), Color(0xFF15927F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        spacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 540,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live operations summary',
                  style: TextStyle(
                    color: Color(0xFFDDF7F2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$greeting. Today: ${snapshot.todayOrders} orders and ${_currency(snapshot.todayRevenue)} revenue. Keep an eye on pending vendor approvals.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Critical queue', style: TextStyle(color: Color(0xFFDDF7F2))),
                const SizedBox(height: 10),
                Text(
                  '${snapshot.criticalQueue} items',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${snapshot.pendingVendorCount} vendor approvals + active order watch',
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
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.hint,
    required this.icon,
    required this.accent,
    this.isNegative = false,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final String delta;
  final String hint;
  final IconData icon;
  final Color accent;
  final bool isNegative;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final deltaBg = isNegative
        ? const Color(0xFFFEE2E2)
        : isWarning
            ? const Color(0xFFFFF6E8)
            : const Color(0xFFE9F7F3);
    final deltaColor = isNegative
        ? const Color(0xFFB91C1C)
        : isWarning
            ? const Color(0xFF9A6200)
            : const Color(0xFF0F766E);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: deltaBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                delta,
                style: TextStyle(color: deltaColor, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final revenueTrend = _percentChange(snapshot.todayRevenue, snapshot.yesterdayRevenue);
    final orderTrend = _percentChange(snapshot.todayOrders.toDouble(), snapshot.yesterdayOrders.toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations Pulse', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Live chart and queue data from admin endpoints.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _TimelineItem(
              title: 'Revenue trend today',
              subtitle: '${_deltaLabel(revenueTrend)} compared with yesterday (${_currency(snapshot.yesterdayRevenue)} baseline).',
              badge: revenueTrend < 0 ? 'Down' : 'Up',
              badgeColor: revenueTrend < 0 ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
            ),
            _TimelineItem(
              title: 'Order flow',
              subtitle: '${snapshot.todayOrders} orders today, ${_deltaLabel(orderTrend)} vs previous day.',
              badge: snapshot.todayOrders > 0 ? 'Live' : 'Idle',
              badgeColor: const Color(0xFF1D4ED8),
            ),
            _TimelineItem(
              title: 'Vendor approval queue',
              subtitle: '${snapshot.pendingVendorCount} vendors currently waiting for admin decision.',
              badge: snapshot.pendingVendorCount > 0 ? 'Action' : 'Clear',
              badgeColor: snapshot.pendingVendorCount > 0 ? const Color(0xFFB45309) : const Color(0xFF0F766E),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistPanel extends StatelessWidget {
  const _WatchlistPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Watchlist', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            _WatchlistRow(
              title: 'Pending vendor approvals',
              value: '${snapshot.pendingVendorCount}',
              footnote: 'Review vendor profiles and approve or reject quickly.',
            ),
            const Divider(height: 28),
            _WatchlistRow(
              title: 'Completed orders',
              value: _compactNumber(snapshot.summary.completedOrders),
              footnote: 'Useful for refund-rate and SLA trend comparisons.',
            ),
            const Divider(height: 28),
            _WatchlistRow(
              title: 'Total revenue',
              value: _currency(snapshot.summary.revenue),
              footnote: 'Synced from /admin/dashboard/summary endpoint.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.title,
    required this.value,
    required this.footnote,
  });

  final String title;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(footnote, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF10201F),
              ),
        ),
      ],
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _LoadingBlock(height: 180, radius: 30),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: const [
                _LoadingBlock(height: 140, radius: 24),
                _LoadingBlock(height: 140, radius: 24),
                _LoadingBlock(height: 140, radius: 24),
                _LoadingBlock(height: 140, radius: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

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
                Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleLarge),
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

String _compactNumber(int value) {
  final formatter = NumberFormat.compact(locale: 'en_IN');
  return formatter.format(value);
}

String _currency(double value) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 1);
  if (value >= 1000) {
    final compact = formatter.format(value / 1000).replaceAll('Rs ', 'Rs ');
    return '${compact}k';
  }
  return formatter.format(value);
}

double _percentChange(double current, double previous) {
  if (previous == 0) {
    return current == 0 ? 0 : 100;
  }
  return ((current - previous) / previous) * 100;
}

String _deltaLabel(double percent) {
  final sign = percent >= 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(1)}%';
}

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
