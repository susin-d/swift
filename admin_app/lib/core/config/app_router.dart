import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit/presentation/screens/audit_logs_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/vendors/presentation/screens/vendors_screen.dart';
import '../../shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      final goingToLogin = state.matchedLocation == '/login';
      final requested = state.uri.toString();
      final fromParam = state.uri.queryParameters['from'];
      final fromIsLogin = fromParam != null && fromParam.startsWith('/login');

      if (isLoading) return null;
      if (!isAuthenticated && !goingToLogin) {
        final from = Uri.encodeComponent(requested);
        return '/login?from=$from';
      }
      if (isAuthenticated && goingToLogin) {
        if (fromParam != null && fromParam.isNotEmpty && !fromIsLogin) {
          return fromParam;
        }
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final index = _indexForPath(state.matchedLocation);
          return AppShell(
            title: _titleForIndex(index),
            subtitle: _subtitleForIndex(index),
            selectedIndex: index,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardBody(),
          ),
          GoRoute(
            path: '/vendors',
            builder: (_, __) => const VendorsScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (_, __) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/audit',
            builder: (_, __) => const AuditLogsScreen(),
          ),
        ],
      ),
    ],
  );
});

int _indexForPath(String path) {
  if (path.startsWith('/vendors')) return 1;
  if (path.startsWith('/orders')) return 2;
  if (path.startsWith('/users')) return 3;
  if (path.startsWith('/finance')) return 4;
  if (path.startsWith('/settings')) return 5;
  if (path.startsWith('/audit')) return 6;
  return 0;
}

String _titleForIndex(int i) => const [
      'Dashboard',
      'Vendors',
      'Orders',
      'Users',
      'Finance',
  'Settings',
  'Audit Logs',
    ][i];

String _subtitleForIndex(int i) => const [
      'Platform health, vendor quality, and revenue in one place.',
      'Manage vendor accounts and approve new applications.',
      'Monitor live orders and resolve escalations.',
      'Manage user accounts, roles, and access.',
      'Revenue, payouts, and financial reporting.',
  'Commission, delivery fee, and platform controls.',
  'Read-only timeline of administrator actions.',
    ][i];
