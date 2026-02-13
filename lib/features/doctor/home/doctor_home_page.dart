import 'package:flutter/material.dart';
import '../../../shared/stores/doctor_store.dart';
import '../../../shared/stores/appointment_store.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = DoctorStore.profile;
    final pending = AppointmentStore.doctorPending().length;
    final accepted = AppointmentStore.doctorAccepted().length;
    final completed = AppointmentStore.doctorCompleted().length;

    return SafeArea(
      child: Container(
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
            Text(
              "Hello, ${p.name}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _statCard(
              "Pending Requests",
              pending.toString(),
              Icons.hourglass_top,
            ),
            const SizedBox(height: 10),
            _statCard(
              "Accepted",
              accepted.toString(),
              Icons.check_circle_outline,
            ),
            const SizedBox(height: 10),
            _statCard("Completed", completed.toString(), Icons.task_alt),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "Tip: Keep your schedule updated so patients can book accurately.",
                style: TextStyle(color: Colors.black.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2BB673).withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
