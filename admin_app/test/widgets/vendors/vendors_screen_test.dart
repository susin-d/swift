import 'package:admin_app/features/vendors/data/models/vendor_item.dart';
import 'package:admin_app/features/vendors/presentation/providers/vendors_provider.dart';
import 'package:admin_app/features/vendors/presentation/screens/vendors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVendorsNotifier extends VendorsNotifier {
  static String? lastApprovedId;
  static String? lastRejectedId;
  static String? lastRejectReason;
  static List<String>? lastApprovedBulkIds;
  static List<String>? lastRejectedBulkIds;
  static String? lastRejectedBulkReason;

  @override
  Future<List<VendorItem>> build() async {
    return const [
      VendorItem(
        id: 'vendor-1',
        name: 'Campus Bites',
        description: 'Fresh meals daily.',
        imageUrl: null,
        isOpen: true,
        createdAt: null,
        ownerName: 'Riya Owner',
        ownerEmail: 'riya@example.com',
      ),
    ];
  }

  @override
  Future<String?> approve(String vendorId) async {
    lastApprovedId = vendorId;
    return null;
  }

  @override
  Future<String?> reject(String vendorId, {required String reason}) async {
    lastRejectedId = vendorId;
    lastRejectReason = reason;
    return null;
  }

  @override
  Future<VendorBulkActionResult> approveMany(List<String> vendorIds) async {
    lastApprovedBulkIds = List<String>.from(vendorIds);
    return VendorBulkActionResult(successCount: vendorIds.length, errors: const {});
  }

  @override
  Future<VendorBulkActionResult> rejectMany(List<String> vendorIds, {required String reason}) async {
    lastRejectedBulkIds = List<String>.from(vendorIds);
    lastRejectedBulkReason = reason;
    return VendorBulkActionResult(successCount: vendorIds.length, errors: const {});
  }
}

void _resetFakeVendorNotifier() {
  _FakeVendorsNotifier.lastApprovedId = null;
  _FakeVendorsNotifier.lastRejectedId = null;
  _FakeVendorsNotifier.lastRejectReason = null;
  _FakeVendorsNotifier.lastApprovedBulkIds = null;
  _FakeVendorsNotifier.lastRejectedBulkIds = null;
  _FakeVendorsNotifier.lastRejectedBulkReason = null;
}

void main() {
  testWidgets('VendorsScreen opens vendor details panel', (tester) async {
    _resetFakeVendorNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorsProvider.overrideWith(_FakeVendorsNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Details').first);
    await tester.pumpAndSettle();

    expect(find.text('Owner email'), findsOneWidget);
    expect(find.text('riya@example.com'), findsWidgets);
  });

  testWidgets('VendorsScreen approve action confirms and calls notifier', (
    tester,
  ) async {
    _resetFakeVendorNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorsProvider.overrideWith(_FakeVendorsNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();

    expect(find.text('Approve vendor'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pumpAndSettle();

    expect(_FakeVendorsNotifier.lastApprovedId, 'vendor-1');
    expect(find.textContaining('approved successfully'), findsOneWidget);
  });

  testWidgets(
    'VendorsScreen reject action captures reason and calls notifier',
    (tester) async {
      _resetFakeVendorNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vendorsProvider.overrideWith(_FakeVendorsNotifier.new)],
          child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject').first);
      await tester.pumpAndSettle();

      expect(find.text('Reject vendor'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'Vendor submitted incomplete compliance docs.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Reject').last);
      await tester.pumpAndSettle();

      expect(_FakeVendorsNotifier.lastRejectedId, 'vendor-1');
      expect(_FakeVendorsNotifier.lastRejectReason, isNotNull);
      expect(_FakeVendorsNotifier.lastRejectReason!, contains('compliance'));
    },
  );

  testWidgets('VendorsScreen bulk approve selected vendors', (tester) async {
    _resetFakeVendorNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorsProvider.overrideWith(_FakeVendorsNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all visible').first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Approve selected').first);
    await tester.pumpAndSettle();

    expect(find.text('Approve selected vendors'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve all').first);
    await tester.pumpAndSettle();

    expect(_FakeVendorsNotifier.lastApprovedBulkIds, isNotNull);
    expect(_FakeVendorsNotifier.lastApprovedBulkIds, contains('vendor-1'));
    expect(find.textContaining('approved successfully'), findsOneWidget);
  });

  testWidgets('VendorsScreen bulk reject selected vendors captures reason', (tester) async {
    _resetFakeVendorNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorsProvider.overrideWith(_FakeVendorsNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all visible').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject selected').first);
    await tester.pumpAndSettle();

    expect(find.text('Reject selected vendors'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'Bulk reject due to failed compliance verification documents.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Reject all').first);
    await tester.pumpAndSettle();

    expect(_FakeVendorsNotifier.lastRejectedBulkIds, isNotNull);
    expect(_FakeVendorsNotifier.lastRejectedBulkIds, contains('vendor-1'));
    expect(_FakeVendorsNotifier.lastRejectedBulkReason, isNotNull);
    expect(_FakeVendorsNotifier.lastRejectedBulkReason!, contains('compliance'));
    expect(find.textContaining('rejected successfully'), findsOneWidget);
  });
}
