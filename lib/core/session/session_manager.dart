import 'package:shared_preferences/shared_preferences.dart';

enum AppSessionRole { admin, doctor, patient }

class AppSession {
  final AppSessionRole role;
  final String username;

  const AppSession({
    required this.role,
    required this.username,
  });
}

class SessionManager {
  SessionManager._();

  static const _roleKey = 'app_session_role';
  static const _usernameKey = 'app_session_username';

  static Future<void> saveSession(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, session.role.name);
    await prefs.setString(_usernameKey, session.username);
  }

  static Future<AppSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_roleKey);
    final username = prefs.getString(_usernameKey);

    if (roleName == null || username == null || username.trim().isEmpty) {
      return null;
    }

    final role = AppSessionRole.values
        .where((item) => item.name == roleName)
        .firstOrNull;
    if (role == null) return null;

    return AppSession(role: role, username: username.trim());
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_usernameKey);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
