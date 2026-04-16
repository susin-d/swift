import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/profile/growth_hub_screen.dart';
import 'package:mobile_app/services/growth_service.dart';

class _FakeGrowthService extends GrowthService {
  @override
  Future<Map<String, dynamic>> getSpendingSummary() async => {
        'summary': {
          'total_spent': 1200,
          'total_saved': 180,
          'total_orders': 8,
        },
      };

  @override
  Future<Map<String, dynamic>> getLoyaltyTier() async => {
        'loyalty': {'tier': 'gold', 'points': 820},
      };

  @override
  Future<Map<String, dynamic>> generateReferralCode() async => {
        'referral': {'code': 'SWIFT1234'},
      };

  @override
  Future<List<dynamic>> getSubscriptions() async => const [];

  @override
  Future<List<dynamic>> getRefunds() async => const [];

  @override
  Future<Map<String, dynamic>> getEntitlements() async => {
        'entitlements': {
          'delivery_fee_waiver': true,
          'priority_support': false,
          'exclusive_promos': true,
        },
      };

  @override
  Future<Map<String, dynamic>> getDeletionStatus() async => {
        'deletion': null,
      };
}

void main() {
  testWidgets('GrowthHubScreen shows summary and referral code', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrowthHubScreen(service: _FakeGrowthService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Growth Hub'), findsOneWidget);
    expect(find.textContaining('Total spent'), findsOneWidget);
    expect(find.textContaining('SWIFT1234'), findsOneWidget);
    expect(find.textContaining('Tier: gold'), findsOneWidget);
  });
}
