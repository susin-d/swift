import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'staff_providers.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Staff & Access Control',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StaffTile(
            title: 'Staff Management',
            subtitle: 'Invite, suspend, and manage kitchen and cashier staff.',
            icon: Icons.groups_rounded,
            onTap: () => context.push('/staff/management'),
          ),
          _StaffTile(
            title: 'Roles & Permissions',
            subtitle: 'Control action-level permissions for operational safety.',
            icon: Icons.admin_panel_settings_rounded,
            onTap: () => context.push('/staff/roles'),
          ),
        ],
      ),
    );
  }
}

class StaffManagementDetailScreen extends ConsumerStatefulWidget {
  const StaffManagementDetailScreen({super.key});

  @override
  ConsumerState<StaffManagementDetailScreen> createState() => _StaffManagementDetailScreenState();
}

class _StaffManagementDetailScreenState extends ConsumerState<StaffManagementDetailScreen> {
  bool _busy = false;

  Future<void> _createStaff() async {
    final result = await _openStaffEditDialog(context);
    if (result == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(staffServiceProvider).createStaffMember(
            name: result.name,
            roleKey: result.roleKey,
            status: result.status,
            email: result.email,
            phone: result.phone,
          );
      ref.invalidate(staffManagementProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff member created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create staff member: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _inviteStaff() async {
    final result = await _openStaffInviteDialog(context);
    if (result == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(staffServiceProvider).inviteStaff(
            email: result.email,
            roleKey: result.roleKey,
            expiresInDays: result.expiresInDays,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invite staff: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _editStaff(Map<String, dynamic> row) async {
    final result = await _openStaffEditDialog(context, initial: row);
    if (result == null) return;
    final staffId = (row['id'] ?? '').toString();
    if (staffId.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(staffServiceProvider).updateStaffMember(
            staffId: staffId,
            name: result.name,
            roleKey: result.roleKey,
            status: result.status,
            email: result.email,
            phone: result.phone,
          );
      ref.invalidate(staffManagementProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff member updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update staff member: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteStaff(Map<String, dynamic> row) async {
    final staffId = (row['id'] ?? '').toString();
    if (staffId.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Staff Member'),
            content: Text('Remove ${(row['name'] ?? 'this staff member')} from staff list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() => _busy = true);
    try {
      await ref.read(staffServiceProvider).deleteStaffMember(staffId);
      ref.invalidate(staffManagementProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff member deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete staff member: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffManagementProvider);
    return _StaffDetailScaffold(
      title: 'Staff Management',
      child: staffAsync.when(
        data: (rows) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _inviteStaff,
                    icon: const Icon(Icons.mark_email_unread_rounded),
                    label: const Text('Invite Staff'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _createStaff,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add Staff'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StaffRows(
              rows: rows,
              onEdit: _busy ? null : _editStaff,
              onDelete: _busy ? null : _deleteStaff,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load staff management: $e')),
      ),
    );
  }
}

class StaffRolesScreen extends ConsumerStatefulWidget {
  const StaffRolesScreen({super.key});

  @override
  ConsumerState<StaffRolesScreen> createState() => _StaffRolesScreenState();
}

class _StaffRolesScreenState extends ConsumerState<StaffRolesScreen> {
  bool _busy = false;

  Future<void> _upsertRole(List<dynamic> currentRoles, {Map<String, dynamic>? initial}) async {
    final nextRole = await _openRoleDialog(context, initial: initial);
    if (nextRole == null) return;

    final normalized = currentRoles
        .map((entry) => (entry as Map).cast<String, dynamic>())
        .where((entry) => (entry['key'] ?? '').toString().trim().isNotEmpty)
        .toList();

    final withoutSameKey = normalized.where((entry) => entry['key'] != nextRole['key']).toList();
    final payload = [...withoutSameKey, nextRole];

    setState(() => _busy = true);
    try {
      await ref.read(staffServiceProvider).updateRoles(payload);
      ref.invalidate(staffRolesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role definitions updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role definitions: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(staffRolesProvider);
    return _StaffDetailScaffold(
      title: 'Roles & Permissions',
      child: rolesAsync.when(
        data: (rows) => Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _upsertRole(rows),
                icon: const Icon(Icons.add_moderator_rounded),
                label: const Text('Add Role'),
              ),
            ),
            const SizedBox(height: 12),
            _StaffRows(
              rows: rows,
              onEdit: _busy
                  ? null
                  : (row) {
                      _upsertRole(rows, initial: row);
                    },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load roles: $e')),
      ),
    );
  }
}

class _StaffDetailScaffold extends StatelessWidget {
  const _StaffDetailScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [child],
      ),
    );
  }
}

class _StaffRows extends StatelessWidget {
  const _StaffRows({
    required this.rows,
    this.onEdit,
    this.onDelete,
  });

  final List<dynamic> rows;
  final void Function(Map<String, dynamic> row)? onEdit;
  final void Function(Map<String, dynamic> row)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No records found.');
    return Column(
      children: rows
          .map(
            (entry) {
              final row = (entry as Map).cast<String, dynamic>();
              final title = (row['name'] ?? row['key'] ?? 'Record').toString();
              final detailText = row.entries
                  .where((e) => e.key != 'permissions')
                  .map((e) => '${e.key}: ${e.value}')
                  .take(3)
                  .join(' | ');

              final permissions = (row['permissions'] as List?)?.cast<dynamic>() ?? const [];
              final permissionText = permissions.take(3).map((e) => e.toString()).join(', ');

              return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.verified_user_rounded),
                title: Text(title),
                subtitle: Text(
                  permissions.isEmpty ? detailText : '$detailText | permissions: $permissionText',
                ),
                trailing: (onEdit == null && onDelete == null)
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!(row);
                          }
                          if (value == 'delete' && onDelete != null) {
                            onDelete!(row);
                          }
                        },
                        itemBuilder: (_) => [
                          if (onEdit != null)
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                        ],
                      ),
              ),
            );
            },
          )
          .toList(),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal.shade600),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _StaffEditResult {
  const _StaffEditResult({
    required this.name,
    required this.roleKey,
    required this.status,
    this.email,
    this.phone,
  });

  final String name;
  final String roleKey;
  final String status;
  final String? email;
  final String? phone;
}

class _StaffInviteResult {
  const _StaffInviteResult({
    required this.email,
    required this.roleKey,
    required this.expiresInDays,
  });

  final String email;
  final String roleKey;
  final int expiresInDays;
}

Future<_StaffEditResult?> _openStaffEditDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final nameController = TextEditingController(text: (initial?['name'] ?? '').toString());
  final roleController = TextEditingController(text: (initial?['role_key'] ?? 'cashier').toString());
  final emailController = TextEditingController(text: (initial?['email'] ?? '').toString());
  final phoneController = TextEditingController(text: (initial?['phone'] ?? '').toString());
  String status = (initial?['status'] ?? 'active').toString();

  return showDialog<_StaffEditResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(initial == null ? 'Add Staff Member' : 'Edit Staff Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role Key (manager/cashier/kitchen)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => status = value);
                },
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                ],
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              if (name.isEmpty || role.isEmpty) return;
              Navigator.of(dialogContext).pop(
                _StaffEditResult(
                  name: name,
                  roleKey: role,
                  status: status,
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<_StaffInviteResult?> _openStaffInviteDialog(BuildContext context) async {
  final emailController = TextEditingController();
  final roleController = TextEditingController(text: 'cashier');
  final expiryController = TextEditingController(text: '7');

  return showDialog<_StaffInviteResult>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Invite Staff Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role Key'),
            ),
            TextField(
              controller: expiryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Expires in Days'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final email = emailController.text.trim();
            final role = roleController.text.trim();
            final days = int.tryParse(expiryController.text.trim()) ?? 7;
            if (email.isEmpty || role.isEmpty) return;
            Navigator.of(dialogContext).pop(
              _StaffInviteResult(email: email, roleKey: role, expiresInDays: days),
            );
          },
          child: const Text('Send Invite'),
        ),
      ],
    ),
  );
}

Future<Map<String, dynamic>?> _openRoleDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final keyController = TextEditingController(text: (initial?['key'] ?? '').toString());
  final permissionController = TextEditingController(
    text: ((initial?['permissions'] as List?) ?? const []).map((e) => e.toString()).join(', '),
  );

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(initial == null ? 'Add Role' : 'Edit Role'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Role Key'),
            ),
            TextField(
              controller: permissionController,
              decoration: const InputDecoration(
                labelText: 'Permissions (comma separated)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final key = keyController.text.trim();
            if (key.isEmpty) return;
            final permissions = permissionController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            Navigator.of(dialogContext).pop({'key': key, 'permissions': permissions});
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
