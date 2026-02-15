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

    // ✅ Admin credentials work from ANY toggle
    if (e == "admin" && p == "admin") {
      _loggedIn = true;
      _role = UserRole.admin;
      _name = "Admin";
      _email = "admin";
      return true;
    }

    // Normal patient/doctor demo validation
    if (e.isEmpty || (!e.contains("@") && role != UserRole.doctor)) {
      // for doctor we still allow non-email? (keep strict here)
      return false;
    }
    if (p.length < 4) return false;

    _loggedIn = true;
    _role = role;
    _email = e;
    _name = e.contains("@") ? e.split("@").first : e;
    return true;
  }

  static void logout() {
    _loggedIn = false;
    _role = UserRole.patient;
  }
}
