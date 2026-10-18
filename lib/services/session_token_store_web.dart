import 'package:web/web.dart' as web;

final Map<String, String> _memoryFallback = {};

String? read(String key) {
  try {
    return web.window.sessionStorage.getItem(key) ?? _memoryFallback[key];
  } catch (_) {
    return _memoryFallback[key];
  }
}

void write(String key, String value) {
  try {
    web.window.sessionStorage.setItem(key, value);
  } catch (_) {
    _memoryFallback[key] = value;
  }
}

void remove(String key) {
  _memoryFallback.remove(key);
  try {
    web.window.sessionStorage.removeItem(key);
  } catch (_) {
    // The in-memory value has already been removed.
  }
}
