import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/admin_theme.dart';
import 'core/config/app_router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Swift Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.light,
      routerConfig: router,
    );
  }
}