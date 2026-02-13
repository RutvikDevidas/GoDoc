import 'package:flutter/material.dart';
import '../../../shared/models/doctor.dart';
import '../booking/appointment_page.dart';

class DoctorDetailPage extends StatelessWidget {
  final Doctor doctor;
  const DoctorDetailPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              doctor.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            doctor.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            doctor.title,
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                "${doctor.rating.toStringAsFixed(1)} (${doctor.reviews} reviews)",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Clinic Address",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              "https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?w=1200",
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Text("About Me", style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            doctor.about,
            style: TextStyle(color: Colors.black.withOpacity(0.7)),
          ),
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
    );
  }
}
