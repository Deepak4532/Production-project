import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userEmailKey = 'user_email';

  static Future<void> saveUserSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
  }
}
