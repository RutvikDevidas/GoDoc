import 'package:flutter/material.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../patients/patient_detail_page.dart';

class AppointmentActionPage extends StatefulWidget {
  final String appointmentId;
  const AppointmentActionPage({super.key, required this.appointmentId});

  @override
  State<AppointmentActionPage> createState() => _AppointmentActionPageState();
}

class _AppointmentActionPageState extends State<AppointmentActionPage> {
  @override
  Widget build(BuildContext context) {
    final a = AppointmentStore.byId(widget.appointmentId);
    if (a == null) {
      return const Scaffold(body: Center(child: Text("Appointment not found")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient: ${a.patient.name}",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text("Mode: ${a.isOnline ? "Online" : "Offline"}"),
                Text("DateTime: ${a.dateTime}"),
                Text("Status: ${a.status.name}"),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDetailPage(patient: a.patient),
                        ),
                      );
                    },
                    child: const Text("View Patient Profile & Reports"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (a.status == AppointmentStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AppointmentStore.accept(a.id);
                      Navigator.pop(context, true);
                    },
                    child: const Text("Accept"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      AppointmentStore.reject(a.id);
                      Navigator.pop(context, true);
                    },
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],

          if (a.status == AppointmentStatus.accepted) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final dt = await _pickDateTime(context, a.dateTime);
                  if (dt == null) return;
                  AppointmentStore.reschedule(a.id, dt, a.isOnline);
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text("Reschedule"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppointmentStore.complete(a.id);
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.task_alt),
                label: const Text("Mark Completed"),
              ),
            ),
          ],

          if (a.status == AppointmentStatus.completed) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Patient Feedback",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (a.feedback == null)
                    const Text("No feedback given yet.")
                  else ...[
                    Text("Rating: ${a.feedback!.rating}/5"),
                    const SizedBox(height: 6),
                    Text(a.feedback!.comment),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
