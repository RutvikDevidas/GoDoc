import 'package:flutter/material.dart';
import 'doctor_detail_page.dart';

class DoctorsListPage extends StatelessWidget {
  const DoctorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🩺 Dummy verified doctors list
    final List<Map<String, String>> doctors = [
      {
        "id": "1",
        "name": "Dr. Rahul Sharma",
        "specialization": "Cardiologist",
        "clinicName": "Heart Care Clinic",
      },
      {
        "id": "2",
        "name": "Dr. Priya Naik",
        "specialization": "Dermatologist",
        "clinicName": "Skin Wellness Center",
      },
      {
        "id": "3",
        "name": "Dr. Amit Verma",
        "specialization": "Orthopedic",
        "clinicName": "Ortho Plus Hospital",
      },
      {
        "id": "4",
        "name": "Dr. Sneha Kulkarni",
        "specialization": "Pediatrician",
        "clinicName": "Happy Kids Clinic",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Doctors")),
      body: doctors.isEmpty
          ? const Center(child: Text("No verified doctors available"))
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      doctor["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor["specialization"]!),
                        Text(doctor["clinicName"]!),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DoctorDetailPage(doctorId: doctor["id"]!),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
