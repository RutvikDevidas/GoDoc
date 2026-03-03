import 'package:flutter/material.dart';
import '../doctors/doctor_detail_page.dart';

class SavedDoctorsPage extends StatelessWidget {
  const SavedDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🩺 Dummy doctors list (Frontend only)
    final List<Map<String, String>> savedDoctors = [
      {"id": "1", "name": "Dr. Rahul Sharma", "specialization": "Cardiologist"},
      {"id": "2", "name": "Dr. Priya Naik", "specialization": "Dermatologist"},
      {"id": "3", "name": "Dr. Amit Verma", "specialization": "Orthopedic"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Doctors")),
      body: savedDoctors.isEmpty
          ? const Center(child: Text("No saved doctors"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = savedDoctors[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorDetailPage(doctorId: doctor["id"]!),
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
                        const CircleAvatar(
                          radius: 35,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor["name"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(doctor["specialization"]!),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
