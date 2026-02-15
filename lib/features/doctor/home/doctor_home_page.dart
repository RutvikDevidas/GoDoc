import 'package:flutter/material.dart';

import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/doctor_auth_store.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = DoctorAuthStore.currentDoctorId ?? "d1";

    final pending = AppointmentStore.doctorPending(doctorId).length;
    final accepted = AppointmentStore.doctorAccepted(doctorId).length;
    final completed = AppointmentStore.doctorCompleted(doctorId).length;

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
            const Text(
              "Doctor Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _card("Pending", pending.toString())),
                const SizedBox(width: 12),
                Expanded(child: _card("Accepted", accepted.toString())),
              ],
            ),
            const SizedBox(height: 12),
            _card("Completed", completed.toString()),
          ],
        ),
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
          Text(title, style: TextStyle(color: Colors.black.withOpacity(0.65))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
