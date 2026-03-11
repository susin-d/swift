import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';
import 'package:vendor_app/features/auth/login_screen.dart';
import 'package:vendor_app/features/dashboard/dashboard_screen.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';

final routerProvider = Provider((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/' : '/login',
    redirect: (context, state) {
      final loggedIn = authState.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
