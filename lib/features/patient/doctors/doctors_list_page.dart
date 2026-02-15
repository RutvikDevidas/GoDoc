import 'package:flutter/material.dart';

import '../../../shared/models/doctor.dart';
import '../../../shared/models/specialization.dart';
import '../../../shared/stores/doctor_registry_store.dart';
import '../../../shared/widgets/app_image.dart';
import 'doctor_detail_page.dart';

class DoctorsListPage extends StatelessWidget {
  final Specialization spec;
  const DoctorsListPage({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    final verifiedDoctors = DoctorRegistryStore.visibleForPatients()
        .where((d) => d.specializationId == spec.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(spec.name)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (verifiedDoctors.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    "No verified doctors for this service yet.",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ...verifiedDoctors.map((d) => _doctorCard(context, d)),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(BuildContext context, Doctor doctor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailPage(doctor: doctor)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            AppImage(
              pathOrUrl: doctor.imageUrl,
              width: 70,
              height: 70,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.title,
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "(${doctor.reviews} reviews)",
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
