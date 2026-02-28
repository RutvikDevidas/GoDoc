import '../models/user_role.dart';

class AuthStore {
  static bool _loggedIn = false;
  static UserRole _role = UserRole.patient;

  static String _name = "";
  static String _email = "";

  static final List<Map<String, dynamic>> _users = [];

  static bool get isLoggedIn => _loggedIn;
  static UserRole get role => _role;
  static String get name => _name;
  static String get email => _email;

  // ---------------- REGISTER ----------------
  static bool register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    final e = email.trim();
    final p = password.trim();
    final n = name.trim();

    if (n.isEmpty || e.isEmpty || p.length < 4) {
      return false;
    }

    // Prevent duplicate user
    final exists = _users.any((u) => u["email"] == e);
    if (exists) return false;

    _users.add({"name": n, "email": e, "password": p, "role": role});

    return true;
  }

  // ---------------- LOGIN ----------------
  static bool login({
    required String email,
    required String password,
    required UserRole role,
  }) {
    final e = email.trim();
    final p = password.trim();

    // ADMIN LOGIN
    if (e == "admin" && p == "admin") {
      _loggedIn = true;
      _role = UserRole.admin;
      _name = "Admin";
      _email = "admin";
      return true;
    }

    final user = _users.where(
      (u) => u["email"] == e && u["password"] == p && u["role"] == role,
    );

    if (user.isEmpty) return false;

    _loggedIn = true;
    _role = role;
    _name = user.first["name"];
    _email = e;

    return true;
  }

  static void logout() {
    _loggedIn = false;
    _role = UserRole.patient;
    _name = "";
    _email = "";
  }
}
