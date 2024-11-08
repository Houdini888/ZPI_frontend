import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _usernameKey = 'username';
  static const _activeGroupKey = 'username';

  // Save username in SharedPreferences
  static Future<void> saveUserName(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  // Retrieve username from SharedPreferences
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Clear saved username (use when logging out)
  static Future<void> clearUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }
}