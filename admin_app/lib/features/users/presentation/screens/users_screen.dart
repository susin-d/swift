import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_user.dart';
import '../providers/users_provider.dart';
import '../../../../../shared/widgets/reason_capture_dialog.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _query = '';
  bool _isBulkProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _UsersError(
        message: error.toString(),
        onRetry: () => ref.read(usersProvider.notifier).refresh(),
      ),
      data: (state) {
        final allIds = state.users.map((e) => e.id).toSet();
        _selectedIds.removeWhere((id) => !allIds.contains(id));
        final filtered = state.users.where((u) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(usersProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 360,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search by name or email',
                          ),
                        ),
                      ),
                      Text('${filtered.length} of ${state.total} users'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _UsersEmpty()
              else ...[
                _UsersBulkActionBar(
                  selectedCount: _selectedIds.length,
                  allVisibleSelected:
                      filtered.isNotEmpty &&
                      filtered.every((user) => _selectedIds.contains(user.id)),
                  processing: _isBulkProcessing,
                  onSelectVisible: () {
                    setState(() {
                      for (final user in filtered) {
                        _selectedIds.add(user.id);
                      }
                    });
                  },
                  onClearSelection: () => setState(_selectedIds.clear),
                  onToggleSelectVisible: (value) {
                    setState(() {
                      if (value) {
                        for (final user in filtered) {
                          _selectedIds.add(user.id);
                        }
                      } else {
                        for (final user in filtered) {
                          _selectedIds.remove(user.id);
                        }
                      }
                    });
                  },
                  onBlockSelected: () => _bulkSetBlocked(context, blocked: true),
                  onUnblockSelected: () => _bulkSetBlocked(context, blocked: false),
                  onChangeRoleSelected: (role) => _bulkChangeRole(context, role),
                ),
                const SizedBox(height: 12),
                ...filtered.map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserCard(
                      user: u,
                      selected: _selectedIds.contains(u.id),
                      onSelectedChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedIds.add(u.id);
                          } else {
                            _selectedIds.remove(u.id);
                          }
                        });
                      },
                      onViewDetails: () => _showUserDetails(context, u),
                    ),
                  ),
                ),
                if (state.hasMore)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(usersProvider.notifier).loadMore(),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load more'),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _bulkSetBlocked(
    BuildContext context, {
    required bool blocked,
  }) async {
    if (_selectedIds.isEmpty || _isBulkProcessing) return;

    String? reason;
    if (blocked) {
      reason = await ReasonCaptureDialog.show(
        context,
        title: 'Block selected users',
        actionLabel: 'Block all',
        warningText:
            'You are about to block ${_selectedIds.length} users. Provide a reason for audit logging.',
      );
      if (reason == null || !context.mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unblock selected users'),
          content: Text(
            'Unblock ${_selectedIds.length} users and restore their access?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Unblock all'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    setState(() => _isBulkProcessing = true);
    final result = await ref.read(usersProvider.notifier).setBlockedMany(
          _selectedIds.toList(),
          blocked: blocked,
          reason: reason,
        );

    if (!context.mounted) return;
    setState(() {
      _isBulkProcessing = false;
      _selectedIds.clear();
    });

    _showBulkResultSnackBar(
      context,
      success: result.successCount,
      failed: result.errors.length,
      successVerb: blocked ? 'blocked' : 'unblocked',
      firstError: result.errors.values.isNotEmpty
          ? result.errors.values.first
          : null,
    );
  }

  Future<void> _bulkChangeRole(BuildContext context, String role) async {
    if (_selectedIds.isEmpty || _isBulkProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change selected users role'),
        content: Text(
          'Set role of ${_selectedIds.length} users to $role?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isBulkProcessing = true);
    final result = await ref
        .read(usersProvider.notifier)
        .changeRoleMany(_selectedIds.toList(), role);

    if (!context.mounted) return;
    setState(() {
      _isBulkProcessing = false;
      _selectedIds.clear();
    });

    _showBulkResultSnackBar(
      context,
      success: result.successCount,
      failed: result.errors.length,
      successVerb: 'updated',
      firstError: result.errors.values.isNotEmpty
          ? result.errors.values.first
          : null,
    );
  }

  void _showBulkResultSnackBar(
    BuildContext context, {
    required int success,
    required int failed,
    required String successVerb,
    String? firstError,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (failed == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('$success users $successVerb successfully.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$success succeeded, $failed failed. First error: ${firstError ?? 'Unknown error'}',
        ),
        backgroundColor: const Color(0xFFB45309),
      ),
    );
  }

  Future<void> _showUserDetails(BuildContext context, AdminUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  _UserDetailRow(label: 'User ID', value: user.id),
                  _UserDetailRow(label: 'Role', value: user.role.toUpperCase()),
                  _UserDetailRow(
                    label: 'Blocked',
                    value: user.blocked ? 'Yes' : 'No',
                  ),
                  _UserDetailRow(label: 'Joined', value: _date(user.createdAt)),
                  const SizedBox(height: 12),
                  Text(
                    'Note: order count is not exposed by the current users endpoint.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({
    required this.user,
    required this.onViewDetails,
    required this.selected,
    required this.onSelectedChanged,
  });

  final AdminUser user;
  final VoidCallback onViewDetails;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelectedChanged(value ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _RoleChip(role: user.role),
                if (user.blocked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'BLOCKED',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Joined ${_date(user.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Details'),
                ),
                DropdownButton<String>(
                  value: user.role,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (role) {
                    if (role != null && role != user.role) {
                      _confirmRoleChange(context, ref, role);
                    }
                  },
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _confirmToggleBlock(context, ref),
                  icon: Icon(
                    user.blocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                  ),
                  label: Text(user.blocked ? 'Unblock' : 'Block'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRoleChange(
    BuildContext context,
    WidgetRef ref,
    String role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change role'),
        content: Text('Change ${user.name} role to $role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(usersProvider.notifier).changeRole(user, role);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Role updated to $role.'),
        backgroundColor: error == null ? null : const Color(0xFFB91C1C),
      ),
    );
  }

  Future<void> _confirmToggleBlock(BuildContext context, WidgetRef ref) async {
    final targetBlocked = !user.blocked;

    if (targetBlocked) {
      // Blocking is a sensitive action — require a reason.
      final reason = await ReasonCaptureDialog.show(
        context,
        title: 'Block user',
        actionLabel: 'Block',
        warningText:
            'Blocking ${user.name} prevents them from signing in. Provide a reason that will be stored in the audit log.',
      );
      if (reason == null || !context.mounted) return;

      final error = await ref
          .read(usersProvider.notifier)
          .toggleBlocked(user, reason: reason);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'User blocked successfully.'),
          backgroundColor: error == null ? null : const Color(0xFFB91C1C),
        ),
      );
    } else {
      // Unblocking is a reversible action — simple confirmation is sufficient.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unblock user'),
          content: Text('Unblock ${user.name} and restore their access?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Unblock'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final error = await ref.read(usersProvider.notifier).toggleBlocked(user);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'User unblocked successfully.'),
          backgroundColor: error == null ? null : const Color(0xFFB91C1C),
        ),
      );
    }
  }
}

class _UsersBulkActionBar extends StatelessWidget {
  const _UsersBulkActionBar({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.processing,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onToggleSelectVisible,
    required this.onBlockSelected,
    required this.onUnblockSelected,
    required this.onChangeRoleSelected,
  });

  final int selectedCount;
  final bool allVisibleSelected;
  final bool processing;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onToggleSelectVisible;
  final VoidCallback onBlockSelected;
  final VoidCallback onUnblockSelected;
  final ValueChanged<String> onChangeRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$selectedCount selected'),
            FilterChip(
              label: const Text('Select visible'),
              selected: allVisibleSelected,
              onSelected: processing ? null : onToggleSelectVisible,
            ),
            OutlinedButton(
              onPressed: processing ? null : onSelectVisible,
              child: const Text('Select all filtered'),
            ),
            OutlinedButton(
              onPressed: processing ? null : onClearSelection,
              child: const Text('Clear'),
            ),
            FilledButton.tonalIcon(
              onPressed: processing || selectedCount == 0 ? null : onBlockSelected,
              icon: const Icon(Icons.block_rounded),
              label: const Text('Block selected'),
            ),
            FilledButton.tonalIcon(
              onPressed:
                  processing || selectedCount == 0 ? null : onUnblockSelected,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unblock selected'),
            ),
            PopupMenuButton<String>(
              enabled: !processing && selectedCount > 0,
              onSelected: onChangeRoleSelected,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'user', child: Text('Set role: user')),
                PopupMenuItem(value: 'vendor', child: Text('Set role: vendor')),
                PopupMenuItem(value: 'admin', child: Text('Set role: admin')),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_rounded),
                    SizedBox(width: 6),
                    Text('Change role'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailRow extends StatelessWidget {
  const _UserDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      'admin' => (const Color(0xFFE8F5FF), const Color(0xFF1D4ED8)),
      'vendor' => (const Color(0xFFE7F8EE), const Color(0xFF166534)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _UsersEmpty extends StatelessWidget {
  const _UsersEmpty();

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
                const Icon(
                  Icons.group_off_rounded,
                  size: 36,
                  color: Color(0xFF475569),
                ),
                const SizedBox(height: 12),
                Text(
                  'No users found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search query.',
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
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message, required this.onRetry});

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
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB91C1C),
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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

String _date(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown';
  return DateFormat('dd MMM yyyy').format(dateTime);
}
