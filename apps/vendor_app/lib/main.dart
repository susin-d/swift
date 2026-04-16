import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/router.dart';
import 'package:vendor_app/core/vendor_theme.dart';
import 'package:vendor_app/core/device_token_service.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';
import 'package:vendor_app/features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvironment();

  runApp(
    const ProviderScope(
      child: VendorApp(),
    ),
  );
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env');
  } catch (_) {
    // Use runtime defaults when no .env file is bundled.
  }
}

class VendorApp extends ConsumerStatefulWidget {
  const VendorApp({super.key});

  @override
  ConsumerState<VendorApp> createState() => _VendorAppState();
}

class _VendorAppState extends ConsumerState<VendorApp> {
  bool _registeredToken = false;

  Future<void> _registerDeviceToken() async {
    try {
      final token = await DeviceTokenService().getOrCreateToken();
      await NotificationService().registerDeviceToken(token, platform: _platformLabel());
      if (mounted) {
        setState(() => _registeredToken = true);
      }
    } catch (_) {}
  }

  String _platformLabel() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next.isAuthenticated && !_registeredToken) {
        await _registerDeviceToken();
      }
      if (!next.isAuthenticated) {
        _registeredToken = false;
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vendor Swift',
      debugShowCheckedModeBanner: false,
      theme: VendorTheme.light,
      routerConfig: router,
    );
  }
}
