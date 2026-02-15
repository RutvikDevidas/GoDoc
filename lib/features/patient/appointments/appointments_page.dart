import 'package:flutter/material.dart';

import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';
import 'feedback_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    final upcoming = AppointmentStore.patientUpcoming();
    final history = AppointmentStore.patientHistory();

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
            const Text(
              "Current",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (upcoming.isEmpty) _empty("No current appointments"),
            ...upcoming.map((a) => _tile(a, true)),

            const SizedBox(height: 18),
            const Text(
              "History",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (history.isEmpty) _empty("No history"),
            ...history.map((a) => _tile(a, false)),
          ],
        ),
      ),
    );
  }

  Widget _empty(String t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _tile(Appointment a, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.doctor.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(a.dateTime),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text("Status: ${_statusLabel(a.status)}"),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isUpcoming && a.status != AppointmentStatus.cancelled)
                OutlinedButton(
                  onPressed: () {
                    AppointmentStore.cancel(a.id);
                    NotificationStore.add(
                      "Cancelled ❌",
                      "Appointment cancelled.",
                    );
                    setState(() {});
                  },
                  child: const Text("Cancel"),
                ),
              if (a.status == AppointmentStatus.completed)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackPage(appointmentId: a.id),
                      ),
                    );
                  },
                  child: const Text("Give Feedback"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.pending:
        return "Pending";
      case AppointmentStatus.accepted:
        return "Accepted";
      case AppointmentStatus.rejected:
        return "Rejected";
      case AppointmentStatus.cancelled:
        return "Cancelled";
      case AppointmentStatus.completed:
        return "Completed";
    }
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
