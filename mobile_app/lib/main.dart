import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

class CampusFoodApp extends ConsumerWidget {
  const CampusFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Swift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
