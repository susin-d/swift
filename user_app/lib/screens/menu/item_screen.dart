import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Unable to load this item right now.'),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CachedNetworkImage(
                imageUrl: data.imageUrl ??
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          ],
        ),
      ),
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
