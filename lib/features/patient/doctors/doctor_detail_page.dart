import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorDetailPage extends StatelessWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Details"),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('saved_doctors')
                .where('userId', isEqualTo: uid)
                .where('doctorId', isEqualTo: doctorId)
                .snapshots(),
            builder: (context, snapshot) {
              final isSaved =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () async {
                  if (isSaved) {
                    await snapshot.data!.docs.first.reference.delete();
                  } else {
                    await FirebaseFirestore.instance
                        .collection('saved_doctors')
                        .add({
                          'userId': uid,
                          'doctorId': doctorId,
                          'createdAt': Timestamp.now(),
                        });
                  }
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Doctor not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: data['profileImage'] != null
                        ? NetworkImage(data['profileImage'])
                        : null,
                    child: data['profileImage'] == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Name + Verified Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (data['isVerified'] == true)
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                  ],
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    data['specialization'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 24),

                _infoTile("Clinic Name", data['clinicName'] ?? ''),
                _infoTile("Clinic Address", data['clinicAddress'] ?? ''),
                _infoTile("Experience", "${data['experience'] ?? ''} years"),
                _infoTile("License No", data['licenseNo'] ?? ''),
                _infoTile("PR Number", data['prNumber'] ?? ''),
                _infoTile("KMC Number", data['kmcNumber'] ?? ''),

                const SizedBox(height: 30),

                // Book Appointment Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2BB673),
                    ),
                    onPressed: () {
                      // Next step: Appointment screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Appointment booking coming next 🚀"),
                        ),
                      );
                    },
                    child: const Text(
                      "Book Appointment",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }
}
