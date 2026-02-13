import 'package:flutter/material.dart';
import '../../../shared/stores/patient_store.dart';
import '../../../shared/stores/auth_store.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PatientStore.demoPatient;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6E4FF), Color(0xFFC7DAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text("${p.email}\n${p.phone}"),
              ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text(
                  "Admin Account",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text("Logged in: ${AuthStore.email}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
