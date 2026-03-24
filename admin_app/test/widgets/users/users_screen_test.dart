import 'package:admin_app/features/users/data/models/admin_user.dart';
import 'package:admin_app/features/users/presentation/providers/users_provider.dart';
import 'package:admin_app/features/users/presentation/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUsersNotifier extends UsersNotifier {
  static List<String>? lastBulkBlockedIds;
  static bool? lastBulkBlockedState;
  static String? lastBulkBlockReason;

  @override
  Future<UsersState> build() async {
    return UsersState(
      users: const [
        AdminUser(
          id: 'u-1',
          name: 'Alice Admin',
          email: 'alice@example.com',
          role: 'admin',
          blocked: false,
          createdAt: null,
        ),
      ],
      page: 1,
      limit: 20,
      total: 1,
    );
  }

  @override
  Future<UserBulkActionResult> setBlockedMany(
    List<String> userIds, {
    required bool blocked,
    String? reason,
  }) async {
    lastBulkBlockedIds = List<String>.from(userIds);
    lastBulkBlockedState = blocked;
    lastBulkBlockReason = reason;
    return const UserBulkActionResult(successCount: 1, errors: {});
  }
}

void main() {
  setUp(() {
    _FakeUsersNotifier.lastBulkBlockedIds = null;
    _FakeUsersNotifier.lastBulkBlockedState = null;
    _FakeUsersNotifier.lastBulkBlockReason = null;
  });

  testWidgets('UsersScreen supports client-side search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(_FakeUsersNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: UsersScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice Admin'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'zzzz-not-found');
    await tester.pumpAndSettle();

    expect(find.text('No users found'), findsOneWidget);
  });

  testWidgets('UsersScreen bulk block selected users captures reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(_FakeUsersNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: UsersScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all filtered'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block selected'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Blocking for policy violation');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block all'));
    await tester.pumpAndSettle();

    expect(_FakeUsersNotifier.lastBulkBlockedIds, ['u-1']);
    expect(_FakeUsersNotifier.lastBulkBlockedState, isTrue);
    expect(_FakeUsersNotifier.lastBulkBlockReason, contains('policy'));
  });
}
