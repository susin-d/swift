import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VendorApp(),
    ),
  );
}

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Swift Vendor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
        ),
      ),
      routerConfig: router,
    );
  }
}
