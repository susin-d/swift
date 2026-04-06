import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vendor_app/core/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({bool? isLoading, String? error, bool? isAuthenticated}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();

  AuthNotifier(this._api) : super(AuthState()) {
    _checkAuth();
  }

  Future<String?> _readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } on MissingPluginException {
      // Ignore in test/headless environments where plugin channels are unavailable.
    } catch (_) {
      // Ignore write failures and continue with in-memory auth state.
    }
  }

  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } on MissingPluginException {
      // Ignore in test/headless environments where plugin channels are unavailable.
    } catch (_) {
      // Ignore delete failures and continue with in-memory auth state.
    }
  }

  Future<void> _checkAuth() async {
    final token = await _readToken();
    if (token == null) {
      return;
    }

    try {
      final response = await _api.get('/auth/me');
      final role = response.data['user']?['role'] as String? ?? 'user';
      if (role != 'vendor') {
        await _clearToken();
        state = AuthState(error: 'Access denied. Vendor role required.');
        return;
      }

      state = state.copyWith(isAuthenticated: true);
    } catch (_) {
      await _clearToken();
      state = AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.post('/auth/session', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final role = response.data['user']?['role'] as String? ?? 'user';
        if (role != 'vendor') {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            error: 'Access denied. Vendor role required.',
          );
          return;
        }

        final token = response.data['session']['access_token'];
        await _writeToken(token?.toString() ?? '');
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _clearToken();
    state = AuthState();
  }
}
