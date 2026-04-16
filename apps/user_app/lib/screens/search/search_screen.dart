import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/customer_shell.dart';
import '../../core/widgets/responsive_content.dart';
import '../../models/recommended_item.dart';
import '../../models/search_result.dart';
import '../../providers/vendor_provider.dart';
import '../../services/search_service.dart';

const String searchErrorActionLabel = 'Try again';
const String searchNoMatchesActionLabel = 'Clear query';
const String searchResultSemanticPrefix = 'Search result';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String _query = '';
  String _selectedCategory = 'All';
  String? _error;
  List<SearchResult> _results = [];

  static const List<String> _browseCategories = [
    'All',
    'Fast food',
    'Healthy',
    'South Indian',
    'Drinks',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SearchService();
      final raw = await service.searchItems(query.trim());
      final results = raw.map((json) => SearchResult.fromJson(json)).toList();
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
    });
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => _performSearch(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomerShell(
      selectedIndex: 1,
      destinations: CustomerShell.primaryDestinations,
      showHeader: false,
      body: ResponsiveContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              child: TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search food or vendors...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (_query.trim().isEmpty) _buildBrowseChips(),
            const SizedBox(height: 12),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _browseCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _browseCategories[index];
          final selected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_query.trim().isEmpty) {
      return _BrowseGrid(category: _selectedCategory);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _EmptySearchState(
        title: 'Search failed',
        subtitle: _error!,
        actionLabel: searchErrorActionLabel,
        onAction: () => _performSearch(_query),
      );
    }

    if (_results.isEmpty) {
      return _EmptySearchState(
        title: 'No matches yet',
        subtitle: 'Try a different keyword or search for a vendor name.',
        actionLabel: searchNoMatchesActionLabel,
        onAction: () {
          _controller.clear();
          _onQueryChanged('');
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _results.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _SearchResultCard(
          result: result,
          onTap: () {
            context.push('/item', extra: result);
          },
        );
      },
    );
  }
}

class _BrowseGrid extends ConsumerWidget {
  const _BrowseGrid({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allFoodItemsProvider).when(
      data: (items) {
        final filtered = items.where((item) => _matchesCategory(item, category)).toList();
        if (filtered.isEmpty) {
          return _EmptySearchState(
            title: 'No matches yet',
            subtitle: 'Try another category or type a search query.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _BrowseCard(
              item: item,
              onTap: () {
                context.push('/item', extra: SearchResult(
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
                ));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _EmptySearchState(
        title: 'Browse failed',
        subtitle: 'Unable to load menu items right now.',
      ),
    );
  }

  bool _matchesCategory(RecommendedItem item, String category) {
    if (category == 'All') return true;
    final text = '${item.category ?? ''} ${item.name} ${item.description ?? ''}'.toLowerCase();
    switch (category) {
      case 'Fast food':
        return text.contains('pizza') || text.contains('burger') || text.contains('taco') || text.contains('fries');
      case 'Healthy':
        return text.contains('healthy') || text.contains('salad') || text.contains('bowl');
      case 'South Indian':
        return text.contains('idli') || text.contains('dosa') || text.contains('south') || text.contains('uttapam');
      case 'Drinks':
        return text.contains('coffee') || text.contains('tea') || text.contains('drink') || text.contains('juice');
      default:
        return text.contains(category.toLowerCase());
    }
  }
}

class _BrowseCard extends StatelessWidget {
  const _BrowseCard({required this.item, required this.onTap});

  final RecommendedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFE0F0EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF9AD7C9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DbImageBlock(
                imageUrl: item.imageUrl,
                fallback: _categoryEmoji(item.category),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}+ · ${_estimateMinutes(item.category)} min',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '★ ${item.score > 0 ? item.score.toStringAsFixed(1) : '4.5'}',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      color: const Color(0xFFE0F0EB),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: const TextStyle(fontSize: 42),
      ),
    );
  }
}

int _estimateMinutes(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('coffee') || value.contains('drink')) return 10;
  if (value.contains('salad') || value.contains('light')) return 15;
  if (value.contains('biryani') || value.contains('meal')) return 25;
  if (value.contains('dessert') || value.contains('sweet')) return 18;
  return 15;
}

String _categoryEmoji(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('pizza')) return '🍕';
  if (value.contains('noodle') || value.contains('ramen')) return '🍜';
  if (value.contains('salad') || value.contains('bowl')) return '🥗';
  if (value.contains('coffee') || value.contains('drink')) return '☕';
  if (value.contains('taco')) return '🌮';
  if (value.contains('dessert') || value.contains('sweet')) return '🧁';
  return '🍽️';
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vendorName = result.vendor?.name ?? 'Campus Vendor';
    final description = result.description?.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Semantics(
        button: true,
        label:
            '$searchResultSemanticPrefix ${result.name}, $vendorName, Rs ${result.price.toStringAsFixed(0)}',
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: _DbImageBlock(
                    imageUrl: result.imageUrl ?? result.vendor?.imageUrl,
                    fallback: _categoryEmoji(null),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendorName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u20B9${result.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
