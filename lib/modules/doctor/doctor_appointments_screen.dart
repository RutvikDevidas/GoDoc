// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../video_call/video_call_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorAppointmentsScreen({super.key, required this.doctor});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<AppointmentModel> get myAppointments => AppState.appointments
      .where((a) => a.doctorUsername == widget.doctor.username)
      .toList();

  void confirmAppointment(AppointmentModel appt) {
    setState(() {
      appt.status = "confirmed";
    });

    AppState.notifications.add("Your appointment has been confirmed");
  }

  void rejectAppointment(AppointmentModel appt) {
    setState(() {
      appt.status = "rejected";
    });

    AppState.notifications.add("Your appointment has been rejected");
  }

  void rescheduleAppointment(AppointmentModel appt) async {
    String? newDate = await showDatePickerDialog();
    if (newDate == null) return;

    String? newTime = await showTimePickerDialog();
    if (newTime == null) return;

    setState(() {
      appt.status = "rescheduled";
      appt.rescheduledDate = newDate;
      appt.rescheduledTime = newTime;
    });

    AppState.notifications.add("Your appointment has been rescheduled");
  }

  Future<void> _startVideoCall(AppointmentModel appt) async {
    final currentContext = context;

    if (appt.callRoom == null || appt.callRoom!.isEmpty) {
      appt.callRoom = "godoc-${appt.id}";
    }

    appt.callStarted = true;
    appt.callStartedAt = DateTime.now();
    appt.callEndedAt = null;

    // Persist the call state so patient can join.
    await FirestoreDataService.instance.saveAppointment(appt);

    if (!mounted) return;

    await Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callID: appt.callRoom ?? appt.id,
          userID: widget.doctor.username,
          userName: widget.doctor.name,
        ),
      ),
    );

    // Mark call ended when doctor leaves the call screen.
    appt.callEndedAt = DateTime.now();
    appt.callStarted = false;
    await FirestoreDataService.instance.saveAppointment(appt);

    // Refresh UI in case state changed elsewhere
    if (!mounted) return;
    setState(() {});
  }

  Future<String?> showDatePickerDialog() async {
    final currentContext = context;
    DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked == null) return null;

    return "${picked.day}/${picked.month}/${picked.year}";
  }

  Future<String?> showTimePickerDialog() async {
    final currentContext = context;
    TimeOfDay? picked = await showTimePicker(
      context: currentContext,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return null;

    return picked.format(currentContext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: myAppointments.length,
        itemBuilder: (context, index) {
          final appt = myAppointments[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appt.patientUsername,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(appt.status),
                      backgroundColor: getStatusColor(appt.status),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text("Date: ${appt.date}"),
                Text("Time: ${appt.time}"),
                Text("Type: ${appt.type}"),

                if (appt.status == "rescheduled") ...[
                  const SizedBox(height: 8),
                  Text("New Date: ${appt.rescheduledDate}"),
                  Text("New Time: ${appt.rescheduledTime}"),
                ],

                const SizedBox(height: 15),

                if (appt.status == "pending")
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () => confirmAppointment(appt),
                          child: const Text("Confirm"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => rejectAppointment(appt),
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () => rescheduleAppointment(appt),
                          child: const Text("Reschedule"),
                        ),
                      ),
                    ],
                  ),

                if (appt.status == "confirmed" &&
                    appt.type.toLowerCase() == "online")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () => _startVideoCall(appt),
                        child: Text(
                          (appt.callStarted && appt.callEndedAt == null)
                              ? "Rejoin Call"
                              : "Start Video Call",
                        ),
                      ),
                      if (appt.callStartedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Call started: ${appt.callStartedAt!.toLocal()}"
                              .split('.')
                              .first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (appt.callEndedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Call ended: ${appt.callEndedAt!.toLocal()}"
                              .split('.')
                              .first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
              ],
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
