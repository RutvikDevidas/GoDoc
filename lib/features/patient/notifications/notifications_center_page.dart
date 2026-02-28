import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsCenterPage extends StatelessWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['message'] ?? ''),
                trailing: data['isRead'] == false
                    ? const Icon(Icons.circle, size: 10, color: Colors.red)
                    : null,
                onTap: () async {
                  await doc.reference.update({'isRead': true});
                },
              );
            },
          );
        },
      ),
    );
  }
}
