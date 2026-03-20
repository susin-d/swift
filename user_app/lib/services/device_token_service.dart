import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceTokenService {
  static const _tokenKey = 'device_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getOrCreateToken() async {
    final existing = await _storage.read(key: _tokenKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final token = _generateToken();
    await _storage.write(key: _tokenKey, value: token);
    return token;
  }

  String _generateToken() {
    final rand = Random.secure();
    final values = List<int>.generate(24, (_) => rand.nextInt(256));
    return values.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }
}
