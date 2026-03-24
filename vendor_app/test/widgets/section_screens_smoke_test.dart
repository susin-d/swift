import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/features/analytics/analytics_screen.dart';
import 'package:vendor_app/features/finance/finance_screen.dart';
import 'package:vendor_app/features/preferences/preferences_screen.dart';
import 'package:vendor_app/features/reports/reports_screen.dart';
import 'package:vendor_app/features/staff/staff_management_screen.dart';

void main() {
  testWidgets('finance screen renders section title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FinanceScreen()));
    expect(find.text('Finance & Payments'), findsAtLeastNWidgets(1));
  });

  testWidgets('analytics screen renders section title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnalyticsScreen()));
    expect(find.text('Analytics'), findsAtLeastNWidgets(1));
  });

  testWidgets('staff screen renders section title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StaffManagementScreen()));
    expect(find.text('Staff & Access Control'), findsAtLeastNWidgets(1));
  });

  testWidgets('reports screen renders section title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
    expect(find.text('Reports'), findsAtLeastNWidgets(1));
  });

  testWidgets('preferences screen renders section title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PreferencesScreen()));
    expect(find.text('Preferences'), findsAtLeastNWidgets(1));
  });
}
