import 'package:flutter/material.dart';
import '../../../core/utils/datetime_fmt.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';
import '../booking/reschedule_page.dart';
import 'feedback_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int tab = 0; // 0 current, 1 history

  @override
  Widget build(BuildContext context) {
    final upcoming = AppointmentStore.patientUpcoming();
    final history = AppointmentStore.patientHistory();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: _tabButton("Current", 0)),
                    Expanded(child: _tabButton("History", 1)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (tab == 0) ...[
                    if (upcoming.isEmpty) _empty("No current appointments"),
                    ...upcoming.map((a) => _upcomingCard(a)),
                  ] else ...[
                    if (history.isEmpty) _empty("No history yet"),
                    ...history.map((a) => _historyCard(a)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final selected = tab == index;
    return InkWell(
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2BB673) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
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
  // CURRENT / UPCOMING CARD
  // -------------------------
  Widget _upcomingCard(Appointment a) {
    final when = DateTimeFmt.nice(context, a.dateTime);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              a.doctor.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
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
                const SizedBox(height: 6),
                Text(when),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(a.isOnline ? "Online" : "Offline"),
                    _pill(_statusLabel(a.status)),
                  ],
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () async {
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReschedulePage(appointmentId: a.id),
                    ),
                  );
                  if (res == true) {
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
                onPressed: () => _deleteDialog(a.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------
  // HISTORY / COMPLETED CARD
  // -------------------------
  Widget _historyCard(Appointment a) {
    final when = DateTimeFmt.nice(context, a.dateTime);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  a.doctor.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
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
                    const SizedBox(height: 6),
                    Text(when),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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

          // Feedback section
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
