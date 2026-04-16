import 'package:flutter_dotenv/flutter_dotenv.dart';

class RuntimeConfig {
  static const String _defaultApiBaseUrl = 'http://localhost:3000/api/v1';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? _defaultApiBaseUrl;

  static String get demoVendorEmail => dotenv.env['DEMO_VENDOR_EMAIL'] ?? '';

  static String get demoVendorPassword =>
      dotenv.env['DEMO_VENDOR_PASSWORD'] ?? '';
}