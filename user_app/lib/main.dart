import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/router/app_router.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/device_token_service.dart';
import 'package:mobile_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  
  await Supabase.initialize(
    url: 'https://ncknhkowypkjvzleyaar.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.7hiYPKG0YYqG2gQdEAOOXspuuqX4b8jw8GhsSSlIygQ',
  );

  runApp(
    const ProviderScope(
      child: CampusFoodApp(),
    ),
  );
}

class CampusFoodApp extends ConsumerStatefulWidget {
  const CampusFoodApp({super.key});

  @override
  ConsumerState<CampusFoodApp> createState() => _CampusFoodAppState();
}

class _CampusFoodAppState extends ConsumerState<CampusFoodApp> {
  bool _registeredToken = false;
  ProviderSubscription<User?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _userSubscription = ref.listenManual<User?>(userProvider, (previous, next) async {
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
