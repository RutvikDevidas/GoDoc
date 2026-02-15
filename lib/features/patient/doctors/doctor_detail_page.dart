import 'package:flutter/material.dart';

import '../../../shared/models/doctor.dart';
import '../../../shared/widgets/app_image.dart';
import '../booking/appointment_page.dart';

class DoctorDetailPage extends StatelessWidget {
  final Doctor doctor;
  const DoctorDetailPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Details")),
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
            AppImage(
              pathOrUrl: doctor.imageUrl,
              width: double.infinity,
              height: 220,
              radius: 18,
            ),
            const SizedBox(height: 14),
            Text(
              doctor.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              doctor.title,
              style: TextStyle(color: Colors.black.withOpacity(0.65)),
            ),
            const SizedBox(height: 10),

            _pillRow(),
            const SizedBox(height: 14),

            _card("Clinic / Hospital", doctor.hospital),
            const SizedBox(height: 10),
            _card("Address", doctor.address),
            const SizedBox(height: 10),
            _card("About", doctor.about),

            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentPage(doctor: doctor),
                    ),
                  );
                },
                child: const Text("Book Appointment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillRow() {
    return Row(
      children: [
        _pill(Icons.star, "${doctor.rating.toStringAsFixed(1)}"),
        const SizedBox(width: 10),
        _pill(Icons.reviews, "${doctor.reviews} reviews"),
      ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}
