import 'package:flutter/material.dart';

class NotificationsCenterPage extends StatefulWidget {
  const NotificationsCenterPage({super.key});

  @override
  State<NotificationsCenterPage> createState() =>
      _NotificationsCenterPageState();
}

class _NotificationsCenterPageState extends State<NotificationsCenterPage> {
  // 🔔 Dummy notifications (frontend only)
  List<Map<String, dynamic>> notifications = [
    {
      "title": "Appointment Confirmed",
      "message": "Your appointment with Dr. Rahul is confirmed.",
      "isRead": false,
    },
    {
      "title": "Reminder",
      "message": "You have an appointment tomorrow at 10 AM.",
      "isRead": false,
    },
    {
      "title": "Welcome to GoDoc",
      "message": "Thank you for using our app.",
      "isRead": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final data = notifications[index];

                return ListTile(
                  title: Text(data['title']),
                  subtitle: Text(data['message']),
                  trailing: data['isRead'] == false
                      ? const Icon(Icons.circle, size: 10, color: Colors.red)
                      : null,
                  onTap: () {
                    setState(() {
                      notifications[index]['isRead'] = true;
                    });
                  },
                );
              },
            ),
    );
  }
}
