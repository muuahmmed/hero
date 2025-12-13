import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _sessionKey = 'supabase_session';
  static const String _userKey = 'supabase_user';

  static Future<void> saveSession(String sessionToken, String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, sessionToken);
      await prefs.setString(_userKey, userEmail);
      print('✅ Session saved for: $userEmail');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  static Future<Map<String, String>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString(_sessionKey);
      final userEmail = prefs.getString(_userKey);

      if (sessionToken != null && userEmail != null) {
        print('✅ Found saved session for: $userEmail');
        return {
          'token': sessionToken,
          'email': userEmail,
        };
      }
      print('⚠️ No saved session found');
      return null;
    } catch (e) {
      print('❌ Error getting session: $e');
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_userKey);
      print('✅ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  static Future<bool> hasSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_sessionKey);
    } catch (e) {
      return false;
    }
  }
}