import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/customer_shell.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/recommended_item.dart';
import '../../models/search_result.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../core/utils/app_animations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> homeBottomNavLabels = ['Home', 'Orders', 'Cart', 'Profile'];
const String homeHeroPrimaryCtaLabel = 'Order Now';
const String homeCategoriesErrorText = 'Unable to load categories right now.';
const String homeReorderErrorText = 'Reorder Studio is unavailable right now.';
const String homeFeaturedErrorText = 'Featured items could not be loaded.';
const String homeReorderFailureText = 'Quick reorder failed. Please try again.';
const String homeTipPrimaryText =
    'Tip: mood chips filter discovery, and Reorder Studio repeats your latest order quickly.';
const String homeTipSecondaryText =
    'Use Home, Orders, Cart, and Profile tabs below to move through your order flow faster.';
const Duration homeMicroAnimationDuration = Duration(milliseconds: 180);

String moodDescriptionForLabel(String label) {
  switch (label) {
    case 'Comfort':
      return 'Hearty and filling meals';
    case 'Quick':
      return 'Fast bites and snacks';
    case 'Sweet':
      return 'Desserts and bakery picks';
    case 'Light':
      return 'Fresh and lighter options';
    default:
      return 'Browse every available item';
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedMood = 'All';
  bool _isReordering = false;
  bool _showHomeTips = false;
  int _homeTipStep = 0;
  static const String _homeTipsSeenKey = 'home_tips_seen_v1';

  static const List<_MoodChip> _moodChips = [
    _MoodChip(label: 'All', icon: Icons.restaurant_rounded, keywords: []),
    _MoodChip(
      label: 'Comfort',
      icon: Icons.ramen_dining_rounded,
      keywords: ['north', 'indian', 'meal', 'comfort'],
    ),
    _MoodChip(
      label: 'Quick',
      icon: Icons.flash_on_rounded,
      keywords: ['quick', 'snack', 'fast'],
    ),
    _MoodChip(
      label: 'Sweet',
      icon: Icons.icecream_rounded,
      keywords: ['dessert', 'sweet', 'bakery'],
    ),
    _MoodChip(
      label: 'Light',
      icon: Icons.eco_rounded,
      keywords: ['healthy', 'salad', 'light'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeTipsState();
  }

  Future<void> _loadHomeTipsState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTips = prefs.getBool(_homeTipsSeenKey) ?? false;
    if (!mounted || hasSeenTips) return;
    setState(() => _showHomeTips = true);
  }

  Future<void> _dismissHomeTips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTipsSeenKey, true);
    if (!mounted) return;
    setState(() => _showHomeTips = false);
  }

  void _nextHomeTip() {
    if (_homeTipStep == 0) {
      setState(() => _homeTipStep = 1);
      return;
    }
    _dismissHomeTips();
  }

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
    final sorted = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  Future<void> _quickRepeatOrder(OrderModel? order) async {
    if (order == null || order.items.isEmpty || _isReordering) return;

    setState(() => _isReordering = true);
    try {
      final placed = await ref
          .read(orderServiceProvider)
          .placeOrder(
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(homeReorderFailureText),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _quickRepeatOrder(order),
          ),
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
    final isCompactWidth = MediaQuery.sizeOf(context).width < 360;
    final pagePadding = isCompactWidth ? 16.0 : 24.0;
    final heroTopPadding = isCompactWidth ? 52.0 : 64.0;
    final heroBottomPadding = isCompactWidth ? 22.0 : 28.0;
    final recommendedItemsAsync = ref.watch(allFoodItemsProvider);
    final userOrdersAsync = ref.watch(userOrdersProvider);

    return CustomerShell(
      selectedIndex: 0,
      showHeader: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allFoodItemsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
                // Vibrant Hero Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: heroTopPadding,
                      left: pagePadding,
                      right: pagePadding,
                      bottom: heroBottomPadding,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
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
                                    color: Colors.white.withValues(alpha: 0.92),
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
                                tooltip: 'Open notifications',
                                onPressed: () => context.push('/notifications'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/search');
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(homeHeroPrimaryCtaLabel),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(140, 48),
                            textStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Search Bar Placeholder
                        GestureDetector(
                          onTap: () => context.push('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Search for a vendor or dish...',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isCompactWidth ? 13 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EtaConfidenceBand(),
                        if (_showHomeTips) ...[
                          const SizedBox(height: 14),
                          _HomeTipsCard(
                            step: _homeTipStep,
                            onNext: _nextHomeTip,
                            onDismiss: _dismissHomeTips,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Categories Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 32,
                      left: pagePadding,
                      right: pagePadding,
                      bottom: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedMood = 'All');
                            context.push('/search');
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        children: List.generate(_moodChips.length, (index) {
                          final mood = _moodChips[index];
                          return _buildCategoryItem(
                            context,
                            mood.label,
                            mood.icon,
                            _selectedMood == mood.label,
                            index,
                            onTap: () => setState(() {
                              _selectedMood = mood.label;
                            }),
                          );
                        }),
                      ),
                      loading: () => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const CategoryShimmer(),
                      ),
                      error: (_, _) => _InlineLoadStateCard(
                        icon: Icons.category_outlined,
                        message: homeCategoriesErrorText,
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(allFoodItemsProvider),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 6,
                      left: pagePadding,
                      right: pagePadding,
                      bottom: 16,
                    ),
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
                      error: (_, _) => _InlineLoadStateCard(
                        icon: Icons.history_toggle_off_rounded,
                        message: homeReorderErrorText,
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(userOrdersProvider),
                      ),
                    ),
                  ),
                ),

                // Featured Vendors Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 24,
                      left: pagePadding,
                      right: pagePadding,
                      bottom: 16,
                    ),
                    child: AnimatedSwitcher(
                      duration: homeMicroAnimationDuration,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.14),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: Text(
                        _selectedMood == 'All'
                            ? 'Featured Food Items'
                            : '$_selectedMood Picks',
                        key: ValueKey<String>(_selectedMood),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                  ),
                ),

                // Recommended Food List
                recommendedItemsAsync.when(
                  data: (items) {
                    final mood = _moodChips.firstWhere(
                      (chip) => chip.label == _selectedMood,
                    );
                    final filteredItems = items
                        .where((item) => _matchesMood(item, mood))
                        .toList();

                    if (filteredItems.isEmpty) {
                      return SliverPadding(
                        padding: EdgeInsets.only(
                          left: pagePadding,
                          right: pagePadding,
                          bottom: 120,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _NoMoodMatchesCard(
                            onExploreAll: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedMood = 'All');
                              context.push('/search');
                            },
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.only(
                        left: pagePadding,
                        right: pagePadding,
                        bottom: 120,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = filteredItems[index];
                          return AppAnimations.staggeredList(
                            index,
                            _RecommendedFoodGridCard(
                              item: item,
                              onTap: () {
                                context.push(
                                  '/item',
                                  extra: SearchResult(
                                    id: item.id,
                                    name: item.name,
                                    description: item.description,
                                    price: item.price,
                                    imageUrl: item.imageUrl,
                                    vendor: item.vendor == null
                                        ? null
                                        : SearchVendor(
                                            id: item.vendor!.id,
                                            name: item.vendor!.name,
                                            description:
                                                item.vendor!.description,
                                            imageUrl: item.vendor!.imageUrl,
                                          ),
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: filteredItems.length),
                      ),
                    );
                  },
                  loading: () => SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: pagePadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const VendorCardShimmer(),
                        childCount: 3,
                      ),
                    ),
                  ),
                  error: (_, _) => SliverPadding(
                    padding: EdgeInsets.only(
                      left: pagePadding,
                      right: pagePadding,
                      bottom: 120,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _InlineLoadStateCard(
                        icon: Icons.cloud_off_rounded,
                        message: homeFeaturedErrorText,
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(allFoodItemsProvider),
                      ),
                    ),
                  ),
                ),
          ],
        ),
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
            Tooltip(
              message: moodDescriptionForLabel(label),
              child: Semantics(
                button: true,
                selected: isActive,
                label: '$label mood. ${moodDescriptionForLabel(label)}',
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: homeMicroAnimationDuration,
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isActive ? AppColors.primaryGradient : null,
                      color: isActive ? null : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? Colors.white : AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ETA confidence: high for 12-22 min routes this hour',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTipsCard extends StatelessWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback onDismiss;

  const _HomeTipsCard({
    required this.step,
    required this.onNext,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isFinalStep = step > 0;
    final bodyText = isFinalStep ? homeTipSecondaryText : homeTipPrimaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bodyText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onNext,
            child: Text(
              isFinalStep ? 'Done' : 'Next',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isFinalStep)
            TextButton(
              onPressed: onDismiss,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
                Row(
                  children: [
                    Text(
                      'Reorder Studio',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Repeat your latest order in one tap.',
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasOrder
                      ? 'Last order from ${latestOrder!.vendorName ?? 'your recent vendor'} \u2022 Rs ${latestOrder!.totalAmount.toStringAsFixed(0)}'
                      : 'No recent orders yet. Your repeats will show up here.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
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
                onPressed: hasOrder && !isSubmitting
                    ? () => onQuickRepeat(latestOrder)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(74, 36),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
  final VoidCallback onExploreAll;

  const _NoMoodMatchesCard({required this.onExploreAll});

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
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 28,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'No food items match this mood yet',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('Try a different mood chip to see more options.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onExploreAll,
            icon: const Icon(Icons.travel_explore_rounded),
            label: const Text('Explore all food'),
          ),
        ],
      ),
    );
  }
}

class _InlineLoadStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineLoadStateCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _RecommendedFoodGridCard extends StatefulWidget {
  const _RecommendedFoodGridCard({required this.item, required this.onTap});

  final RecommendedItem item;
  final VoidCallback onTap;

  @override
  State<_RecommendedFoodGridCard> createState() =>
      _RecommendedFoodGridCardState();
}

class _RecommendedFoodGridCardState extends State<_RecommendedFoodGridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final vendorName = widget.item.vendor?.name ?? 'Campus Vendor';

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1,
      duration: homeMicroAnimationDuration,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) {
          if (_isPressed == value) return;
          setState(() => _isPressed = value);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.03 : 0.05),
                blurRadius: _isPressed ? 8 : 14,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        widget.item.imageUrl ??
                            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendorName,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\u20B9${widget.item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
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
}
