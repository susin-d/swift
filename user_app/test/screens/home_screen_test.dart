import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Smoke Tests', () {
    testWidgets('Basic scaffold renders expected text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Swift User App'),
          ),
        ),
      );

      expect(find.text('Swift User App'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Icon button tap does not throw', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pump();

      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
