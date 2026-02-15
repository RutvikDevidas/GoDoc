import 'package:flutter/material.dart';

// import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';

class AppointmentActionPage extends StatelessWidget {
  final String appointmentId;
  const AppointmentActionPage({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final a = AppointmentStore.byId(appointmentId);

    if (a == null) {
      return const Scaffold(body: Center(child: Text("Appointment not found")));
    }

    final patientName = a.patient?.name ?? "Patient";
    final patientEmail = a.patient?.email ?? "-";
    final patientPhone = a.patient?.phone ?? "-";

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Actions")),
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
            _card("Patient", "$patientName\n$patientEmail\n$patientPhone"),
            const SizedBox(height: 10),
            _card("Status", a.status.name),
            const SizedBox(height: 10),
            _card("Time", _fmt(a.dateTime)),
            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    AppointmentStore.accept(a.id);
                    NotificationStore.add(
                      "Accepted ✅",
                      "Appointment accepted.",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Accept"),
                ),
                OutlinedButton(
                  onPressed: () {
                    AppointmentStore.reject(a.id);
                    NotificationStore.add(
                      "Rejected ❌",
                      "Appointment rejected.",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Reject"),
                ),
                ElevatedButton(
                  onPressed: () {
                    AppointmentStore.complete(a.id);
                    NotificationStore.add(
                      "Completed ✅",
                      "Appointment marked completed.",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Complete"),
                ),
              ],
            ),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(value),
        ],
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
