class AppConstants {
  // Use 10.0.2.2 for Android emulator (maps to host machine localhost)
  // Change to your server IP for physical device testing
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://150.241.245.88:8091/api/v1',
  );

  // Socket.io server URL — same host as baseUrl, without /api/v1 path
  static String get socketUrl => baseUrl.replaceFirst('/api/v1', '');

  static const String tokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userIdKey = 'userId';
  static const String onboardingDoneKey = 'onboardingDone';

  // Contact info
  static const String salesPhone = String.fromEnvironment(
    'SALES_PHONE',
    defaultValue: '+91 98765 43210',
  );
  static const String salesEmail = String.fromEnvironment(
    'SALES_EMAIL',
    defaultValue: 'sales@ngopartners.in',
  );
  static const String salesAvailability = 'Mon–Sat, 9AM–7PM';
  static const int basePriceOnwards = 500;
}
