import 'package:admin_app/core/config/session_posture_provider.dart';
import 'package:admin_app/features/auth/data/models/admin_session.dart';
import 'package:admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:admin_app/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell shows bottom navigation on compact width', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SizedBox(
            width: 420,
            height: 800,
            child: AppShell(
              title: 'Dashboard',
              selectedIndex: 0,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Swift Control'), findsNothing);
  });

  testWidgets('AppShell shows trust warning banner for untrusted admin session', (tester) async {
    final fakeService = _FakeSessionPostureService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuthNotifier.new),
          sessionPostureServiceProvider.overrideWithValue(fakeService),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 1200,
            height: 900,
            child: AppShell(
              title: 'Dashboard',
              selectedIndex: 0,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Untrusted device'), findsOneWidget);
    expect(find.text('Trust this device'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthAuthenticated(
      AdminSession(
        token: 'token',
        userId: 'admin-1',
        email: 'admin@example.com',
        role: 'admin',
      ),
    );
  }
}

class _FakeSessionPostureService extends SessionPostureService {
  bool _trusted = false;

  @override
  Future<SessionPosture> loadPosture({required bool isAuthenticated}) async {
    if (!isAuthenticated) {
      return const SessionPosture(
        isAuthenticated: false,
        isTrusted: false,
        statusLabel: 'Session inactive',
        detail: 'No active session.',
      );
    }

    if (_trusted) {
      return const SessionPosture(
        isAuthenticated: true,
        isTrusted: true,
        statusLabel: 'Trusted device',
        detail: 'Trusted posture.',
        deviceFingerprint: 'abcd1234',
      );
    }

    return const SessionPosture(
      isAuthenticated: true,
      isTrusted: false,
      statusLabel: 'Untrusted device',
      detail: 'This device needs trust confirmation.',
      deviceFingerprint: 'abcd1234',
    );
  }

  @override
  Future<void> markCurrentDeviceTrusted() async {
    _trusted = true;
  }

  @override
  Future<void> markCurrentDeviceUntrusted() async {
    _trusted = false;
  }
}
