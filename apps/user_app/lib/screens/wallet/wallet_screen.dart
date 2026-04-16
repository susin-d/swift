import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/customer_shell.dart';
import '../../core/widgets/responsive_content.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final balanceRaw = user?['wallet_balance'] ?? user?['walletBalance'] ?? 480;
    final balance = balanceRaw is num
        ? balanceRaw.toDouble()
        : double.tryParse(balanceRaw.toString()) ?? 480;

    return CustomerShell(
      selectedIndex: 3,
      destinations: CustomerShell.primaryDestinations,
      title: 'Wallet',
      subtitle: 'Balance, rewards, and recent money flow.',
      actions: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            tooltip: 'Wallet history',
            onPressed: () => context.push('/order-history'),
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          ),
        ),
      ],
      body: ResponsiveContent(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userOrdersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E8B6A), Color(0xFF0B6B59)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _memberLabel(user),
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionPill(
                              label: '+ Top up',
                              icon: Icons.add_rounded,
                              onTap: () => _showWalletSnack(context, 'Top up is not linked yet.'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionPill(
                              label: 'Send',
                              icon: Icons.send_rounded,
                              onTap: () => _showWalletSnack(context, 'Send money is coming soon.'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionPill(
                              label: 'History',
                              icon: Icons.history_rounded,
                              onTap: () => context.push('/order-history'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<OrderModel>>(
                  future: ref.read(userOrdersProvider.future),
                  builder: (context, snapshot) {
                    final orders = snapshot.data ?? const <OrderModel>[];
                    final spent = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
                    final cashback = (spent * 0.05) + (orders.length * 8);
                    return Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            title: 'Spent this month',
                            value: '₹${spent.toStringAsFixed(0)}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            title: 'Cashback earned',
                            value: '₹${cashback.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'TRANSACTIONS',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF077A63),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ordersAsync.when(
                  data: (orders) => _TransactionList(orders: orders),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )),
                  error: (_, _) => _TransactionList(orders: const []),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _memberLabel(Map<String, dynamic>? user) {
    final name = user?['user_metadata']?['name']?.toString() ?? 'Swift Wallet';
    return '$name · Silver member';
  }

  void _showWalletSnack(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD9ECE7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8DD0C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF086B5C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF05473D),
              fontSize: 27,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final transactions = <_WalletTransaction>[
      ...orders.take(4).map((order) => _WalletTransaction(
            title: 'Order #${_shortOrderId(order.id)}',
            subtitle: _dateLabel(order.createdAt),
            amount: -order.totalAmount,
            icon: Icons.restaurant_rounded,
          )),
      const _WalletTransaction(
        title: 'Wallet top-up',
        subtitle: 'Today · 10:00 am',
        amount: 200,
        icon: Icons.add_rounded,
      ),
      const _WalletTransaction(
        title: 'Referral bonus',
        subtitle: 'Yesterday',
        amount: 50,
        icon: Icons.card_giftcard_rounded,
      ),
    ];

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No wallet activity yet.'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8DD0C0)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < transactions.length; index++) ...[
            _TransactionRow(transaction: transactions[index]),
            if (index != transactions.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  String _dateLabel(DateTime createdAt) {
    final today = DateTime.now();
    final sameDay = createdAt.year == today.year &&
        createdAt.month == today.month &&
        createdAt.day == today.day;
    if (sameDay) {
      return 'Today · ${DateFormat('hh:mm a').format(createdAt)}';
    }
    return 'Yesterday · ${DateFormat('hh:mm a').format(createdAt)}';
  }

  String _shortOrderId(String id) {
    if (id.length <= 4) return id;
    return id.substring(0, 4);
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final _WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount >= 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(transaction.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}₹${transaction.amount.abs().toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: isCredit ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTransaction {
  const _WalletTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
}
