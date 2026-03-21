import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.session != null) {
      await _storage.write(key: 'jwt', value: response.session!.accessToken);
    }
    
    return response;
  }

  Future<void> signUp(String email, String password, String name) async {
    await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<void> updateProfile({String? name, String? phone, String? address}) async {
    final payload = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
    };
    payload.removeWhere((_, value) => value == null);

    await _api.patch('/auth/me', data: payload);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: 'jwt');
  }

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;
}
