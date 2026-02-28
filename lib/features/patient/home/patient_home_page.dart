import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../doctors/doctor_detail_page.dart';
// import '../doctors/doctors_list_page.dart';
import '../notifications/notifications_center_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String search = "";

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // ---------------- HEADER ----------------
            Row(
              children: [
                const CircleAvatar(radius: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Hello Patient!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),

                // 🔔 Notification Icon (Firestore Based)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final unread = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsCenterPage(),
                              ),
                            );
                          },
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- SEARCH ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search doctor",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Available Doctors",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            // ---------------- FIRESTORE DOCTORS ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doctors = snapshot.data!.docs;

                final filtered = doctors.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? "").toLowerCase();
                  return name.contains(search.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        "No verified doctors available.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _doctorCard(context, doc.id, data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(
    BuildContext context,
    String doctorId,
    Map<String, dynamic> data,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailPage(doctorId: doctorId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2BB673).withOpacity(0.22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: data['profileImage'] != null
                  ? NetworkImage(data['profileImage'])
                  : null,
              child: data['profileImage'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['specialization'] ?? '',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
