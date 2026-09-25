import 'package:shared_preferences/shared_preferences.dart';

/// Records that this device's user agreed to the Terms of Use (EULA). App
/// Store guideline 1.2 requires that agreement before sign-in or
/// registration, and before anyone who signed in on an older build reaches
/// the Community.
///
/// Raise [version] whenever the terms change materially, and everyone is
/// asked to agree again.
class TermsConsent {
  TermsConsent._();

  static const String version = '2026-09-25';
  static const String _key = 'termsAcceptedVersion';

  static bool _accepted = false;

  static bool get accepted => _accepted;

  /// Call once at start-up, before the first frame.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accepted = prefs.getString(_key) == version;
  }

  /// Takes effect immediately, so a sign-in that completes right after this
  /// call already sees the agreement.
  static Future<void> accept() async {
    _accepted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, version);
  }
}
