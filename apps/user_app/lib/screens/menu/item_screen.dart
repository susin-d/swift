import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_content.dart';
import '../../models/menu_model.dart';
import '../../models/search_result.dart';
import '../../providers/cart_provider.dart';

class ItemScreen extends ConsumerWidget {
  const ItemScreen({super.key, required this.item});

  final Object? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item is! SearchResult) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Item'),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const ResponsiveContent(
          child: Center(child: Text('Unable to load this item right now.')),
        ),
      );
    }

    final data = item as SearchResult;
    final vendor = data.vendor;
    final canAddToCart =
        data.id.trim().isNotEmpty && vendor?.id.trim().isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Item Details'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CachedNetworkImage(
                  imageUrl:
                      data.imageUrl ??
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1200',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                data.name,
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (vendor != null)
                Text(
                  vendor.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\u20B9${data.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                data.description?.trim().isNotEmpty == true
                    ? data.description!.trim()
                    : 'Freshly prepared and served by your campus favorite vendor.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Recommended',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 170,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Mock recommendations; replace with real data as needed
                      for (final rec in _mockRecommendations)
                        _RecommendationCard(item: rec),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Mock recommendations (replace with real data/provider as needed)
      final List<SearchResult> _mockRecommendations = [
        SearchResult(
          id: '1',
          name: 'Paneer Butter Masala',
          description: 'Creamy cottage cheese curry.',
          price: 120,
          imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=400',
          vendor: SearchVendor(id: 'v1', name: 'Annapoorna Bhavan'),
        ),
        SearchResult(
          id: '2',
          name: 'Veg Biryani',
          description: 'Aromatic rice with veggies.',
          price: 110,
          imageUrl: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?q=80&w=400',
          vendor: SearchVendor(id: 'v1', name: 'Annapoorna Bhavan'),
        ),
        SearchResult(
          id: '3',
          name: 'Gulab Jamun',
          description: 'Classic Indian dessert.',
          price: 60,
          imageUrl: 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?q=80&w=400',
          vendor: SearchVendor(id: 'v1', name: 'Annapoorna Bhavan'),
        ),
      ];

      class _RecommendationCard extends StatelessWidget {
        final SearchResult item;
        const _RecommendationCard({required this.item});

        @override
        Widget build(BuildContext context) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl ?? '',
                    height: 80,
                    width: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 80,
                      width: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\u20B9${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
      }
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SizedBox(
          height: 58,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            onPressed: canAddToCart
                ? () {
                    final cartItem = MenuItemModel(
                      id: data.id,
                      menuId: '',
                      vendorId: vendor!.id,
                      name: data.name,
                      description: data.description,
                      price: data.price,
                      imageUrl: data.imageUrl,
                      isAvailable: true,
                    );
                    ref.read(cartProvider.notifier).addItem(cartItem);
                    context.push('/cart');
                  }
                : null,
            child: const Text('Add to cart', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
