import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/recommended_item.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../core/utils/app_animations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedMood = 'All';
  bool _isReordering = false;

  static const List<_MoodChip> _moodChips = [
    _MoodChip(label: 'All', icon: Icons.restaurant_rounded, keywords: []),
    _MoodChip(label: 'Comfort', icon: Icons.ramen_dining_rounded, keywords: ['north', 'indian', 'meal', 'comfort']),
    _MoodChip(label: 'Quick', icon: Icons.flash_on_rounded, keywords: ['quick', 'snack', 'fast']),
    _MoodChip(label: 'Sweet', icon: Icons.icecream_rounded, keywords: ['dessert', 'sweet', 'bakery']),
    _MoodChip(label: 'Light', icon: Icons.eco_rounded, keywords: ['healthy', 'salad', 'light']),
  ];

  bool _matchesMood(RecommendedItem item, _MoodChip mood) {
    if (mood.label == 'All') return true;

    final category = (item.category ?? '').toLowerCase();
    final name = item.name.toLowerCase();
    final description = (item.description ?? '').toLowerCase();
    final vendorName = (item.vendor?.name ?? '').toLowerCase();
    final combined = '$category $name $description $vendorName';

    return mood.keywords.any((keyword) => combined.contains(keyword));
  }

  OrderModel? _latestOrder(List<OrderModel> orders) {
    if (orders.isEmpty) return null;
    final sorted = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  Future<void> _quickRepeatOrder(OrderModel? order) async {
    if (order == null || order.items.isEmpty || _isReordering) return;

    setState(() => _isReordering = true);
    try {
      final placed = await ref.read(orderServiceProvider).placeOrder(
        vendorId: order.vendorId,
        items: order.items.map((item) {
          return {
            'menu_item_id': item.menuItemId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          };
        }).toList(),
        totalAmount: order.totalAmount,
      );

      if (!mounted) return;
      ref.invalidate(userOrdersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repeat order placed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.push('/order-status/${placed.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick reorder failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendedItemsAsync = ref.watch(recommendedItemsProvider);
    final userOrdersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recommendedItemsProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Vibrant Hero Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 40),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Swift Delivery',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Campus Kitchens',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                onPressed: () => context.push('/notifications'),
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Search Bar Placeholder
                        GestureDetector(
                          onTap: () => context.push('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Search for a vendor or dish...',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EtaConfidenceBand(),
                      ],
                    ),
                  ),
                ),

                // Categories Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          'See All',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dynamic Categories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: recommendedItemsAsync.when(
                      data: (_) => ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: List.generate(_moodChips.length, (index) {
                          final mood = _moodChips[index];
                          return _buildCategoryItem(
                            context,
                            mood.label,
                            mood.icon,
                            _selectedMood == mood.label,
                            index,
                            onTap: () => setState(() => _selectedMood = mood.label),
                          );
                        }),
                      ),
                      loading: () => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: 5,
                        itemBuilder: (context, index) => const CategoryShimmer(),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 24, right: 24, bottom: 16),
                    child: userOrdersAsync.when(
                      data: (orders) => _ReorderStudioCard(
                        latestOrder: _latestOrder(orders),
                        isSubmitting: _isReordering,
                        onOpenVendor: (order) {
                          if (order == null) return;
                          HapticFeedback.lightImpact();
                          context.push('/vendor/${order.vendorId}');
                        },
                        onQuickRepeat: _quickRepeatOrder,
                      ),
                      loading: () => const VendorCardShimmer(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Featured Vendors Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 16),
                    child: Text(
                      _selectedMood == 'All'
                          ? 'Featured Food Items'
                          : '$_selectedMood Picks',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),

                // Recommended Food List
                recommendedItemsAsync.when(
                  data: (items) => SliverPadding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mood = _moodChips.firstWhere((chip) => chip.label == _selectedMood);
                          final filteredItems = items.where((item) => _matchesMood(item, mood)).toList();
                          if (filteredItems.isEmpty) {
                            return const _NoMoodMatchesCard();
                          }

                          final item = filteredItems[index];
                          return AppAnimations.staggeredList(
                            index,
                            _RecommendedFoodCard(
                              item: item,
                              onTap: () {
                                final vendorId = item.vendor?.id;
                                if (vendorId != null && vendorId.isNotEmpty) {
                                  context.push('/vendor/$vendorId');
                                }
                              },
                            ),
                          );
                        },
                        childCount: (() {
                          final mood = _moodChips.firstWhere((chip) => chip.label == _selectedMood);
                          final filteredItems = items.where((item) => _matchesMood(item, mood)).toList();
                          return filteredItems.isEmpty ? 1 : filteredItems.length;
                        })(),
                      ),
                    ),
                  ),
                  loading: () => SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const VendorCardShimmer(),
                        childCount: 3,
                      ),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading recommendations: $e')),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Bottom Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildBottomNav(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    int index, {
    required VoidCallback onTap,
  }) {
    return AppAnimations.staggeredList(
      index,
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: isActive ? Colors.white : AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteGlass,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, true, () {}),
          _buildNavItem(Icons.history_rounded, false, () {
            HapticFeedback.lightImpact();
            context.push('/order-history');
          }),
          _buildNavItemWithBadge(Icons.shopping_bag_rounded, cartCount, () {
            HapticFeedback.lightImpact();
            context.push('/cart');
          }),
          _buildNavItem(Icons.person_rounded, false, () {
            HapticFeedback.lightImpact();
            context.push('/profile');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(IconData icon, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodChip {
  final String label;
  final IconData icon;
  final List<String> keywords;

  const _MoodChip({
    required this.label,
    required this.icon,
    required this.keywords,
  });
}

class _EtaConfidenceBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ETA confidence: high for 12-22 min routes this hour',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderStudioCard extends StatelessWidget {
  final OrderModel? latestOrder;
  final bool isSubmitting;
  final ValueChanged<OrderModel?> onOpenVendor;
  final ValueChanged<OrderModel?> onQuickRepeat;

  const _ReorderStudioCard({
    required this.latestOrder,
    required this.isSubmitting,
    required this.onOpenVendor,
    required this.onQuickRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final hasOrder = latestOrder != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.replay_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reorder Studio',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  hasOrder
                      ? 'Last order from ${latestOrder!.vendorName ?? 'your recent vendor'} • Rs ${latestOrder!.totalAmount.toStringAsFixed(0)}'
                      : 'No recent orders yet. Your repeats will show up here.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (hasOrder) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${latestOrder!.items.length} items ready to repeat',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              OutlinedButton(
                onPressed: hasOrder ? () => onOpenVendor(latestOrder) : null,
                child: const Text('Open'),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: hasOrder && !isSubmitting ? () => onQuickRepeat(latestOrder) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(74, 36),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Repeat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoMoodMatchesCard extends StatelessWidget {
  const _NoMoodMatchesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, size: 28, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('No food items match this mood yet', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Try a different mood chip to see more options.'),
        ],
      ),
    );
  }
}

class _RecommendedFoodCard extends StatelessWidget {
  const _RecommendedFoodCard({required this.item, required this.onTap});

  final RecommendedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vendorName = item.vendor?.name ?? 'Campus Vendor';
    final description = item.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  image: DecorationImage(
                    image: NetworkImage(
                      item.imageUrl ?? 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Top Pick',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 30),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rs ${item.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vendorName,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
