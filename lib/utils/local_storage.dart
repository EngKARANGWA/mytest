import 'package:shared_preferences/shared_preferences.dart';

// Save data locally
Future<void> saveLocalData(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

// Read data locally
Future<String?> getLocalData(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
