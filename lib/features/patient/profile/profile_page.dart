import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../notifications/notifications_center_page.dart';
import '../appointments/appointments_page.dart';
import 'saved_doctors_page.dart';
import '../../auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance.collection('patients').doc(uid).get(),
            FirebaseFirestore.instance.collection('users').doc(uid).get(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final patientDoc = snapshot.data![0] as DocumentSnapshot;
            final userDoc = snapshot.data![1] as DocumentSnapshot;

            if (!patientDoc.exists) {
              return const Center(child: Text("Profile not found"));
            }

            final patient = patientDoc.data() as Map<String, dynamic>;
            final user = userDoc.data() as Map<String, dynamic>;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 12),

                // Profile Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: user['profileImage'] != null
                            ? NetworkImage(user['profileImage'])
                            : null,
                        child: user['profileImage'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Age: ${patient['age'] ?? "-"}"),
                            Text(patient['email'] ?? "-"),
                            Text(patient['phone'] ?? "-"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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

                // Logout Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                        );
                      }
                    },
                    child: const Text(
                      "Logout",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
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
