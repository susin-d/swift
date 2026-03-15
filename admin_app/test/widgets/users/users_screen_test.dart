import 'package:admin_app/features/users/data/models/admin_user.dart';
import 'package:admin_app/features/users/presentation/providers/users_provider.dart';
import 'package:admin_app/features/users/presentation/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUsersNotifier extends UsersNotifier {
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
}

void main() {
  testWidgets('UsersScreen supports client-side search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(_FakeUsersNotifier.new),
        ],
        child: const MaterialApp(home: UsersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice Admin'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'zzzz-not-found');
    await tester.pumpAndSettle();

    expect(find.text('No users found'), findsOneWidget);
  });
}
