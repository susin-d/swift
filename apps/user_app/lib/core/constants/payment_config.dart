import '../config/runtime_config.dart';

class PaymentConfig {
  static String get razorpayKeyId => RuntimeConfig.razorpayKeyId;
  static const String merchantName = 'Swift';
  static const String merchantDescription = 'Campus Food Delivery';
}
