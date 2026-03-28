import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/support/support_screen.dart';
import 'package:mobile_app/services/support_service.dart';

class _FakeSupportGateway implements SupportTicketGateway {
  _FakeSupportGateway();
  String? capturedSubject;
  String? capturedDescription;
  String? capturedPriority;
  String? capturedOrderId;

  @override
  Future<String?> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? orderId,
  }) async {
    capturedSubject = subject;
    capturedDescription = description;
    capturedPriority = priority;
    capturedOrderId = orderId;
    return 'ticket_demo_123';
  }
}

void main() {
  testWidgets('email option launches mailto support channel', (tester) async {
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SupportScreen(
          uriLauncher: (uri) async {
            launchedUris.add(uri);
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Email Us'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(1));
    expect(launchedUris.first.scheme, 'mailto');
    expect(launchedUris.first.path, 'support@swift.campus.edu');
  });

  testWidgets('faq option opens bottom sheet with answers', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));

    await tester.tap(find.text('FAQs'));
    await tester.pumpAndSettle();

    expect(find.text('FAQ Center'), findsOneWidget);
    expect(find.text('How long does delivery take?'), findsOneWidget);
  });

  testWidgets('failed channel launch shows a snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SupportScreen(uriLauncher: (_) async => false)),
    );

    await tester.ensureVisible(find.text('Call Us'));
    await tester.tap(find.text('Call Us'));
    await tester.pump();

    expect(find.text('Unable to open phone dialer right now.'), findsOneWidget);
  });

  testWidgets('submit ticket sends payload to backend gateway', (tester) async {
    final gateway = _FakeSupportGateway();

    await tester.pumpWidget(
      MaterialApp(home: SupportScreen(supportGateway: gateway)),
    );

    await tester.tap(find.text('Submit Ticket'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Missing item');
    await tester.enterText(
      find.byType(TextField).at(1),
      'I did not receive one of my ordered items.',
    );
    await tester.enterText(find.byType(TextField).at(2), 'order_123');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(gateway.capturedSubject, 'Missing item');
    expect(gateway.capturedPriority, 'normal');
    expect(gateway.capturedOrderId, 'order_123');
    expect(find.textContaining('ticket_demo_123'), findsOneWidget);
  });
}
