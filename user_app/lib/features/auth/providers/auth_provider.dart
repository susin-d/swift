import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed direct Supabase dependency; all auth is now backend API only.
import '../services/auth_service.dart';


final authRefreshListenableProvider = Provider<Listenable>((ref) {
  final notifier = ValueNotifier<Map<String, dynamic>?>(ref.read(userProvider));
  ref.listen<Map<String, dynamic>?>(userProvider, (previous, next) {
    notifier.value = next;
  });
  return notifier;
});

final authServiceProvider = Provider((ref) => AuthService());



// Auth state stream using backend session endpoint (polling example)
final authStateProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  // Poll backend session endpoint every 10 seconds (example)
  while (true) {
    try {
      final session = await ref.read(authServiceProvider).fetchSession();
      yield session;
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 10));
  }
});


// User model fetched from backend session/profile endpoint
final userProvider = Provider<Map<String, dynamic>?>(
  (ref) => ref.watch(authStateProvider).value?['user'] as Map<String, dynamic>?,
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signIn(email, password));
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signUp(email, password, name);
      await _authService.signIn(email, password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signOut());
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
