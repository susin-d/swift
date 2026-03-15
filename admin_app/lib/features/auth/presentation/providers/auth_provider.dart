import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_session.dart';
import '../../data/services/auth_service.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);
  final AdminSession session;
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthInitial();
  }

  Future<void> _restore() async {
    state = const AuthLoading();
    final session = await AuthService.instance.restoreSession();
    state = session != null ? AuthAuthenticated(session) : const AuthInitial();
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await AuthService.instance.login(email, password);
      state = AuthAuthenticated(session);
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    state = const AuthInitial();
  }

  String? get errorMessage {
    final s = state;
    return s is AuthError ? s.message : null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
