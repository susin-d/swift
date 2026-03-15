import 'package:admin_app/features/audit/data/models/audit_log_item.dart';
import 'package:admin_app/features/audit/presentation/providers/audit_provider.dart';
import 'package:admin_app/features/audit/presentation/screens/audit_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuditNotifier extends AuditNotifier {
  @override
  Future<AuditState> build() async {
    return AuditState(
      logs: const [
        AuditLogItem(
          id: '1',
          adminId: 'admin-1',
          action: 'block_user',
          targetId: 'user-1',
          createdAt: null,
        ),
        AuditLogItem(
          id: '2',
          adminId: 'admin-2',
          action: 'approve_vendor',
          targetId: 'vendor-9',
          createdAt: null,
        ),
      ],
      page: 1,
      limit: 20,
      total: 2,
      action: 'all',
    );
  }
}

void main() {
  testWidgets('AuditLogsScreen filters logs by search query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditProvider.overrideWith(_FakeAuditNotifier.new),
        ],
        child: const MaterialApp(home: AuditLogsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Block User'), findsOneWidget);
    expect(find.text('Approve Vendor'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'vendor-9');
    await tester.pumpAndSettle();

    expect(find.text('Approve Vendor'), findsOneWidget);
    expect(find.text('Block User'), findsNothing);
  });
}