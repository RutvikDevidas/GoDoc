import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../services/firebase_auth_service.dart';
import '../../shared/models/user_role.dart';
import '../doctor/shell/doctor_shell.dart';
import '../patient/shell/patient_shell.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  UserRole selectedRole = UserRole.patient;
  bool isLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = selectedRole == UserRole.patient
        ? "Patient Login"
        : "Doctor Login";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 40),
              const Text(
                "GoDoc",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              _roleToggle(),
              const SizedBox(height: 20),

              _card(
                child: Column(
                  children: [
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterPage(initialRole: selectedRole),
                          ),
                        );
                      },
                      child: const Text("Create new account"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleToggle() {
    final isPatient = selectedRole == UserRole.patient;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _seg(
              "Patient",
              isPatient,
              () => setState(() => selectedRole = UserRole.patient),
            ),
          ),
          Expanded(
            child: _seg(
              "Doctor",
              !isPatient,
              () => setState(() => selectedRole = UserRole.doctor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(String title, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2BB673) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Future<void> _login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _showError("Please enter email and password");
      return;
    }

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // Fake loading

    if (!mounted) return;

    if (selectedRole == UserRole.doctor) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DoctorShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientShell()),
      );
    }

    setState(() => isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
