import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../doctors/doctor_detail_page.dart';

class SavedDoctorsPage extends StatelessWidget {
  const SavedDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Doctors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('saved_doctors')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final savedDocs = snapshot.data!.docs;

          if (savedDocs.isEmpty) {
            return const Center(child: Text("No saved doctors"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedDocs.length,
            itemBuilder: (context, index) {
              final doctorId = savedDocs[index]['doctorId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(doctorId)
                    .get(),
                builder: (context, doctorSnap) {
                  if (!doctorSnap.hasData) {
                    return const SizedBox();
                  }

                  final data = doctorSnap.data!.data() as Map<String, dynamic>;

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
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
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
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(data['specialization'] ?? ''),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
