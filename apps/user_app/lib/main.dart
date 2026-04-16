import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/router/app_router.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/services/device_token_service.dart';
import 'package:mobile_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvironment();

  runApp(
    const ProviderScope(
      child: CampusFoodApp(),
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

class CampusFoodApp extends ConsumerStatefulWidget {
  const CampusFoodApp({super.key});

  @override
  ConsumerState<CampusFoodApp> createState() => _CampusFoodAppState();
}

class _CampusFoodAppState extends ConsumerState<CampusFoodApp> {
  bool _registeredToken = false;
  ProviderSubscription<Map<String, dynamic>?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _userSubscription = ref.listenManual<Map<String, dynamic>?>(userProvider, (previous, next) async {
      if (next != null && !_registeredToken) {
        await _registerDeviceToken();
      }
      if (next == null) {
        _registeredToken = false;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _userSubscription?.close();
    super.dispose();
  }

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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Swift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
