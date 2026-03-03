import 'package:flutter/material.dart';

// import '../patient/shell/patient_shell.dart';
// import '../doctor/shell/doctor_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Frontend only: Always start with LoginPage
    return const LoginPage();
  }
}
