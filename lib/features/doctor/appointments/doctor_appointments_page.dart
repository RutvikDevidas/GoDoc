import 'package:flutter/material.dart';

import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/doctor_auth_store.dart';
import 'appointment_action_page.dart';

class DoctorAppointmentsPage extends StatelessWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = DoctorAuthStore.currentDoctorId ?? "d1";

    final pending = AppointmentStore.doctorPending(doctorId);
    final accepted = AppointmentStore.doctorAccepted(doctorId);
    final completed = AppointmentStore.doctorCompleted(doctorId);

    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
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
            _section("Pending", pending, context),
            const SizedBox(height: 14),
            _section("Accepted", accepted, context),
            const SizedBox(height: 14),
            _section("Completed", completed, context),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Appointment> list, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text("No appointments"),
          ),
        ...list.map((a) => _tile(a, context)),
      ],
    );
  }

  Widget _tile(Appointment a, BuildContext context) {
    final patientName = a.patient?.name ?? "Patient";
    final patientPhone = a.patient?.phone ?? "-";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentActionPage(appointmentId: a.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text("Phone: $patientPhone"),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(a.dateTime),
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

  String _fmt(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, "0");
    final d = dt.day.toString().padLeft(2, "0");
    final hh = dt.hour.toString().padLeft(2, "0");
    final mm = dt.minute.toString().padLeft(2, "0");
    return "$y-$m-$d $hh:$mm";
  }
}
