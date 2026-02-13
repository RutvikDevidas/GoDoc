import 'package:flutter/material.dart';
import '../../shared/models/user_role.dart';
import '../../shared/stores/auth_store.dart';
import '../patient/shell/patient_shell.dart';
import '../doctor/shell/doctor_shell.dart';
import '../admin/shell/admin_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthStore.isLoggedIn) return const LoginPage();

    if (AuthStore.role == UserRole.admin) return const AdminShell();
    if (AuthStore.role == UserRole.doctor) return const DoctorShell();

    return const PatientShell();
  }
}
