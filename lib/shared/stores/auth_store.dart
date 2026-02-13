import '../models/user_role.dart';

class AuthStore {
  static bool _loggedIn = false;
  static UserRole _role = UserRole.patient;

  static String _name = "Patient";
  static String _email = "patient@godoc.com";

  static bool get isLoggedIn => _loggedIn;
  static UserRole get role => _role;
  static String get name => _name;
  static String get email => _email;

  static bool login({
    required String email,
    required String password,
    required UserRole role,
  }) {
    final e = email.trim();
    final p = password.trim();

    // ✅ Admin fixed credentials
    if (role == UserRole.admin) {
      if (e == "admin" && p == "admin") {
        _loggedIn = true;
        _role = UserRole.admin;
        _name = "Admin";
        _email = "admin";
        return true;
      }
      return false;
    }

    // Patient/Doctor demo validation
    if (e.isEmpty || !e.contains("@")) return false;
    if (p.length < 4) return false;

    _loggedIn = true;
    _role = role;
    _email = e;
    _name = e.split("@").first;
    return true;
  }

  static bool register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    // Admin cannot register
    if (role == UserRole.admin) return false;

    if (name.trim().isEmpty) return false;
    if (!email.contains("@")) return false;
    if (password.trim().length < 4) return false;

    _loggedIn = true;
    _role = role;
    _name = name.trim();
    _email = email.trim();
    return true;
  }

  static void logout() {
    _loggedIn = false;
    _role = UserRole.patient;
  }
}
