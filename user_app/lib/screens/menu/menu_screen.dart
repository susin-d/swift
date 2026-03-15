import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../core/utils/app_animations.dart';
import '../../core/router/app_router.dart';

enum _MenuSort { recommended, priceLowToHigh }

class VendorMenuScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorMenuScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends ConsumerState<VendorMenuScreen> {
  String _selectedCategory = 'All';
  bool _availableOnly = false;
  _MenuSort _sort = _MenuSort.recommended;

  List<MenuItemModel> _applyDecisionFilters(List<MenuItemModel> items) {
    var filtered = items.where((item) {
      final categoryMatch = _selectedCategory == 'All' || (item.category ?? 'Uncategorized') == _selectedCategory;
      final availabilityMatch = !_availableOnly || item.isAvailable;
      return categoryMatch && availabilityMatch;
    }).toList();

    if (_sort == _MenuSort.priceLowToHigh) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(vendorMenuProvider(widget.vendorId));
    final vendorsAsync = ref.watch(vendorsProvider);
    final cart = ref.watch(cartProvider);

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
                  final vendor = vendors.firstWhere((v) => v.id == widget.vendorId);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'vendor_${vendor.id}',
                        child: CachedNetworkImage(
                          imageUrl: vendor.imageUrl ?? 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
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
              padding: EdgeInsets.fromLTRB(24, 32, 24, 14),
              child: Text(
                'Full Menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
            ),
          ),

          menuAsync.when(
            data: (items) {
              final categories = <String>{'All', ...items.map((e) => e.category ?? 'Uncategorized')}.toList();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = category == _selectedCategory;
                            return _DecisionChip(
                              label: category,
                              selected: selected,
                              onTap: () => setState(() => _selectedCategory = category),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _DecisionChip(
                            label: _availableOnly ? 'Available only' : 'All availability',
                            selected: _availableOnly,
                            onTap: () => setState(() => _availableOnly = !_availableOnly),
                          ),
                          const SizedBox(width: 8),
                          _DecisionChip(
                            label: _sort == _MenuSort.recommended ? 'Sort: Recommended' : 'Sort: Price low-high',
                            selected: _sort == _MenuSort.priceLowToHigh,
                            onTap: () {
                              setState(() {
                                _sort = _sort == _MenuSort.recommended
                                    ? _MenuSort.priceLowToHigh
                                    : _MenuSort.recommended;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Menu Grid
          menuAsync.when(
            data: (items) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final filtered = _applyDecisionFilters(items);
                    if (filtered.isEmpty) {
                      return const _NoMenuMatchCard();
                    }

                    final item = filtered[index];
                    final quantityInCart = cart[item.id]?.quantity ?? 0;
                    return AppAnimations.staggeredList(
                      index,
                      MenuItemCard(
                        item: item,
                        quantityInCart: quantityInCart,
                        onIncrement: () {
                          ref.read(cartProvider.notifier).addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} updated in cart'),
                              margin: const EdgeInsets.all(24),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onDecrement: () => ref.read(cartProvider.notifier).removeItem(item),
                      ),
                    );
                  },
                  childCount: (() {
                    final filtered = _applyDecisionFilters(items);
                    return filtered.isEmpty ? 1 : filtered.length;
                  })(),
                ),
              ),
            ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const MenuItemShimmer(),
                  childCount: 6,
                ),
              ),
            ),
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
                color: AppColors.primary.withValues(alpha: 0.4),
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

class _DecisionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DecisionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _NoMenuMatchCard extends StatelessWidget {
  const _NoMenuMatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.filter_alt_off_rounded, color: AppColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No items match these filters. Try another category or availability option.',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
