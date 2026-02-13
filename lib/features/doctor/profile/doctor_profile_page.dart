import 'package:flutter/material.dart';
import '../../../shared/stores/doctor_store.dart';
import '../../../shared/stores/auth_store.dart';
import '../../auth/auth_gate.dart';
import 'edit_doctor_profile_page.dart';
import 'clinic_details_page.dart';
import '../schedule/doctor_schedule_page.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = DoctorStore.profile;

    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=200",
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.email),
                    Text(p.phone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _tile(Icons.edit, "Edit Bio & Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditDoctorProfilePage()),
            );
          }),
          _tile(Icons.local_hospital, "Clinic Details", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClinicDetailsPage()),
            );
          }),
          _tile(Icons.schedule, "Set Schedule", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorSchedulePage()),
            );
          }),
          _tile(Icons.logout, "Logout", () {
            AuthStore.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (_) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2BB673).withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
