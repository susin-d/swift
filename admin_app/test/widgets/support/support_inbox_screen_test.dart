import 'package:admin_app/features/support/presentation/screens/support_inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SupportInboxScreen renders ticket row from loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SupportInboxScreen(
          loadTicketsOverride: () async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'ticket-1',
              'subject': 'Missing item',
              'description': 'Drink was missing',
              'status': 'open',
              'priority': 'high',
            },
          ],
          updateTicketOverride: (_, __) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missing item'), findsOneWidget);
    expect(find.textContaining('Status: OPEN'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
