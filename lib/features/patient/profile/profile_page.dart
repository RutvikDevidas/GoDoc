import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../notifications/notifications_center_page.dart';
import '../appointments/appointments_page.dart';
import 'saved_doctors_page.dart';
import '../../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final picker = ImagePicker();

  final nameCtrl = TextEditingController(text: "John Doe");
  final emailCtrl = TextEditingController(text: "johndoe@gmail.com");
  final phoneCtrl = TextEditingController(text: "9876543210");
  final ageCtrl = TextEditingController(text: "25");

  final List<String> reports = [];

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  void _addReport() {
    setState(() {
      reports.add("Medical Report ${reports.length + 1}");
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            // 👤 Profile Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : null,
                        child: _image == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: ageCtrl,
                    decoration: const InputDecoration(
                      labelText: "Age",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📄 Medical Reports
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Medical Reports",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _addReport,
                  child: const Text("Add Report"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (reports.isEmpty)
              const Text("No reports added yet")
            else
              ...reports.map(
                (report) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(report),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 🔗 Navigation Tiles
            _tile(context, "Saved Doctors", Icons.favorite, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedDoctorsPage()),
              );
            }),

            _tile(context, "My Appointments", Icons.event_available, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsPage()),
              );
            }),

            _tile(context, "Notifications", Icons.notifications, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsCenterPage(),
                ),
              );
            }),

            const SizedBox(height: 20),

            // 🚪 Logout Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: _logout,
                child: const Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2BB673).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
