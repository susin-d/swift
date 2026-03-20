class PaymentConfig {
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');
  static const String merchantName = 'Swift';
  static const String merchantDescription = 'Campus Food Delivery';
}
