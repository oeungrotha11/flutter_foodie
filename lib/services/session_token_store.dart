import 'session_token_store_mobile.dart'
    if (dart.library.js_interop) 'session_token_store_web.dart'
    as platform;

/// Keeps authentication tokens only for the current app/browser session.
class SessionTokenStore {
  SessionTokenStore._();

  static Future<String?> read(String key) async => platform.read(key);

  static Future<void> write(String key, String value) async =>
      platform.write(key, value);

  static Future<void> remove(String key) async => platform.remove(key);
}
