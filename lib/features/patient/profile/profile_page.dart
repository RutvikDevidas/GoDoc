import 'package:flutter/material.dart';
import '../../../shared/stores/auth_store.dart';
import '../notifications/notifications_center_page.dart';
import 'edit_profile_page.dart';
import 'my_appointments_page.dart';
import 'saved_doctors_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';
import 'logout_confirm_page.dart';
import 'medical_reports_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200",
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthStore.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(AuthStore.email),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          _tile(Icons.person, "Edit Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
          }),
          _tile(Icons.history, "My Appointments", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyAppointmentsPage()),
            );
          }),
          _tile(Icons.favorite_border, "Saved Doctors", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedDoctorsPage()),
            );
          }),
          _tile(Icons.notifications_none, "Notifications", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsCenterPage(),
              ),
            );
          }),

          _tile(Icons.folder_open, "Medical Reports", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalReportsPage()),
            );
          }),

          _tile(Icons.settings, "Settings", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }),
          _tile(Icons.help_outline, "Help & Support", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportPage()),
            );
          }),
          _tile(Icons.logout, "Logout", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogoutConfirmPage()),
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
