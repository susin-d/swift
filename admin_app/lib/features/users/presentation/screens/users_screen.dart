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
  String _query = '';

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
        final filtered = state.users.where((u) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
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
                ...filtered.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserCard(user: u),
                    )),
                if (state.hasMore)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(usersProvider.notifier).loadMore(),
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
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final AdminUser user;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                _RoleChip(role: user.role),
                if (user.blocked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'BLOCKED',
                      style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text('Joined ${_date(user.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
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
                  icon: Icon(user.blocked ? Icons.lock_open_rounded : Icons.block_rounded),
                  label: Text(user.blocked ? 'Unblock' : 'Block'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRoleChange(BuildContext context, WidgetRef ref, String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change role'),
        content: Text('Change ${user.name} role to $role?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirm')),
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

      final error = await ref.read(usersProvider.notifier).toggleBlocked(user, reason: reason);
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
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Unblock')),
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
                const Icon(Icons.group_off_rounded, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 12),
                Text('No users found', style: Theme.of(context).textTheme.titleLarge),
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
                const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 36),
                const SizedBox(height: 12),
                Text('Failed to load users', style: Theme.of(context).textTheme.titleLarge),
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
