import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart'; 
import 'package:mobile_app/core/theme/app_theme.dart';

void main() {
  group('Home Screen Widget Tests', () {
    testWidgets('Renders the core UI elements', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const CampusFoodApp());

      // Verify that the AppBar title gets rendered.
      expect(find.text('Campus Bites'), findsOneWidget);
      expect(find.text('Hungry, Student?'), findsOneWidget);

      // Verify Search TextField is rendered
      expect(find.byType(TextField), findsOneWidget);
      
      // Verify Vendor Card renders
      expect(find.text('Popular Vendors'), findsOneWidget);
      expect(find.text('Spice Route Canteen'), findsOneWidget);
    });

    testWidgets('Tapping Cart icon does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusFoodApp());

      // Find the shopping cart icon button
      final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
      expect(cartIcon, findsOneWidget);

      // Tap the cart icon
      await tester.tap(cartIcon);
      await tester.pump();
      
      // Since it's a dummy button currently, we just assert it doesn't throw.
      expect(tester.takeException(), isNull);
    });
  });
}
