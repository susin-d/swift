import 'package:flutter_dotenv/flutter_dotenv.dart';

class RuntimeConfig {
  static const String _defaultBackendApiUrl = 'http://localhost:3000/api/v1';
  static const String _defaultSupportEmail = 'support@example.com';
  static const String _defaultSupportEmailSubject = 'Support Request';
  static const String _defaultSupportPhone = '+10000000000';
  static const String _defaultSupportPhoneDisplay = '+1 000-000-0000';

  static String get backendApiUrl =>
      dotenv.env['BACKEND_API_URL'] ?? _defaultBackendApiUrl;

  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? _defaultSupportEmail;

  static String get supportEmailSubject =>
      dotenv.env['SUPPORT_EMAIL_SUBJECT'] ?? _defaultSupportEmailSubject;

  static String get supportPhone =>
      dotenv.env['SUPPORT_PHONE'] ?? _defaultSupportPhone;

  static String get supportPhoneDisplay =>
      dotenv.env['SUPPORT_PHONE_DISPLAY'] ?? _defaultSupportPhoneDisplay;

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
}