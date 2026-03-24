import 'package:flutter/material.dart';
import 'package:admin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
