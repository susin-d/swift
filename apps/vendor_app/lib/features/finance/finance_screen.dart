import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'finance_providers.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Finance & Payments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FinanceTile(
            title: 'Earnings Dashboard',
            subtitle: 'Daily revenue, net payout trend, and pending settlements.',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => context.push('/finance/earnings'),
          ),
          _FinanceTile(
            title: 'Payouts / Settlements',
            subtitle: 'Upcoming payouts, settled amounts, and cycle status.',
            icon: Icons.payments_rounded,
            onTap: () => context.push('/finance/payouts'),
          ),
          _FinanceTile(
            title: 'Transactions History',
            subtitle: 'Order-level transaction ledger with payment references.',
            icon: Icons.receipt_long_rounded,
            onTap: () => context.push('/finance/transactions'),
          ),
          _FinanceTile(
            title: 'Tax / GST Reports',
            subtitle: 'Tax summary and period-wise GST filing support exports.',
            icon: Icons.request_page_rounded,
            onTap: () => context.push('/finance/tax-reports'),
          ),
        ],
      ),
    );
  }
}

class FinanceEarningsScreen extends ConsumerWidget {
  const FinanceEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(financeEarningsProvider);
    return _FinanceDetailScaffold(
      title: 'Earnings Dashboard',
      subtitle: 'Revenue trends and net earnings snapshot.',
      child: earningsAsync.when(
        data: (data) => _MapSummaryList(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load earnings: $e')),
      ),
    );
  }
}

class FinancePayoutsScreen extends ConsumerWidget {
  const FinancePayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(financePayoutsProvider);
    return _FinanceDetailScaffold(
      title: 'Payouts / Settlements',
      subtitle: 'Payout cycle and settlement reconciliation.',
      child: payoutsAsync.when(
        data: (rows) => _ListSummary(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load payouts: $e')),
      ),
    );
  }
}

class FinanceTransactionsScreen extends ConsumerWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(financeTransactionsProvider);
    return _FinanceDetailScaffold(
      title: 'Transactions History',
      subtitle: 'Order-level payment and refund trail.',
      child: txAsync.when(
        data: (rows) => _ListSummary(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load transactions: $e')),
      ),
    );
  }
}

class FinanceTaxReportsScreen extends ConsumerWidget {
  const FinanceTaxReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(financeTaxReportsProvider);
    return _FinanceDetailScaffold(
      title: 'Tax / GST Reports',
      subtitle: 'Tax liability and filing support exports.',
      child: taxAsync.when(
        data: (data) => _MapSummaryList(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load tax report: $e')),
      ),
    );
  }
}

class _FinanceDetailScaffold extends StatelessWidget {
  const _FinanceDetailScaffold({
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

class _MapSummaryList extends StatelessWidget {
  const _MapSummaryList({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('No data available.');
    }
    return Column(
      children: data.entries
          .map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text('${entry.value}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No records found.');
    }

    return Column(
      children: rows
          .map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text((row as Map).entries.first.value.toString()),
                subtitle: Text(
                  (row.entries
                          .skip(1)
                          .map((e) => '${e.key}: ${e.value}')
                          .take(3)
                          .join(' | '))
                      .toString(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
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
