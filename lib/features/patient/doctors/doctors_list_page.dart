import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_detail_page.dart';

class DoctorsListPage extends StatelessWidget {
  const DoctorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Doctors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('isVerified', isEqualTo: true) // ✅ ONLY VERIFIED
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No verified doctors available"));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: data['profileImage'] != null
                        ? NetworkImage(data['profileImage'])
                        : null,
                    child: data['profileImage'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    data['name'] ?? "Doctor",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['specialization'] ?? ""),
                      Text(data['clinicName'] ?? ""),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorDetailPage(doctorId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
