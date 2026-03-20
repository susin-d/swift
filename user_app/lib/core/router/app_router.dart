import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/menu/menu_screen.dart';
import '../../screens/menu/item_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/orders/order_tracking_screen.dart';
import '../../screens/orders/order_history_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/legal/legal_screen.dart';
import '../../screens/support/support_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/address/address_book_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/class_schedule_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(authRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/vendor/:id',
        builder: (context, state) => VendorMenuScreen(vendorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/item',
        builder: (context, state) => ItemScreen(item: state.extra),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/order-status/:id',
        builder: (context, state) => OrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressBookScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/classes',
        builder: (context, state) => const ClassScheduleScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalScreen(
          title: 'Terms of Service',
          content: 'Welcome to Swift. By using our services, you agree to follow the campus dining guidelines and our internal honor code. 1. Orders: All orders placed via the app are final. 2. Payment: Campus wallet or online payments must be cleared before delivery. 3. Delivery: Our delivery partners will reach your designated campus spot within the estimated timeframe. 4. Conduct: Respect our delivery partners and vendors. Failure to comply may lead to account suspension.',
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(
          title: 'Privacy Policy',
          content: 'Your privacy is our priority. Swift collect your name, campus email, and order history to provide a better dining experience. We do not share your personal data with third parties unless required for delivery or campus security. 1. Data Collection: We collect only necessary info. 2. Data Usage: To improve service and security. 3. Cookies: We use local storage to keep you logged in. 4. Security: We use industry-standard encryption.',
        ),
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(userProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isSplash = loc == '/splash';
      final isPublicInfoRoute = loc == '/legal' || loc == '/privacy' || loc == '/support';
      final requested = state.uri.toString();
      final fromParam = state.uri.queryParameters['from'];
      final fromIsAuth = fromParam != null && (fromParam.startsWith('/login') || fromParam.startsWith('/register'));

      // Don't redirect away from splash — it auto-navigates
      if (isSplash) return null;
      if (isPublicInfoRoute) return null;

      // Preserve protected deep-link destination for post-login navigation.
      if (user == null && !isAuthRoute) {
        final from = Uri.encodeComponent(requested);
        return '/login?from=$from';
      }

      if (user != null && isAuthRoute) {
        if (fromParam != null && fromParam.isNotEmpty && !fromIsAuth) {
          return fromParam;
        }
        return '/';
      }

      return null;
    },
  );
});
