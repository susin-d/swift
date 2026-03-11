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

  AuthNotifier(this._api) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
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
        final token = response.data['session']['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
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
    await prefs.remove('auth_token');
    state = AuthState();
  }
}
