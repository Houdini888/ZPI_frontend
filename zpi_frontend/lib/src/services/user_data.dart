import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _usernameKey = 'username';
  static const _activeGroupKey = 'activeGroup';
  static const _activeGroupInstrumentKey = 'activeGroupInstrument';
  static const _sessionCodeKey = 'sessionCode';

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

  static Future<void> saveActiveGroup(String activeGroup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGroupKey, activeGroup);
  }

  // Retrieve username from SharedPreferences
  static Future<String?> getActiveGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeGroupKey);
  }

  // Clear saved username (use when logging out)
  static Future<void> clearActiveGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGroupKey);
  }

  static Future<void> saveActiveGroupInstrument(String activeGroupInstrument) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGroupInstrumentKey, activeGroupInstrument);
  }

  // Retrieve username from SharedPreferences
  static Future<String?> getActiveGroupInstrument() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeGroupInstrumentKey);
  }

  // Clear saved username (use when logging out)
  static Future<void> clearActiveGroupInstrument() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGroupInstrumentKey);
  }

  static Future<void> setUserStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_status', status);
  }

  static Future<bool?> getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_status');
  }

  static Future<String?> getSessionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionCodeKey);
  }

  static Future<void> createSessionCode() async {
    final prefs = await SharedPreferences.getInstance();
    String sessionCode = '';
    final random = Random();
    final characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    for (int i = 0; i < 14; i++) {
      sessionCode += characters[
      random.nextInt(characters.length)];
    }

    await prefs.setString(_sessionCodeKey, sessionCode);
  }
}