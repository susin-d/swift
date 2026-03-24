import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/features/sidebar/sidebar_feature_screen.dart';

void main() {
  testWidgets('renders sidebar feature placeholder metadata', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SidebarFeatureScreen(
          title: 'Order History',
          section: 'Core Navigation',
        ),
      ),
    );

    expect(find.text('Order History'), findsAtLeastNWidgets(1));
    expect(
      find.textContaining('Core Navigation module is now added in the sidebar'),
      findsOneWidget,
    );
  });
}
