
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> write(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> remove(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
