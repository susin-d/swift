import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';
import 'package:vendor_app/features/auth/login_screen.dart';
import 'package:vendor_app/features/dashboard/dashboard_screen.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';
import 'package:vendor_app/features/legal/legal_screen.dart';
import 'package:vendor_app/features/splash/splash_screen.dart';
import 'package:vendor_app/features/profile/vendor_profile_screen.dart';
import 'package:vendor_app/features/notifications/notifications_screen.dart';

final routerProvider = Provider((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login';
      final isSplash = loc == '/splash';
      final isPublicInfoRoute = loc == '/legal' || loc == '/privacy';
      final requested = state.uri.toString();
      final fromParam = state.uri.queryParameters['from'];
      final fromIsAuth = fromParam != null && fromParam.startsWith('/login');

      if (isSplash) return null;
      if (isPublicInfoRoute) return null;

      if (!loggedIn && !loggingIn) {
        final from = Uri.encodeComponent(requested);
        return '/login?from=$from';
      }

      if (loggedIn && loggingIn) {
        if (fromParam != null && fromParam.isNotEmpty && !fromIsAuth) {
          return fromParam;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const VendorProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalScreen(
          title: 'Vendor Terms',
          content: 'As a Swift Vendor, you agree to: 1. Quality: Maintain high food quality and hygiene standards. 2. Timeliness: Update order status promptly. 3. Transparency: Ensure menu prices match campus regulations. 4. Security: Keep your vendor credentials safe.',
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(
          title: 'Vendor Privacy Policy',
          content: 'Swift collects vendor business data, contact info, and transaction history. We use this to facilitate payments and improve the platform. 1. Transparency: Data is shared only with relevant campus units. 2. Control: You can request logs of your transactions anytime.',
        ),
      ),
    ],
  );
});
