import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Profile Header
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200'),
            ),
            const SizedBox(height: 24),
            Text(
              user?.userMetadata?['name'] ?? 'Campus student',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            
            // Wallet Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Campus Wallet Balance',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹1,240.00',
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('TOP UP'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Menu Items
            _buildProfileItem(context, 'Order History', Icons.history_rounded, () => context.push('/order-history')),
            _buildProfileItem(context, 'Favorite Vendors', Icons.favorite_rounded, () {}),
            _buildProfileItem(context, 'Address Settings', Icons.location_on_rounded, () {}),
            _buildProfileItem(context, 'Payment Methods', Icons.credit_card_rounded, () {}),
            _buildProfileItem(context, 'Help & Support', Icons.help_outline_rounded, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(color: AppColors.border),
      ],
    );
  }
}
