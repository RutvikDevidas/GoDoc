import 'package:flutter/material.dart';

class VerifyDoctorsPage extends StatefulWidget {
  const VerifyDoctorsPage({super.key});

  @override
  State<VerifyDoctorsPage> createState() => _VerifyDoctorsPageState();
}

class _VerifyDoctorsPageState extends State<VerifyDoctorsPage> {
  // 🩺 Dummy pending verification requests
  List<Map<String, String>> pendingDoctors = [
    {"uid": "D001", "name": "Dr. Rahul Sharma"},
    {"uid": "D002", "name": "Dr. Priya Naik"},
    {"uid": "D003", "name": "Dr. Amit Verma"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Verification")),
      body: pendingDoctors.isEmpty
          ? const Center(child: Text("No pending requests"))
          : ListView.builder(
              itemCount: pendingDoctors.length,
              itemBuilder: (context, index) {
                final doctor = pendingDoctors[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(doctor["name"]!),
                    subtitle: Text("Doctor ID: ${doctor["uid"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => approveDoctor(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => rejectDoctor(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void approveDoctor(int index) {
    final name = pendingDoctors[index]["name"];

    setState(() {
      pendingDoctors.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$name approved successfully")));
  }

  void rejectDoctor(int index) {
    final name = pendingDoctors[index]["name"];

    setState(() {
      pendingDoctors.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$name rejected")));
  }
}
