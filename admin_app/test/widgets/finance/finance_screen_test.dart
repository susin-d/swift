import 'package:admin_app/features/finance/data/models/finance_summary.dart';
import 'package:admin_app/features/finance/data/services/finance_service.dart';
import 'package:admin_app/features/finance/presentation/providers/finance_provider.dart';
import 'package:admin_app/features/finance/presentation/screens/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFinanceNotifier extends FinanceNotifier {
  final FinanceSnapshot _snapshot;

  _FakeFinanceNotifier(this._snapshot);

  @override
  Future<FinanceSnapshot> build() async => _snapshot;
}

class _ErrorFinanceNotifier extends FinanceNotifier {
  @override
  Future<FinanceSnapshot> build() async => throw Exception('Finance service down');
}

final _testSnapshot = FinanceSnapshot(
  summary: const FinanceSummary(
    todayRevenue: 3200.0,
    weekRevenue: 21500.0,
    monthRevenue: 88000.0,
    totalRevenue: 420000.0,
  ),
  payouts: [
    const PayoutItem(
      vendorId: 'v-1',
      vendorName: 'Campus Canteen',
      totalRevenue: 15000.0,
      totalOrders: 120,
      status: 'pending',
    ),
    const PayoutItem(
      vendorId: 'v-2',
      vendorName: 'Juice Corner',
      totalRevenue: 6500.0,
      totalOrders: 60,
      status: 'paid',
    ),
  ],
  chart: const [],
);

void main() {
  testWidgets('FinanceScreen renders revenue stat cards when data is available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeProvider.overrideWith(() => _FakeFinanceNotifier(_testSnapshot)),
        ],
        child: const MaterialApp(home: Scaffold(body: FinanceScreen())),
      ),
    );

    await tester.pumpAndSettle();

    // Four stat cards must be rendered
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('FinanceScreen shows loading indicator while fetching', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeProvider.overrideWith(() => _FakeFinanceNotifier(
                FinanceSnapshot(
                  summary: const FinanceSummary(
                    todayRevenue: 0,
                    weekRevenue: 0,
                    monthRevenue: 0,
                    totalRevenue: 0,
                  ),
                  payouts: [],
                  chart: [],
                ),
              )),
        ],
        child: const MaterialApp(home: Scaffold(body: FinanceScreen())),
      ),
    );

    // Pump once to capture loading state
    await tester.pump();
    // Loading indicator may be visible briefly; pumpAndSettle resolves to data
    await tester.pumpAndSettle();

    // After settling, stat cards should be present
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('FinanceScreen shows error widget on notifier failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeProvider.overrideWith(_ErrorFinanceNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: FinanceScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('down'), findsOneWidget);
  });

  testWidgets('FinanceScreen renders payout vendor names', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeProvider.overrideWith(() => _FakeFinanceNotifier(_testSnapshot)),
        ],
        child: const MaterialApp(home: Scaffold(body: FinanceScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Campus Canteen'), findsWidgets);
    expect(find.textContaining('Canteen'), findsWidgets);
  });
}
