import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/customer_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../models/recommended_item.dart';
import '../../models/search_result.dart';
import '../../providers/order_provider.dart';
import '../../providers/vendor_provider.dart';

const List<String> homeBottomNavLabels = [
  'Home',
  'Browse',
  'Orders',
  'Wallet',
  'Account',
];
const String homeHeroPrimaryCtaLabel = 'Order Now';
const String homeCategoriesErrorText = 'Unable to load categories right now.';
const String homeReorderErrorText = 'Reorder Studio is unavailable right now.';
const String homeFeaturedErrorText = 'Featured items could not be loaded.';
const String homeReorderFailureText = 'Quick reorder failed. Please try again.';
const String homeTipPrimaryText =
    'Tip: browse chips help discovery, and live order tracking keeps the top card fresh.';
const String homeTipSecondaryText =
    'Use Home, Browse, Orders, Wallet, and Account tabs below to move faster.';
const Duration homeMicroAnimationDuration = Duration(milliseconds: 180);

String moodDescriptionForLabel(String label) {
  switch (label) {
    case 'All':
      return 'Browse every available item';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final itemsAsync = ref.watch(allFoodItemsProvider);

    return CustomerShell(
      selectedIndex: 0,
      destinations: CustomerShell.primaryDestinations,
      showHeader: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(userOrdersProvider);
          ref.invalidate(allFoodItemsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                child: _GreetingHeader(name: _resolveUserName(user)),
              ),
            ),
            SliverToBoxAdapter(
              child: ordersAsync.when(
                data: (orders) => _OrderStatusCard(order: _pickPriorityOrder(orders)),
                loading: () => const _OrderStatusCardLoading(),
                error: (_, _) => const _OrderStatusCard(order: null),
              ),
            ),
            SliverToBoxAdapter(
              child: ordersAsync.when(
                data: _MetricsRow.new,
                loading: () => const _MetricsRow([]),
                error: (_, _) => const _MetricsRow([]),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 24, bottom: 10),
                child: _SectionTitle(title: 'RECOMMENDED'),
              ),
            ),
            SliverToBoxAdapter(
              child: itemsAsync.when(
                data: (items) => _RecommendationsRow(items: items.take(8).toList()),
                loading: () => const _RecommendationsLoading(),
                error: (_, _) => const _RecommendationsRow(items: []),
              ),
            ),
            // ACTIVE OFFER section removed
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }
}

String _resolveUserName(Map<String, dynamic>? user) {
  final metadata = user?['user_metadata'];
  if (metadata is Map && metadata['name'] is String) {
    final name = (metadata['name'] as String).trim();
    if (name.isNotEmpty) return name;
  }

  final email = user?['email'];
  if (email is String && email.contains('@')) {
    final beforeAt = email.split('@').first.trim();
    if (beforeAt.isNotEmpty) {
      return '${beforeAt[0].toUpperCase()}${beforeAt.substring(1)}';
    }
  }

  return 'Arjun';
}

OrderModel? _pickPriorityOrder(List<OrderModel> orders) {
  if (orders.isEmpty) return null;
  final sorted = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final order in sorted) {
    if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) {
      return order;
    }
  }
  return sorted.first;
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Good morning, $name',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF05473D),
              fontSize: 33,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFD8F1EC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF0A7F6F), size: 21),
        ),
      ],
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});

  final OrderModel? order;

  @override
  Widget build(BuildContext context) {
    final hasOrder = order != null;
    final etaMin = order?.eta?.minMinutes ?? 12;
    final etaMax = order?.eta?.maxMinutes ?? 18;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF157D63), Color(0xFF07564B)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasOrder ? 'Order on the way' : 'Ready to order',
            style: GoogleFonts.inter(
              color: const Color(0xFFC4F2E5),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasOrder ? '${order!.vendorName ?? 'Campus Vendor'} · #${order!.id.substring(0, order!.id.length.clamp(0, 4))}' : 'Find your next meal',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            hasOrder
                ? _orderSubtitle(order!)
                : 'Browse restaurants and place your first order in seconds.',
            style: GoogleFonts.inter(
              color: const Color(0xFFDDF8EF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _ProgressStrip(status: order?.status ?? OrderStatus.pending),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              if (hasOrder) {
                context.push('/order-status/${order!.id}');
              } else {
                context.push('/search');
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF82D6C2)),
                color: const Color(0xFF1A7B66).withValues(alpha: 0.4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasOrder
                          ? 'ETA $etaMin-$etaMax min · ${_confidenceLabel(order!.eta?.confidence)} confidence'
                          : 'Discover meals with 10-20 min delivery',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    hasOrder ? 'Track →' : 'Browse →',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusCardLoading extends StatelessWidget {
  const _OrderStatusCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3EF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final progress = _statusProgress(status);
    final labels = <String>['Placed', 'Preparing', 'On way', 'Done'];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF53A38F),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBFF5E7)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(labels.length, (index) {
            final label = labels[index];
            final active = progress >= ((index + 1) / labels.length);
            return Expanded(
              child: Text(
                label,
                textAlign: index == 0
                    ? TextAlign.left
                    : index == labels.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: GoogleFonts.inter(
                  color: active ? const Color(0xFFE5FAF4) : const Color(0xFFA5E1D3),
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

double _statusProgress(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 0.25;
    case OrderStatus.accepted:
    case OrderStatus.preparing:
      return 0.52;
    case OrderStatus.ready:
      return 0.78;
    case OrderStatus.completed:
      return 1;
    case OrderStatus.cancelled:
      return 0;
  }
}

String _orderSubtitle(OrderModel order) {
  if (order.items.isEmpty) {
    return 'Status: ${order.status.name}';
  }
  final firstItem = order.items.first;
  final name = firstItem.menuItem?.name ?? 'Meal';
  final qty = firstItem.quantity;
  final extra = order.items.length > 1 ? ' +${order.items.length - 1} more' : '';
  return '$name · x$qty$extra';
}

String _confidenceLabel(String? confidence) {
  switch ((confidence ?? '').toLowerCase()) {
    case 'high':
      return 'High';
    case 'medium':
      return 'Medium';
    case 'low':
      return 'Low';
    default:
      return 'High';
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow(this.orders);

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final totalSpent = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final walletBalance = (480 + (orders.length * 8)).toInt();
    final loyaltyPoints = (totalSpent / 2.3).round();
    final todaySavings = (orders.length * 18).toInt();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'Wallet',
              value: '₹$walletBalance',
              caption: '+₹$todaySavings today',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              title: 'Loyalty pts',
              value: '$loyaltyPoints',
              caption: loyaltyPoints >= 300 ? 'Silver tier' : 'Starter tier',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
  });

  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFCFE3DE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8CCFBF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF0D6557),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF06483D),
              fontSize: 39,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A8A73),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFF007B66),
        letterSpacing: 0.5,
        fontSize: 35,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RecommendationsRow extends StatelessWidget {
  const _RecommendationsRow({required this.items});

  final List<RecommendedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyRecommendations(onTap: () => context.push('/search'));
    }

    return SizedBox(
      height: 272,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _RecommendationCard(
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
                          description: item.vendor!.description,
                          imageUrl: item.vendor!.imageUrl,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecommendationsLoading extends StatelessWidget {
  const _RecommendationsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 272,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});

  final RecommendedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 182,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF8CCFBF)),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 152,
                  width: double.infinity,
                  child: _DbImageBlock(
                    imageUrl: item.imageUrl,
                    fallback: _categoryEmoji(item.category),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF005246),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.price.toStringAsFixed(0)} · ${_estimateMinutes(item.category)} min',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A6A59),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '★ ${_scoreLabel(item.score)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A6A59),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

class _DbImageBlock extends StatelessWidget {
  const _DbImageBlock({required this.imageUrl, required this.fallback});

  final String? imageUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _FallbackArt(fallback: fallback);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _FallbackArt(fallback: fallback),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _FallbackArt(fallback: '');
      },
    );
  }
}

class _FallbackArt extends StatelessWidget {
  const _FallbackArt({required this.fallback});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD4E6E2),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: const TextStyle(fontSize: 46),
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBE7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8CCFBF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No recommendations yet',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF05473D),
              fontWeight: FontWeight.w600,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse categories to build your personalized feed.',
            style: GoogleFonts.inter(
              color: const Color(0xFF0C6657),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }
}


String _categoryEmoji(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('pizza')) return '🍕';
  if (value.contains('coffee') || value.contains('beverage')) return '☕';
  if (value.contains('salad')) return '🥗';
  if (value.contains('dessert') || value.contains('sweet')) return '🍰';
  if (value.contains('rice')) return '🍚';
  if (value.contains('chicken')) return '🍗';
  return '🍽️';
}

String _scoreLabel(double score) {
  if (score <= 0) return '4.6';
  final normalized = (4 + (score * 0.9)).clamp(4, 4.9);
  return normalized.toStringAsFixed(1);
}

int _estimateMinutes(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('coffee') || value.contains('drink')) return 10;
  if (value.contains('salad') || value.contains('light')) return 15;
  if (value.contains('biryani') || value.contains('meal')) return 25;
  if (value.contains('dessert') || value.contains('sweet')) return 18;
  return 15;
}
