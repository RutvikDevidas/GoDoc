import 'package:flutter/material.dart';
import '../../../shared/data/demo_data.dart';
import '../doctors/doctor_detail_page.dart';

class SavedDoctorsPage extends StatelessWidget {
  const SavedDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = DemoData.doctors.take(2).toList(); // demo saved list

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Doctors")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: saved.isEmpty
            ? [const Center(child: Text("No saved doctors"))]
            : saved
                  .map(
                    (d) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailPage(doctor: d),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                d.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(d.title),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
