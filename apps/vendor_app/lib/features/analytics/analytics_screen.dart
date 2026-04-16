import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'analytics_providers.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnalyticsTile(
            title: 'Sales Analytics',
            subtitle: 'Revenue trends by day/week/month and order-size curves.',
            icon: Icons.query_stats_rounded,
            onTap: () => context.push('/analytics/sales'),
          ),
          _AnalyticsTile(
            title: 'Performance Metrics',
            subtitle: 'SLA adherence, prep-time performance, and fulfillment score.',
            icon: Icons.insights_rounded,
            onTap: () => context.push('/analytics/performance'),
          ),
          _AnalyticsTile(
            title: 'Peak Hours Insights',
            subtitle: 'Rush windows and staffing recommendations from order flow.',
            icon: Icons.schedule_rounded,
            onTap: () => context.push('/analytics/peak-hours'),
          ),
          _AnalyticsTile(
            title: 'Top-Selling Items',
            subtitle: 'Best-performing menu items by volume and margin.',
            icon: Icons.local_fire_department_rounded,
            onTap: () => context.push('/analytics/top-items'),
          ),
        ],
      ),
    );
  }
}

class SalesAnalyticsScreen extends ConsumerWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(analyticsSalesProvider);
    return _AnalyticsDetailScaffold(
      title: 'Sales Analytics',
      subtitle: 'Revenue and conversion trends.',
      child: salesAsync.when(
        data: (rows) => _RowsList(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load sales analytics: $e')),
      ),
    );
  }
}

class PerformanceMetricsScreen extends ConsumerWidget {
  const PerformanceMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(analyticsPerformanceProvider);
    return _AnalyticsDetailScaffold(
      title: 'Performance Metrics',
      subtitle: 'Kitchen and fulfillment quality metrics.',
      child: perfAsync.when(
        data: (data) => _MapRowsList(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load performance metrics: $e')),
      ),
    );
  }
}

class PeakHoursInsightsScreen extends ConsumerWidget {
  const PeakHoursInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peakAsync = ref.watch(analyticsPeakHoursProvider);
    return _AnalyticsDetailScaffold(
      title: 'Peak Hours Insights',
      subtitle: 'Rush pattern and workload windows.',
      child: peakAsync.when(
        data: (rows) => _RowsList(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load peak hour insights: $e')),
      ),
    );
  }
}

class TopSellingItemsScreen extends ConsumerWidget {
  const TopSellingItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(analyticsTopItemsProvider);
    return _AnalyticsDetailScaffold(
      title: 'Top-Selling Items',
      subtitle: 'Item velocity and profitability leaders.',
      child: topAsync.when(
        data: (rows) => _RowsList(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load top items: $e')),
      ),
    );
  }
}

class _AnalyticsDetailScaffold extends StatelessWidget {
  const _AnalyticsDetailScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MapRowsList extends StatelessWidget {
  const _MapRowsList({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Text('No metrics found.');
    return Column(
      children: data.entries
          .map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.show_chart_rounded),
                title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text('${entry.value}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RowsList extends StatelessWidget {
  const _RowsList({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No records found.');
    return Column(
      children: rows
          .map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: Text((row as Map).entries.first.value.toString()),
                subtitle: Text(row.entries.map((e) => '${e.key}: ${e.value}').take(3).join(' | ')),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  const _AnalyticsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal.shade600),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
