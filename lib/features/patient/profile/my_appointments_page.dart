import 'package:flutter/material.dart';

import '../../../core/utils/datetime_fmt.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';
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
    final upcoming = AppointmentStore.patientUpcoming();
    final history = AppointmentStore.patientHistory();

    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: ListView(
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
    );
  }

  Widget _empty(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
    final when = DateTimeFmt.nice(context, a.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(a.doctor.imageUrl)),
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
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReschedulePage(appointmentId: a.id),
                  ),
                );
                if (ok == true) {
                  NotificationStore.add(
                    "Rescheduled ✅",
                    "Appointment updated.",
                  );
                  setState(() {});
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
    final when = DateTimeFmt.nice(context, a.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(a.doctor.imageUrl)),
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
                        _pill("Completed"),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Color(0xFF2BB673)),
            ],
          ),
          const SizedBox(height: 12),

          if (a.feedback == null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackPage(appointmentId: a.id),
                    ),
                  );
                  if (ok == true) {
                    NotificationStore.add("Thanks ⭐", "Feedback submitted.");
                    setState(() {});
                  }
                },
                child: const Text("Give Feedback"),
              ),
            )
          else
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
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Appointment deleted")));
      }
    }
  }
}
