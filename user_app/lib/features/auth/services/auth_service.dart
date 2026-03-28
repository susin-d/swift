  // ...existing code...
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    final response = await _api.post('/auth/session', data: {
      'email': email,
      'password': password,
    });
    final session = response.data['session'] as Map<String, dynamic>?;
    if (session != null && session['access_token'] != null) {
      await _storage.write(key: 'jwt', value: session['access_token']);
    }
    return response.data;
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
    await _storage.delete(key: 'jwt');
    // Optionally, call a backend endpoint to invalidate session if needed
  }

  // Fetch session from backend
  Future<Map<String, dynamic>?> fetchSession() async {
    final response = await _api.get('/auth/me');
    return response.data;
  }
}
