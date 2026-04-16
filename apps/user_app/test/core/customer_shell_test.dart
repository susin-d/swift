import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/core/widgets/customer_shell.dart';

void main() {
  testWidgets('customer shell renders shared navigation and header',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomerShell(
            selectedIndex: 0,
            title: 'Home',
            subtitle: 'Shared shell subtitle',
            body: SizedBox.expand(
              child: Center(child: Text('Shell body')),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    expect(find.text('Home'), findsExactly(2));
    expect(find.text('Shared shell subtitle'), findsOneWidget);
    expect(find.text('Shell body'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  test('primary destinations expose the screenshot tab set', () {
    expect(
      CustomerShell.primaryDestinations.map((item) => item.label).toList(),
      const ['Home', 'Browse', 'Orders', 'Wallet', 'Account'],
    );
  });
}
