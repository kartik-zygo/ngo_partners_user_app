class AppConstants {
  // The API lives behind a path prefix on a TLS host. Plain HTTP on a
  // non-standard port never reached the server from mobile networks, and
  // Android blocks cleartext by default — never point this back at one.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.zygonich.com/ngo-api/api/v1',
  );

  /// Scheme + host + port only. socket.io reads anything after the host as a
  /// namespace, so the `/ngo-api` prefix has to travel in [socketPath] instead.
  static String get socketUrl {
    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// `/ngo-api` from `https://host/ngo-api/api/v1`; empty if the API sits at
  /// the root.
  static String get _pathPrefix {
    final path = Uri.parse(baseUrl).path;
    final index = path.indexOf('/api/v1');
    return index <= 0 ? '' : path.substring(0, index);
  }

  /// Must be passed to the socket.io client explicitly — the default
  /// `/socket.io` does not route behind the prefix and fails silently.
  static String get socketPath => '$_pathPrefix/socket.io';

  /// Base for server-hosted files (`<uploadsBaseUrl>/<file>`).
  static String get uploadsBaseUrl => '$socketUrl$_pathPrefix/uploads';

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
}
