import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/loading_widget.dart';
import '../../core/router/app_router.dart';

class VendorMenuScreen extends ConsumerWidget {
  final String vendorId;

  const VendorMenuScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(vendorMenuProvider(vendorId));
    final vendorsAsync = ref.watch(vendorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Glassmorphic Vendor Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: vendorsAsync.when(
                data: (vendors) {
                  final vendor = vendors.firstWhere((v) => v.id == vendorId);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: vendor.imageUrl ?? 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 32,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.name,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  vendor.rating.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time_filled, color: Colors.white70, size: 18),
                                const SizedBox(width: 4),
                                const Text(
                                  '15-25 mins',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Container(color: Colors.grey[200]),
                error: (e, _) => Container(color: Colors.grey[200]),
              ),
            ),
          ),

          // Menu Section Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Text(
                'Full Menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
            ),
          ),

          // Menu Grid
          menuAsync.when(
            data: (items) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return MenuItemCard(
                      item: item,
                      onAdd: () {
                        ref.read(cartProvider.notifier).addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart'),
                            margin: const EdgeInsets.all(24),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(child: LoadingWidget()),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: _buildCartFab(ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCartFab(WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => ref.read(routerProvider).push('/cart'),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    '${cart.length} ITEMS',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  Text(
                    '₹${ref.read(cartProvider.notifier).totalAmount.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'VIEW CART',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
