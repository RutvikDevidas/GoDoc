class RazorpayConfig {
  const RazorpayConfig._();

  /// Configure via --dart-define so keys are not committed to the repo.
  ///
  /// Example:
  /// flutter run --dart-define=RAZORPAY_KEY_ID=rzp_test_xxxxx
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_SedjqfJdOfT5xW',
  );
  static const String merchantName = String.fromEnvironment(
    'RAZORPAY_MERCHANT_NAME',
    defaultValue: 'GoDoc',
  );
  static const String merchantDescription = String.fromEnvironment(
    'RAZORPAY_MERCHANT_DESCRIPTION',
    defaultValue: 'Doctor consultation payment',
  );

  static bool get isConfigured =>
      keyId.trim().isNotEmpty &&
      keyId != 'YOUR_RAZORPAY_KEY_ID' &&
      keyId.startsWith('rzp_');
}
