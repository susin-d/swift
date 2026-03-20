import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/session_posture_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    this.subtitle,
    this.selectedIndex = 0,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = _navigationItems;
    final sessionPosture = ref.watch(sessionPostureProvider);

    return Scaffold(
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          if (!compact) return const SizedBox.shrink();

          final compactIndex = selectedIndex <= 2 ? selectedIndex : 3;

          return NavigationBar(
            selectedIndex: compactIndex,
            onDestinationSelected: (idx) async {
              if (idx <= 2) {
                context.go(navItems[idx].route);
                return;
              }

              final choice = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (sheetContext) {
                  return SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in navItems.skip(3))
                          ListTile(
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            onTap: () => Navigator.of(sheetContext).pop(item.route),
                          ),
                        const Divider(height: 8),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Sign out'),
                          onTap: () => Navigator.of(sheetContext).pop('__logout__'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (!context.mounted || choice == null) return;
              if (choice == '__logout__') {
                await ref.read(authProvider.notifier).logout();
                return;
              }
              context.go(choice);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_rounded),
                label: 'Vendors',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                label: 'More',
              ),
            ],
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          return Row(
            children: [
              if (!compact) _Sidebar(selectedIndex: selectedIndex, ref: ref),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: title,
                      subtitle: subtitle,
                      compact: compact,
                      posture: sessionPosture,
                    ),
                    if (sessionPosture.hasValue &&
                        sessionPosture.value!.isAuthenticated &&
                        !sessionPosture.value!.isTrusted)
                      _SessionPostureBanner(
                        detail: sessionPosture.value!.detail,
                        onTrustDevice: () async {
                          await ref.read(sessionPostureProvider.notifier).markTrusted();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This device is now marked as trusted.')),
                          );
                        },
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.ref});

  final int selectedIndex;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFF102A2A),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF169B8E), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F766E)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Swift Control',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Operations cockpit',
                        style: TextStyle(color: Color(0xFFCCF5EF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            _navigationItems.length,
            (i) => _SidebarItem(
              icon: _navigationItems[i].icon,
              label: _navigationItems[i].label,
              route: _navigationItems[i].route,
              active: selectedIndex == i,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(authProvider.notifier).logout(),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF173838),
                border: Border.all(color: const Color(0xFF295151)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFF8FB8B2), size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFF8FB8B2),
                      fontWeight: FontWeight.w600,
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: active ? const Color(0xFF1B4A47) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: active ? Colors.white : const Color(0xFF93B5B0)),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF93B5B0),
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        onTap: () => context.go(route),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.posture,
  });

  final String title;
  final String? subtitle;
  final bool compact;
  final AsyncValue<SessionPosture> posture;

  @override
  Widget build(BuildContext context) {
    final postureLabel = posture.when(
      data: (value) => value.statusLabel,
      loading: () => 'Checking posture',
      error: (_, __) => 'Posture unknown',
    );
    final postureTrusted = posture.when(
      data: (value) => value.isTrusted,
      loading: () => false,
      error: (_, __) => false,
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      child: Container(
        height: compact ? 92 : 96,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (!compact)
              Container(
                width: 260,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: Color(0xFF6A8180)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search users, vendors, orders',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF6A8180)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: postureTrusted ? const Color(0xFFE8F7F4) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    postureTrusted ? Icons.verified_user_rounded : Icons.shield_outlined,
                    color: postureTrusted ? const Color(0xFF0F766E) : const Color(0xFFAD6800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    postureLabel,
                    style: TextStyle(
                      color: postureTrusted ? const Color(0xFF0F766E) : const Color(0xFFAD6800),
                      fontWeight: FontWeight.w700,
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

class _SessionPostureBanner extends StatelessWidget {
  const _SessionPostureBanner({required this.detail, required this.onTrustDevice});

  final String detail;
  final Future<void> Function() onTrustDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD58A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.security_update_warning_rounded, color: Color(0xFFAD6800), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF734A00),
                    height: 1.3,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: () {
              onTrustDevice();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFE6B3),
              foregroundColor: const Color(0xFF734A00),
            ),
            child: const Text('Trust this device'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}

const _navigationItems = <_NavItem>[
  _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/dashboard'),
  _NavItem(icon: Icons.storefront_rounded, label: 'Vendors', route: '/vendors'),
  _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', route: '/orders'),
  _NavItem(icon: Icons.location_city_rounded, label: 'Campus', route: '/campus'),
  _NavItem(icon: Icons.group_rounded, label: 'Users', route: '/users'),
  _NavItem(icon: Icons.payments_rounded, label: 'Finance', route: '/finance'),
  _NavItem(icon: Icons.local_offer_rounded, label: 'Promos', route: '/promos'),
  _NavItem(icon: Icons.tune_rounded, label: 'Settings', route: '/settings'),
  _NavItem(icon: Icons.history_rounded, label: 'Audit Logs', route: '/audit'),
];
