import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/vendor_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final vendorsAsync = ref.watch(vendorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load favorites: $e')),
        data: (vendors) {
          final items = vendors.where((v) => favorites.contains(v.id)).toList();
          if (items.isEmpty) {
            return const _EmptyFavorites();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final vendor = items[index];
              return VendorCard(
                vendor: vendor,
                onTap: () => context.push('/vendor/${vendor.id}'),
                isFavorite: true,
                onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggle(vendor.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            const Text('No favorites yet', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Tap the heart on a vendor to save them here.'),
          ],
        ),
      ),
    );
  }
}
