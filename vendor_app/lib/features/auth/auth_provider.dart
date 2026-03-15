import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  AuthNotifier(this._api) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      return;
    }

    try {
      final response = await _api.get('/auth/me');
      final role = response.data['user']?['role'] as String? ?? 'user';
      if (role != 'vendor') {
        await prefs.remove(_tokenKey);
        state = AuthState(error: 'Access denied. Vendor role required.');
        return;
      }

      state = state.copyWith(isAuthenticated: true);
    } catch (_) {
      await prefs.remove(_tokenKey);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    state = AuthState();
  }
}
