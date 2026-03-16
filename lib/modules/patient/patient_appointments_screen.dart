import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/patient_model.dart';
import '../../models/appointment_model.dart';
import '../video_call/video_call_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientAppointmentsScreen({super.key, required this.patient});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<AppointmentModel> get myAppointments => AppState.appointments
      .where((a) => a.patientUsername == widget.patient.username)
      .toList();

  Future<void> _joinVideoCall(AppointmentModel appt) async {
    if (appt.callRoom == null || appt.callRoom!.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callID: appt.callRoom ?? appt.id,
          userID: widget.patient.username,
          userName: widget.patient.name,
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(AppointmentModel appt) async {
    final commentController = TextEditingController();
    int rating = appt.feedbackRating ?? 5;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Give feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      hintText: 'How was your consultation?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Rating:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: (rating).toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: rating.toString(),
                          onChanged: (value) {
                            rating = value.toInt();
                            setState(() {});
                          },
                        ),
                      ),
                      Text(rating.toString()),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    setState(() {
      appt.feedbackSubmitted = true;
      appt.feedbackComments = commentController.text.trim();
      appt.feedbackRating = rating;
    });

    await FirestoreDataService.instance.saveAppointment(appt);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback submitted')));
  }

  @override
  Widget build(BuildContext context) {
    final appointments = myAppointments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(title: const Text("My Appointments")),
      body: appointments.isEmpty
          ? const Center(child: Text("No Appointments Yet"))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AppointmentCard(
                    appointment: appt,
                    statusColor: getStatusColor(appt.status),
                    onJoinCall:
                        appt.status == "confirmed" &&
                            appt.type.toLowerCase() == "online" &&
                            appt.callStarted &&
                            appt.callEndedAt == null
                        ? () => _joinVideoCall(appt)
                        : null,
                    onGiveFeedback:
                        appt.status == "confirmed" && !appt.feedbackSubmitted
                        ? () => _showFeedbackDialog(appt)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green.shade200;
      case "rejected":
        return Colors.red.shade200;
      case "rescheduled":
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade300;
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Color statusColor;
  final VoidCallback? onJoinCall;
  final VoidCallback? onGiveFeedback;

  const _AppointmentCard({
    required this.appointment,
    required this.statusColor,
    this.onJoinCall,
    this.onGiveFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x120F172A),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Doctor",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Dr. ${appointment.doctorUsername}",
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: Icons.calendar_today_rounded,
                label: appointment.date,
              ),
              _MetaPill(icon: Icons.schedule_rounded, label: appointment.time),
              _MetaPill(
                icon: Icons.local_hospital_outlined,
                label: appointment.type,
              ),
            ],
          ),
          if (appointment.status == "rescheduled") ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text(
              "Rescheduled to",
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaPill(
                  icon: Icons.event_repeat_rounded,
                  label: appointment.rescheduledDate ?? "-",
                ),
                _MetaPill(
                  icon: Icons.more_time_rounded,
                  label: appointment.rescheduledTime ?? "-",
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          if (onJoinCall != null &&
              appointment.status == "confirmed" &&
              appointment.type.toLowerCase() == "online" &&
              appointment.callStarted &&
              appointment.callEndedAt == null) ...[
            ElevatedButton(
              onPressed: onJoinCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Join video call'),
            ),
            if (appointment.callStartedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                "Call started: ${appointment.callStartedAt!.toLocal()}"
                    .split('.')
                    .first,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],

          if (onGiveFeedback != null &&
              appointment.status == "confirmed" &&
              !appointment.feedbackSubmitted)
            ElevatedButton(
              onPressed: onGiveFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Give feedback'),
            ),

          if (appointment.feedbackSubmitted)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (appointment.feedbackRating != null)
                    Text('Rating: ${appointment.feedbackRating}/5'),
                  if (appointment.feedbackComments?.isNotEmpty == true)
                    Text('Comments: ${appointment.feedbackComments}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
