import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/features/sidebar/sidebar_feature_screen.dart';

void main() {
  testWidgets('renders feature workspace with checklist and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SidebarFeatureScreen(
          title: 'Order History',
          section: 'Core Navigation',
        ),
      ),
    );

    expect(find.text('Order History'), findsAtLeastNWidgets(1));
    expect(find.text('Readiness Checklist'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Filter by date'), findsOneWidget);
    expect(find.text('Save note', skipOffstage: false), findsOneWidget);
  });
}
