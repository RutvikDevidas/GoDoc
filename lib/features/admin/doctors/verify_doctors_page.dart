import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyDoctorsPage extends StatelessWidget {
  const VerifyDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Verification")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctor_verifications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final uid = doc.id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Doctor ID: $uid"),
                  subtitle: const Text("Pending verification"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => approveDoctor(uid),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => rejectDoctor(uid),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> approveDoctor(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isVerified': true,
    });

    await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
      'isVerified': true,
    });

    await FirebaseFirestore.instance
        .collection('doctor_verifications')
        .doc(uid)
        .update({'status': 'approved'});

    // Send notification
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': uid,
      'title': 'Verification Approved',
      'message': 'Your account has been approved by admin.',
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> rejectDoctor(String uid) async {
    await FirebaseFirestore.instance
        .collection('doctor_verifications')
        .doc(uid)
        .update({'status': 'rejected'});

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': uid,
      'title': 'Verification Rejected',
      'message': 'Your verification request was rejected.',
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }
}
