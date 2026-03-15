import 'package:admin_app/features/settings/data/models/admin_settings.dart';
import 'package:admin_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:admin_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AdminSettings> build() async {
    return const AdminSettings(commissionRate: 12, deliveryFee: 25);
  }
}

void main() {
  testWidgets('SettingsScreen enables save after draft changes', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Decision preview'), findsOneWidget);
    expect(find.text('Current 12.0%'), findsOneWidget);
    expect(find.text('Draft 12.0%'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '14');
    await tester.pumpAndSettle();

    expect(find.text('Review before save'), findsOneWidget);
    expect(find.text('Draft 14.0%'), findsOneWidget);
  });
}