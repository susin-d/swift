import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final name = user?.userMetadata?['name'] ?? 'Campus Student';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'CS';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authNotifierProvider.notifier).signOut();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Profile Header with initials avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(name, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 48),

            // Menu Items
            _buildProfileItem(context, 'Order History', Icons.history_rounded, () => context.push('/order-history')),
            _buildProfileItem(context, 'Saved Addresses', Icons.location_on_rounded, () => context.push('/addresses')),
            _buildProfileItem(context, 'Favorites', Icons.favorite_rounded, () => context.push('/favorites')),
            _buildProfileItem(context, 'Class Schedule', Icons.school_rounded, () => context.push('/profile/classes')),
            _buildProfileItem(context, 'Edit Profile', Icons.edit_rounded, () => context.push('/profile/edit')),
            _buildProfileItem(context, 'Help & Support', Icons.help_outline_rounded, () => context.push('/support')),
            _buildProfileItem(context, 'Terms of Service', Icons.gavel_rounded, () => context.push('/legal')),
            _buildProfileItem(context, 'Privacy Policy', Icons.privacy_tip_rounded, () => context.push('/privacy')),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
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
