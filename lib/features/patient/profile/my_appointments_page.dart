import 'package:flutter/material.dart';

import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';
import '../../../shared/widgets/app_image.dart';
import '../booking/reschedule_page.dart';
import '../appointments/feedback_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppointmentStore.itemsVN,
      builder: (_, __, ___) {
        final upcoming = AppointmentStore.patientUpcoming();
        final history = AppointmentStore.patientHistory();

        return Scaffold(
          appBar: AppBar(title: const Text("My Appointments")),
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
                  "Current Appointments",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (upcoming.isEmpty) _empty("No current appointments"),
                ...upcoming.map((a) => _upcomingTile(a)),

                const SizedBox(height: 18),
                const Text(
                  "Appointment History",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (history.isEmpty) _empty("No history yet"),
                ...history.map((a) => _historyTile(a)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  // -------------------------
  // UPCOMING TILE
  // -------------------------
  Widget _upcomingTile(Appointment a) {
    final when = _nice(context, a.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: AppImage(
          pathOrUrl: a.doctor.imageUrl,
          width: 46,
          height: 46,
          radius: 999,
        ),
        title: Text(
          a.doctor.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(when),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                _pill(a.isOnline ? "Online" : "Offline"),
                _pill(_statusLabel(a.status)),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Reschedule",
              onPressed: () async {
                final newDateTime = await Navigator.push<DateTime?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReschedulePage(appointment: a),
                  ),
                );

                if (newDateTime != null) {
                  AppointmentStore.reschedule(a.id, newDateTime);
                  NotificationStore.add(
                    "Rescheduled ✅",
                    "Appointment updated.",
                  );
                }
              },
              icon: const Icon(Icons.edit_calendar),
            ),
            IconButton(
              tooltip: "Delete",
              onPressed: () => _deleteDialog(a.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // HISTORY TILE
  // -------------------------
  Widget _historyTile(Appointment a) {
    final when = _nice(context, a.dateTime);
    final completed = a.status == AppointmentStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppImage(
                pathOrUrl: a.doctor.imageUrl,
                width: 46,
                height: 46,
                radius: 999,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.doctor.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(when),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _pill(a.isOnline ? "Online" : "Offline"),
                        _pill(_statusLabel(a.status)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                completed ? Icons.check_circle : Icons.history,
                color: completed ? const Color(0xFF2BB673) : Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (a.status == AppointmentStatus.completed && a.feedback == null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackPage(appointmentId: a.id),
                    ),
                  );
                  NotificationStore.add("Thanks ⭐", "Feedback submitted.");
                },
                child: const Text("Give Feedback"),
              ),
            )
          else if (a.feedback != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2BB673).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    "${a.feedback!.rating}/5",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      a.feedback!.comment.isEmpty
                          ? "No comment"
                          : a.feedback!.comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2BB673).withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _deleteDialog(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete appointment?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      AppointmentStore.delete(id);
      NotificationStore.add("Deleted ❌", "Appointment deleted.");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Appointment deleted")));
      }
    }
  }

  // Simple formatter (replaces DateTimeFmt.nice)
  String _nice(BuildContext context, DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, "0");
    final d = dt.day.toString().padLeft(2, "0");

    final hh = dt.hour;
    final mm = dt.minute.toString().padLeft(2, "0");
    final ampm = hh >= 12 ? "PM" : "AM";
    final h12 = (hh % 12 == 0) ? 12 : (hh % 12);

    return "$y-$m-$d  $h12:$mm $ampm";
  }
}
