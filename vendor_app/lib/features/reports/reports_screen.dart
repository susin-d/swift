import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'reports_providers.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Reports', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportTile(
            title: 'Download Reports (PDF/CSV)',
            subtitle: 'Export order and settlement reports by date range.',
            icon: Icons.download_rounded,
            onTap: () => context.push('/reports/download'),
          ),
          _ReportTile(
            title: 'Sales Reports',
            subtitle: 'Revenue, AOV, and conversion snapshots.',
            icon: Icons.bar_chart_rounded,
            onTap: () => context.push('/reports/sales'),
          ),
          _ReportTile(
            title: 'Order Reports',
            subtitle: 'Volume, status mix, cancellations, and SLA adherence.',
            icon: Icons.summarize_rounded,
            onTap: () => context.push('/reports/orders'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/reports/download'),
            icon: const Icon(Icons.file_download_rounded),
            label: const Text('Open Download Center'),
          ),
        ],
      ),
    );
  }
}

class DownloadReportsScreen extends ConsumerWidget {
  const DownloadReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadAsync = ref.watch(reportsDownloadProvider);
    return _ReportsDetailScaffold(
      title: 'Download Reports (PDF/CSV)',
      child: downloadAsync.when(
        data: (data) {
          final csv = (data['csv'] ?? '').toString();
          final rowCount = csv.isEmpty ? 0 : csv.split('\n').length;
          return Column(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download_rounded),
                  title: Text('Format: ${(data['format'] ?? 'csv').toString().toUpperCase()}'),
                  subtitle: Text('CSV rows: $rowCount'),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: csv.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: csv));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV copied to clipboard.')),
                        );
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy CSV Export'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load export metadata: $e')),
      ),
    );
  }
}

class SalesReportsScreen extends ConsumerWidget {
  const SalesReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(reportsSalesProvider);
    return _ReportsDetailScaffold(
      title: 'Sales Reports',
      child: salesAsync.when(
        data: (rows) => _ReportRows(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load sales report: $e')),
      ),
    );
  }
}

class OrderReportsScreen extends ConsumerWidget {
  const OrderReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(reportsOrdersProvider);
    return _ReportsDetailScaffold(
      title: 'Order Reports',
      child: ordersAsync.when(
        data: (data) => _OrderStatusMap(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders report: $e')),
      ),
    );
  }
}

class _ReportsDetailScaffold extends StatelessWidget {
  const _ReportsDetailScaffold({required this.title, required this.child});

  final String title;
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
        children: [child],
      ),
    );
  }
}

class _ReportRows extends StatelessWidget {
  const _ReportRows({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No report rows found.');
    return Column(
      children: rows
          .map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.bar_chart_rounded),
                title: Text((row as Map).entries.first.value.toString()),
                subtitle: Text(row.entries.map((e) => '${e.key}: ${e.value}').take(3).join(' | ')),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OrderStatusMap extends StatelessWidget {
  const _OrderStatusMap({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Text('No order status data found.');
    return Column(
      children: data.entries
          .map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.summarize_rounded),
                title: Text(entry.key.toUpperCase()),
                subtitle: Text('Count: ${entry.value}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
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
