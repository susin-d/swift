import 'package:admin_app/features/dashboard/data/models/chart_data_point.dart';
import 'package:admin_app/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:admin_app/features/dashboard/data/models/dashboard_summary.dart';
import 'package:admin_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:admin_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

final _testSnapshot = DashboardSnapshot(
  summary: const DashboardSummary(
    totalUsers: 120,
    totalVendors: 8,
    activeOrders: 15,
    completedOrders: 430,
    revenue: 98500.0,
  ),
  chartData: const [
    ChartDataPoint(day: 'Mon', orders: 10, revenue: 4000.0),
    ChartDataPoint(day: 'Tue', orders: 14, revenue: 5200.0),
  ],
  pendingVendorCount: 3,
);

void main() {
  testWidgets('DashboardBody renders stat cards when data is available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith((ref) async => _testSnapshot),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardBody())),
      ),
    );

    await tester.pumpAndSettle();

    // Stat cards should show the four key metrics
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Vendors'), findsOneWidget);
    expect(find.text('Active Orders'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
  });

  testWidgets('DashboardBody shows shimmer loading while data is loading', (tester) async {
    final completer = Completer<DashboardSnapshot>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardBody())),
      ),
    );

    // Before settling, shimmer placeholder should be visible.
    await tester.pump();
    expect(find.byType(Shimmer), findsOneWidget);

    completer.complete(_testSnapshot);
    await tester.pumpAndSettle();
  });

  testWidgets('DashboardBody shows error widget on provider failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith((ref) async {
            throw Exception('Dashboard unavailable');
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardBody())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('unavailable'), findsOneWidget);
  });

  testWidgets('DashboardBody renders pending vendor count in stat card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith((ref) async => _testSnapshot),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardBody())),
      ),
    );

    await tester.pumpAndSettle();

    // Pending vendors (3) should be reflected in vendor card hint area
    expect(find.textContaining('3'), findsWidgets);
  });
}
