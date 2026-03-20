import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceTokenService {
  static const _tokenKey = 'device_token';

  Future<String> getOrCreateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_tokenKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final token = _generateToken();
    await prefs.setString(_tokenKey, token);
    return token;
  }

  String _generateToken() {
    final rand = Random.secure();
    final values = List<int>.generate(24, (_) => rand.nextInt(256));
    return values.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }
}
