import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/vendor_item.dart';
import '../providers/vendors_provider.dart';
import '../../../../../shared/widgets/reason_capture_dialog.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsProvider);

    return vendorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _VendorsError(
        message: error.toString(),
        onRetry: () => ref.read(vendorsProvider.notifier).refreshList(),
      ),
      data: (vendors) => _VendorsContent(vendors: vendors),
    );
  }
}

enum _VendorOpenFilter { all, open, closed }

enum _VendorSortMode { newest, oldest, nameAsc, nameDesc }

class _VendorsContent extends ConsumerStatefulWidget {
  const _VendorsContent({required this.vendors});

  final List<VendorItem> vendors;

  @override
  ConsumerState<_VendorsContent> createState() => _VendorsContentState();
}

class _VendorsContentState extends ConsumerState<_VendorsContent> {
  static const int _pageSize = 10;

  final Set<String> _selectedIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  _VendorOpenFilter _openFilter = _VendorOpenFilter.all;
  _VendorSortMode _sortMode = _VendorSortMode.newest;
  String _query = '';
  bool _isBulkProcessing = false;
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VendorItem> get _filteredVendors {
    final normalizedQuery = _query.trim().toLowerCase();

    final filtered = widget.vendors.where((vendor) {
      final matchesSearch = normalizedQuery.isEmpty ||
          vendor.name.toLowerCase().contains(normalizedQuery) ||
          vendor.ownerName.toLowerCase().contains(normalizedQuery) ||
          vendor.ownerEmail.toLowerCase().contains(normalizedQuery);

      final matchesOpenFilter = switch (_openFilter) {
        _VendorOpenFilter.all => true,
        _VendorOpenFilter.open => vendor.isOpen,
        _VendorOpenFilter.closed => !vendor.isOpen,
      };

      return matchesSearch && matchesOpenFilter;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortMode) {
        _VendorSortMode.newest => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        _VendorSortMode.oldest => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        _VendorSortMode.nameAsc => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _VendorSortMode.nameDesc => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      };
    });

    return filtered;
  }

  @override
  void didUpdateWidget(covariant _VendorsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final existingIds = widget.vendors.map((e) => e.id).toSet();
    _selectedIds.removeWhere((id) => !existingIds.contains(id));
    final filteredCount = _filteredVendors.length;
    if (_visibleCount > filteredCount && filteredCount > 0) {
      _visibleCount = filteredCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vendors.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF0F766E), size: 36),
                  const SizedBox(height: 12),
                  Text('No pending vendors', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'All vendor applications are currently processed. New requests will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filteredVendors = _filteredVendors;
    final visibleVendors = filteredVendors.take(_visibleCount).toList();
    final hasMore = filteredVendors.length > visibleVendors.length;

    return RefreshIndicator(
      onRefresh: () => ref.read(vendorsProvider.notifier).refreshList(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _VendorControls(
            searchController: _searchController,
            query: _query,
            openFilter: _openFilter,
            sortMode: _sortMode,
            onQueryChanged: (value) => setState(() {
              _query = value;
              _visibleCount = _pageSize;
            }),
            onFilterChanged: (value) => setState(() {
              _openFilter = value;
              _visibleCount = _pageSize;
            }),
            onSortChanged: (value) => setState(() {
              _sortMode = value;
              _visibleCount = _pageSize;
            }),
            totalCount: widget.vendors.length,
            filteredCount: filteredVendors.length,
          ),
          const SizedBox(height: 12),
          if (filteredVendors.isEmpty)
            _NoSearchResults(
              onReset: () {
                setState(() {
                  _query = '';
                  _openFilter = _VendorOpenFilter.all;
                  _sortMode = _VendorSortMode.newest;
                  _visibleCount = _pageSize;
                });
                _searchController.clear();
              },
            )
          else ...[
            _BulkActionBar(
              selectedCount: _selectedIds.length,
              allVisibleSelected: visibleVendors.isNotEmpty &&
                  visibleVendors.every((vendor) => _selectedIds.contains(vendor.id)),
              processing: _isBulkProcessing,
              onSelectVisible: () {
                setState(() {
                  for (final vendor in visibleVendors) {
                    _selectedIds.add(vendor.id);
                  }
                });
              },
              onClearSelection: () => setState(_selectedIds.clear),
              onToggleSelectVisible: (value) {
                setState(() {
                  if (value) {
                    for (final vendor in visibleVendors) {
                      _selectedIds.add(vendor.id);
                    }
                  } else {
                    for (final vendor in visibleVendors) {
                      _selectedIds.remove(vendor.id);
                    }
                  }
                });
              },
              onApproveSelected: () => _bulkModerate(context, approved: true),
              onRejectSelected: () => _bulkModerate(context, approved: false),
            ),
            const SizedBox(height: 12),
            ...List.generate(visibleVendors.length, (index) {
              final vendor = visibleVendors[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == visibleVendors.length - 1 && !hasMore ? 0 : 12),
                child: _VendorCard(
                  vendor: vendor,
                  selected: _selectedIds.contains(vendor.id),
                  onSelectedChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(vendor.id);
                      } else {
                        _selectedIds.remove(vendor.id);
                      }
                    });
                  },
                ),
              );
            }),
            if (hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _visibleCount = (_visibleCount + _pageSize).clamp(0, filteredVendors.length);
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text('Load more (${filteredVendors.length - visibleVendors.length} remaining)'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _bulkModerate(BuildContext context, {required bool approved}) async {
    if (_selectedIds.isEmpty || _isBulkProcessing) return;

    String? reason;
    if (!approved) {
      if (!context.mounted) return;
      reason = await ReasonCaptureDialog.show(
        context,
        title: 'Reject selected vendors',
        actionLabel: 'Reject all',
        warningText:
            'You are about to reject ${_selectedIds.length} vendors. Provide a reason that will be recorded in the audit log.',
      );
      if (reason == null || !context.mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve selected vendors'),
          content: Text(
            'Are you sure you want to approve ${_selectedIds.length} selected vendors?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Approve all'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    setState(() => _isBulkProcessing = true);
    final notifier = ref.read(vendorsProvider.notifier);
    final ids = _selectedIds.toList();

    final result = approved
        ? await notifier.approveMany(ids)
        : await notifier.rejectMany(ids, reason: reason!);

    if (!context.mounted) return;

    setState(() {
      _isBulkProcessing = false;
      _selectedIds.clear();
    });

    final messenger = ScaffoldMessenger.of(context);
    final failed = result.errors.length;
    final success = result.successCount;

    if (failed == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('$success vendors ${approved ? 'approved' : 'rejected'} successfully.')),
      );
      return;
    }

    final firstError = result.errors.values.first;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$success succeeded, $failed failed. First error: $firstError',
        ),
        backgroundColor: const Color(0xFFB45309),
      ),
    );
  }
}

class _VendorCard extends ConsumerWidget {
  const _VendorCard({
    required this.vendor,
    required this.selected,
    required this.onSelectedChanged,
  });

  final VendorItem vendor;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = _formatDate(vendor.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelectedChanged(value ?? false),
                ),
                const SizedBox(width: 6),
                _VendorAvatar(imageUrl: vendor.imageUrl, name: vendor.name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        vendor.description?.trim().isNotEmpty == true
                            ? vendor.description!
                            : 'No description provided.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(label: 'Owner: ${vendor.ownerName}', tone: const Color(0xFFE6F4F2), text: const Color(0xFF0F766E)),
                          _Tag(label: vendor.ownerEmail, tone: const Color(0xFFF3F5F8), text: const Color(0xFF475569)),
                          _Tag(label: 'Applied $dateLabel', tone: const Color(0xFFFFF4E6), text: const Color(0xFFB45309)),
                          _Tag(
                            label: vendor.isOpen ? 'Currently open' : 'Currently closed',
                            tone: vendor.isOpen ? const Color(0xFFE7F8EE) : const Color(0xFFFEE2E2),
                            text: vendor.isOpen ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _approveVendor(context, ref, vendor),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Approve'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _rejectVendor(context, ref, vendor),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveVendor(BuildContext context, WidgetRef ref, VendorItem vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve vendor'),
        content: Text('Approve ${vendor.name} and allow this store on the platform?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Approve')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(vendorsProvider.notifier).approve(vendor.id);
    if (!context.mounted) return;

    if (error == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('${vendor.name} approved successfully.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  Future<void> _rejectVendor(BuildContext context, WidgetRef ref, VendorItem vendor) async {
    final reason = await ReasonCaptureDialog.show(
      context,
      title: 'Reject vendor',
      actionLabel: 'Reject',
      warningText:
          'Rejecting ${vendor.name} removes this store from the pending queue. Provide a reason for the audit log.',
    );

    if (reason == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(vendorsProvider.notifier).reject(vendor.id, reason: reason);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Rejected ${vendor.name}.'),
        backgroundColor: error == null ? null : const Color(0xFFB45309),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tone, required this.text});

  final String label;
  final Color tone;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VendorControls extends StatelessWidget {
  const _VendorControls({
    required this.searchController,
    required this.query,
    required this.openFilter,
    required this.sortMode,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.totalCount,
    required this.filteredCount,
  });

  final TextEditingController searchController;
  final String query;
  final _VendorOpenFilter openFilter;
  final _VendorSortMode sortMode;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_VendorOpenFilter> onFilterChanged;
  final ValueChanged<_VendorSortMode> onSortChanged;
  final int totalCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search by vendor, owner, or email',
                ),
              ),
            ),
            DropdownButton<_VendorOpenFilter>(
              value: openFilter,
              onChanged: (value) {
                if (value != null) onFilterChanged(value);
              },
              items: const [
                DropdownMenuItem(value: _VendorOpenFilter.all, child: Text('All stores')),
                DropdownMenuItem(value: _VendorOpenFilter.open, child: Text('Open now')),
                DropdownMenuItem(value: _VendorOpenFilter.closed, child: Text('Closed now')),
              ],
            ),
            DropdownButton<_VendorSortMode>(
              value: sortMode,
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
              items: const [
                DropdownMenuItem(value: _VendorSortMode.newest, child: Text('Newest first')),
                DropdownMenuItem(value: _VendorSortMode.oldest, child: Text('Oldest first')),
                DropdownMenuItem(value: _VendorSortMode.nameAsc, child: Text('Name A-Z')),
                DropdownMenuItem(value: _VendorSortMode.nameDesc, child: Text('Name Z-A')),
              ],
            ),
            Text(
              '$filteredCount of $totalCount vendors',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (query.trim().isNotEmpty || openFilter != _VendorOpenFilter.all || sortMode != _VendorSortMode.newest)
              TextButton.icon(
                onPressed: () {
                  onQueryChanged('');
                  onFilterChanged(_VendorOpenFilter.all);
                  onSortChanged(_VendorSortMode.newest);
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.processing,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onToggleSelectVisible,
    required this.onApproveSelected,
    required this.onRejectSelected,
  });

  final int selectedCount;
  final bool allVisibleSelected;
  final bool processing;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onToggleSelectVisible;
  final VoidCallback onApproveSelected;
  final VoidCallback onRejectSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: allVisibleSelected,
                  onChanged: processing ? null : (v) => onToggleSelectVisible(v ?? false),
                ),
                const Text('Select visible'),
              ],
            ),
            if (selectedCount == 0)
              OutlinedButton.icon(
                onPressed: processing ? null : onSelectVisible,
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Select all visible'),
              )
            else ...[
              Text('$selectedCount selected'),
              OutlinedButton.icon(
                onPressed: processing ? null : onClearSelection,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear'),
              ),
              FilledButton.icon(
                onPressed: processing ? null : onApproveSelected,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(processing ? 'Processing...' : 'Approve selected'),
              ),
              FilledButton.tonalIcon(
                onPressed: processing ? null : onRejectSelected,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Reject selected'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.manage_search_rounded, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 12),
                Text('No vendors match current filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Try a different search query or reset the open/closed filter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'V'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
            .join();

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(initials: initials),
        ),
      );
    }

    return _FallbackAvatar(initials: initials);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFE7F8EE),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _VendorsError extends StatelessWidget {
  const _VendorsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 36),
                const SizedBox(height: 12),
                Text('Failed to load vendors', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'recently';
  return DateFormat('dd MMM yyyy').format(date);
}
