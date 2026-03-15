import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/audit_log_item.dart';
import '../providers/audit_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  static const actions = [
    'all',
    'approve_vendor',
    'reject_vendor',
    'cancel_order',
    'block_user',
    'unblock_user',
    'update_user_role',
    'update_settings',
  ];

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(auditProvider);

    return auditAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _AuditError(
        message: error.toString(),
        onRetry: () => ref.read(auditProvider.notifier).refresh(),
      ),
      data: (state) {
        final filteredLogs = state.logs.where((log) => _matchesSearch(log, _searchQuery)).toList();
        final highRiskCount = state.logs.where((log) => _severityFor(log.action) == _AuditSeverity.high).length;
        final policyCount = state.logs.where((log) => log.action == 'update_settings').length;

        return RefreshIndicator(
          onRefresh: () => ref.read(auditProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DropdownButton<String>(
                            value: state.action,
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(auditProvider.notifier).applyActionFilter(value);
                              }
                            },
                            items: AuditLogsScreen.actions
                                .map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(_label(a)),
                                    ))
                                .toList(),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextField(
                              onChanged: (value) => setState(() => _searchQuery = value.trim()),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                labelText: 'Search admin, target, or action',
                              ),
                            ),
                          ),
                          Text('${filteredLogs.length} visible of ${state.total} logs'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _AuditSummaryChip(
                            label: 'High risk',
                            value: '$highRiskCount',
                            background: const Color(0xFFFEE2E2),
                            foreground: const Color(0xFFB91C1C),
                          ),
                          _AuditSummaryChip(
                            label: 'Policy changes',
                            value: '$policyCount',
                            background: const Color(0xFFE0F2FE),
                            foreground: const Color(0xFF1D4ED8),
                          ),
                          _AuditSummaryChip(
                            label: 'Current filter',
                            value: _label(state.action),
                            background: const Color(0xFFE9F7F3),
                            foreground: const Color(0xFF0F766E),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (state.logs.isEmpty)
                const _AuditEmpty()
              else if (filteredLogs.isEmpty)
                const _AuditFilteredEmpty()
              else ...[
                ...filteredLogs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AuditLogCard(log: log),
                    )),
                if (state.hasMore)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(auditProvider.notifier).loadMore(),
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

  bool _matchesSearch(AuditLogItem log, String query) {
    if (query.isEmpty) return true;

    final normalized = query.toLowerCase();
    return [log.adminId, log.targetId, log.action, _label(log.action)]
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .any((value) => value.contains(normalized));
  }

  static String _label(String raw) {
    if (raw == 'all') return 'All actions';
    return raw.split('_').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogItem log;

  @override
  Widget build(BuildContext context) {
    final severity = _severityFor(log.action);
    final badge = _severityBadge(severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _AuditLogsScreenState._label(log.action),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(color: badge.foreground, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_actionNarrative(log), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _AuditMetaPill(icon: Icons.badge_rounded, label: 'Admin ${log.adminId ?? 'N/A'}'),
                _AuditMetaPill(icon: Icons.adjust_rounded, label: 'Target ${log.targetId ?? 'N/A'}'),
                _AuditMetaPill(icon: Icons.schedule_rounded, label: _date(log.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSummaryChip extends StatelessWidget {
  const _AuditSummaryChip({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: foreground, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AuditMetaPill extends StatelessWidget {
  const _AuditMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _AuditEmpty extends StatelessWidget {
  const _AuditEmpty();

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
                const Icon(Icons.history_toggle_off_rounded, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 12),
                Text('No audit logs found', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditFilteredEmpty extends StatelessWidget {
  const _AuditFilteredEmpty();

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
                const Icon(Icons.filter_alt_off_rounded, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 12),
                Text('No audit logs match the current search', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditError extends StatelessWidget {
  const _AuditError({required this.message, required this.onRetry});

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
                Text('Failed to load audit logs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
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
  return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
}

enum _AuditSeverity { low, medium, high }

_AuditSeverity _severityFor(String action) {
  switch (action) {
    case 'block_user':
    case 'reject_vendor':
    case 'cancel_order':
      return _AuditSeverity.high;
    case 'update_user_role':
    case 'update_settings':
      return _AuditSeverity.medium;
    default:
      return _AuditSeverity.low;
  }
}

({String label, Color background, Color foreground}) _severityBadge(_AuditSeverity severity) {
  switch (severity) {
    case _AuditSeverity.high:
      return (
        label: 'High risk',
        background: const Color(0xFFFEE2E2),
        foreground: const Color(0xFFB91C1C),
      );
    case _AuditSeverity.medium:
      return (
        label: 'Review',
        background: const Color(0xFFFFF7E8),
        foreground: const Color(0xFF9A6200),
      );
    case _AuditSeverity.low:
      return (
        label: 'Routine',
        background: const Color(0xFFE9F7F3),
        foreground: const Color(0xFF0F766E),
      );
  }
}

String _actionNarrative(AuditLogItem log) {
  switch (log.action) {
    case 'approve_vendor':
      return 'Vendor onboarding decision completed and ready for downstream operations.';
    case 'reject_vendor':
      return 'Vendor approval path was blocked and should be checked for follow-up communication.';
    case 'cancel_order':
      return 'Order escalation ended in cancellation and may need refund or SLA review.';
    case 'block_user':
      return 'A user access restriction was applied. Confirm the moderation rationale if this was unexpected.';
    case 'unblock_user':
      return 'User access was restored after review.';
    case 'update_user_role':
      return 'Role permissions changed. Verify the affected admin or vendor retains only intended access.';
    case 'update_settings':
      return 'Platform policy values changed. Monitor commission and delivery fee impact after this change.';
    default:
      return 'Administrative action recorded for traceability.';
  }
}
