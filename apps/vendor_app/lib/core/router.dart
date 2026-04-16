import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';
import 'package:vendor_app/features/auth/forgot_password_screen.dart';
import 'package:vendor_app/features/auth/login_screen.dart';
import 'package:vendor_app/features/dashboard/dashboard_screen.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';
import 'package:vendor_app/features/legal/legal_screen.dart';
import 'package:vendor_app/features/splash/splash_screen.dart';
import 'package:vendor_app/features/profile/vendor_profile_screen.dart';
import 'package:vendor_app/features/notifications/notifications_screen.dart';
import 'package:vendor_app/features/sidebar/sidebar_feature_screen.dart';
import 'package:vendor_app/features/finance/finance_screen.dart';
import 'package:vendor_app/features/analytics/analytics_screen.dart';
import 'package:vendor_app/features/staff/staff_management_screen.dart';
import 'package:vendor_app/features/reports/reports_screen.dart';
import 'package:vendor_app/features/preferences/preferences_screen.dart';
import 'package:vendor_app/features/auth/register_screen.dart';

final routerProvider = Provider((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/forgot-password';
      final isSplash = loc == '/splash';
      final isPublicInfoRoute = loc == '/legal' || loc == '/privacy';
      final requested = state.uri.toString();
      final fromParam = state.uri.queryParameters['from'];
      final fromIsAuth = fromParam != null && (fromParam.startsWith('/login') || fromParam.startsWith('/forgot-password'));

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
        path: '/finance',
        builder: (context, state) => const FinanceScreen(),
      ),
      GoRoute(
        path: '/finance/earnings',
        builder: (context, state) => const FinanceEarningsScreen(),
      ),
      GoRoute(
        path: '/finance/payouts',
        builder: (context, state) => const FinancePayoutsScreen(),
      ),
      GoRoute(
        path: '/finance/transactions',
        builder: (context, state) => const FinanceTransactionsScreen(),
      ),
      GoRoute(
        path: '/finance/tax-reports',
        builder: (context, state) => const FinanceTaxReportsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/sales',
        builder: (context, state) => const SalesAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/performance',
        builder: (context, state) => const PerformanceMetricsScreen(),
      ),
      GoRoute(
        path: '/analytics/peak-hours',
        builder: (context, state) => const PeakHoursInsightsScreen(),
      ),
      GoRoute(
        path: '/analytics/top-items',
        builder: (context, state) => const TopSellingItemsScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: '/staff/management',
        builder: (context, state) => const StaffManagementDetailScreen(),
      ),
      GoRoute(
        path: '/staff/roles',
        builder: (context, state) => const StaffRolesScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/reports/download',
        builder: (context, state) => const DownloadReportsScreen(),
      ),
      GoRoute(
        path: '/reports/sales',
        builder: (context, state) => const SalesReportsScreen(),
      ),
      GoRoute(
        path: '/reports/orders',
        builder: (context, state) => const OrderReportsScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/preferences/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/preferences/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/preferences/app',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
      GoRoute(
        path: '/feature',
        builder: (context, state) => SidebarFeatureScreen(
          title: state.uri.queryParameters['title'] ?? 'Feature',
          section: state.uri.queryParameters['section'] ?? 'Vendor',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
});
