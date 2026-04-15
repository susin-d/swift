import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/customer_shell.dart';
import '../../core/widgets/responsive_content.dart';
import '../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final name = user?['user_metadata']?['name'] ?? 'Campus Student';
    final email = user != null ? user['email'] : '';
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((word) => word.isNotEmpty ? word[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'CS';
    final walletBalanceRaw =
        user?['wallet_balance'] ?? user?['walletBalance'] ?? 0;
    final walletBalance = walletBalanceRaw is num
        ? walletBalanceRaw.toDouble()
        : double.tryParse(walletBalanceRaw.toString()) ?? 0;

    return CustomerShell(
      selectedIndex: 3,
      title: 'Profile',
      subtitle: 'Account, saved places, growth, and support.',
      actions: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              HapticFeedback.mediumImpact();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text(
                    'Sign Out',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                  ),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authNotifierProvider.notifier).signOut();
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ),
      ],
      body: ResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        initials,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Wallet Balance',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildProfileItem(
                      context,
                      'Order History',
                      Icons.history_rounded,
                      () => context.push('/order-history'),
                    ),
                    _buildProfileItem(
                      context,
                      'Saved Addresses',
                      Icons.location_on_rounded,
                      () => context.push('/addresses'),
                    ),
                    _buildProfileItem(
                      context,
                      'Favorites',
                      Icons.favorite_rounded,
                      () => context.push('/favorites'),
                    ),
                    _buildProfileItem(
                      context,
                      'Class Schedule',
                      Icons.school_rounded,
                      () => context.push('/profile/classes'),
                    ),
                    _buildProfileItem(
                      context,
                      'Edit Profile',
                      Icons.edit_rounded,
                      () => context.push('/profile/edit'),
                    ),
                    _buildProfileItem(
                      context,
                      'Growth Hub',
                      Icons.trending_up_rounded,
                      () => context.push('/growth'),
                    ),
                    _buildProfileItem(
                      context,
                      'Help & Support',
                      Icons.help_outline_rounded,
                      () => context.push('/support'),
                    ),
                    _buildProfileItem(
                      context,
                      'Terms of Service',
                      Icons.gavel_rounded,
                      () => context.push('/legal'),
                    ),
                    _buildProfileItem(
                      context,
                      'Privacy Policy',
                      Icons.privacy_tip_rounded,
                      () => context.push('/privacy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(color: AppColors.divider),
      ],
    );
  }
}
