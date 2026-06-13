// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../video_call/video_call_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorAppointmentsScreen({super.key, required this.doctor});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  List<AppointmentModel> get myAppointments => AppState.appointments
      .where((a) => a.doctorUsername == widget.doctor.username)
      .toList();

  List<AppointmentModel> get newAppointments => myAppointments
      .where(
        (a) =>
            a.status == "pending" ||
            a.status == "confirmed" ||
            a.status == "rescheduled",
      )
      .toList();

  List<AppointmentModel> get completedAppointments =>
      myAppointments.where((a) => a.status == "completed").toList();

  List<AppointmentModel> get rejectedAppointments => myAppointments
      .where((a) => a.status == "rejected" || a.status == "cancelled")
      .toList();

  DateTime? _parseAppointmentDate(String value) {
    try {
      return DateFormat('d MMMM yyyy').parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  bool _removeCompletedSlotFromAvailability(AppointmentModel appt) {
    final appointmentDate = _parseAppointmentDate(appt.date);
    if (appointmentDate == null) return false;
    return widget.doctor.removeTimeSlotFromDate(appointmentDate, appt.time);
  }

  Future<void> confirmAppointment(AppointmentModel appt) async {
    final requiresOnlinePayment = appt.type.toLowerCase() == "online";
    final hasOnlinePayment =
        appt.paymentStatus.toLowerCase() == "paid" &&
        (appt.paymentReference?.trim().isNotEmpty ?? false);

    if (requiresOnlinePayment && !hasOnlinePayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Online consultation cannot be confirmed until payment is completed.",
          ),
        ),
      );
      return;
    }

    setState(() {
      appt.status = "confirmed";
    });

    await FirestoreDataService.instance.saveAppointment(appt);
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.patientNotifications.add(
      "Your appointment has been confirmed by Dr. ${widget.doctor.name}.",
    );
    if (!mounted) return;
    TopSnackbar.show(
      context,
      message: 'Appointment confirmed for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.success,
    );
  }

  Future<void> rejectAppointment(AppointmentModel appt) async {
    setState(() {
      appt.status = "rejected";
      _applyFullRefundIfOnline(
        appt,
        reason: "Doctor rejected the online consultation.",
      );
    });

    await FirestoreDataService.instance.saveAppointment(appt);
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.patientNotifications.add(
      appt.type.toLowerCase() == "online"
          ? "Your online consultation was rejected. A 100% fee refund has been issued."
          : "Your appointment has been rejected.",
    );
    if (!mounted) return;
    TopSnackbar.show(
      context,
      message: 'Appointment rejected for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.warning,
    );
  }

  Future<void> cancelAppointment(AppointmentModel appt) async {
    setState(() {
      appt.status = "cancelled";
      _applyFullRefundIfOnline(
        appt,
        reason: "Doctor cancelled the online consultation.",
      );
    });

    await FirestoreDataService.instance.saveAppointment(appt);
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.patientNotifications.add(
      appt.type.toLowerCase() == "online"
          ? "Your online consultation was cancelled. A 100% fee refund has been issued."
          : "Your appointment has been cancelled by the doctor.",
    );
    if (!mounted) return;
    TopSnackbar.show(
      context,
      message: 'Appointment cancelled for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.warning,
    );
  }

  Future<void> rescheduleAppointment(AppointmentModel appt) async {
    String? newDate = await showDatePickerDialog();
    if (newDate == null) return;

    String? newTime = await showTimePickerDialog();
    if (newTime == null) return;

    setState(() {
      appt.status = "rescheduled";
      appt.rescheduledDate = newDate;
      appt.rescheduledTime = newTime;
    });

    await FirestoreDataService.instance.saveAppointment(appt);
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.patientNotifications.add("Your appointment has been rescheduled");
    if (!mounted) return;
    TopSnackbar.show(
      context,
      message: 'Appointment rescheduled for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.info,
    );
  }

  Future<void> completeAppointment(AppointmentModel appt) async {
    final removedFromAvailability = _removeCompletedSlotFromAvailability(appt);

    setState(() {
      appt.status = "completed";
      appt.completedAt = DateTime.now();
      appt.callStarted = false;
      appt.callEndedAt ??= appt.completedAt;
    });

    await FirestoreDataService.instance.saveAppointment(appt);
    if (removedFromAvailability) {
      await FirestoreDataService.instance.saveDoctor(widget.doctor);
    }
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.patientNotifications.add(
      "Your appointment with Dr. ${widget.doctor.name} has been marked completed. You can now leave feedback.",
    );
    if (!mounted) return;
    TopSnackbar.show(
      context,
      message: 'Appointment completed for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.success,
    );
  }

  void _applyFullRefundIfOnline(
    AppointmentModel appt, {
    required String reason,
  }) {
    if (appt.type.toLowerCase() != "online") {
      appt.refundIssued = false;
      appt.refundPercentage = 0;
      appt.refundReason = null;
      appt.refundedAt = null;
      return;
    }

    appt.refundIssued = true;
    appt.refundPercentage = 100;
    appt.refundReason = reason;
    appt.refundedAt = DateTime.now();
  }

  Future<void> _startVideoCall(AppointmentModel appt) async {
    final currentContext = context;

    if (appt.callRoom == null || appt.callRoom!.isEmpty) {
      appt.callRoom = "godoc-${appt.id}";
    }

    appt.callStarted = true;
    appt.callStartedAt = DateTime.now();
    appt.callEndedAt = null;

    try {
      // Persist the call state so patient can join.
      await FirestoreDataService.instance.saveAppointment(appt);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved call state locally, but database sync failed: $error',
            ),
          ),
        );
      }
    }

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
    try {
      await FirestoreDataService.instance.saveAppointment(appt);
    } catch (_) {}

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

  PatientModel? _findPatient(String username) {
    for (final patient in AppState.patients) {
      if (patient.username == username) {
        return patient;
      }
    }
    return null;
  }

  void _openPatientProfile(AppointmentModel appt) {
    final patient = _findPatient(appt.patientUsername);

    if (patient == null) {
      TopSnackbar.show(
        context,
        message: 'Patient profile not found for ${appt.patientUsername}.',
        variant: TopSnackbarVariant.warning,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DoctorPatientProfileScreen(patient: patient),
      ),
    );
  }

  Future<void> _updateMedicalReport(AppointmentModel appt) async {
    final titleController = TextEditingController();
    String? attachmentData;
    String? attachmentName;
    var isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickAttachment() async {
              final file = await _imagePicker.pickImage(
                source: ImageSource.gallery,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              setDialogState(() {
                attachmentData = base64Encode(bytes);
                attachmentName = file.name;
              });
            }

            return AlertDialog(
              title: const Text('Update medical report'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient: ${appt.patientUsername}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Report summary',
                        hintText: 'Diagnosis, prescription, or follow-up note',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: isSaving ? null : pickAttachment,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        attachmentName == null
                            ? 'Attach image'
                            : 'Change attachment',
                      ),
                    ),
                    if (attachmentName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        attachmentName!,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          await FirestoreDataService.instance
                              .addMedicalReportForPatient(
                                patientUsername: appt.patientUsername,
                                report: MedicalReport(
                                  title: title,
                                  attachmentData: attachmentData,
                                  attachmentName: attachmentName,
                                ),
                              );
                          await FirestoreDataService.instance
                              .syncAllToAppState();

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Save report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;
    TopSnackbar.show(
      context,
      message: 'Medical report updated for ${appt.patientUsername}.',
      variant: TopSnackbarVariant.success,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget buildSection(String title, List<AppointmentModel> appointments) {
      if (appointments.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ...appointments.map(
            (appt) => Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openPatientProfile(appt),
                child: Container(
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
                  child: buildAppointmentCard(appt),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSection("New Requests", newAppointments),
              buildSection("Completed", completedAppointments),
              buildSection("Rejected / Cancelled", rejectedAppointments),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppointmentCard(AppointmentModel appt) {
    final patient = _findPatient(appt.patientUsername);
    final imageBytes = patient?.profileImageData?.isNotEmpty == true
        ? base64Decode(patient!.profileImageData!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(imageBytes, fit: BoxFit.cover)
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                patient?.name.isNotEmpty == true
                    ? patient!.name
                    : appt.patientUsername,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text(appt.status),
              backgroundColor: getStatusColor(appt.status),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("Username: ${appt.patientUsername}"),
        Text("Date: ${appt.date}"),
        Text("Time: ${appt.time}"),
        Text("Type: ${appt.type}"),
        Text("Payment: ${appt.paymentStatus}"),
        Text("Amount: Rs ${appt.paymentAmount.toStringAsFixed(0)}"),
        if (appt.paymentReference?.isNotEmpty == true)
          Text("Reference: ${appt.paymentReference}"),
        if (appt.status == "rescheduled") ...[
          const SizedBox(height: 8),
          Text("New Date: ${appt.rescheduledDate}"),
          Text("New Time: ${appt.rescheduledTime}"),
        ],
        if (appt.refundIssued) ...[
          const SizedBox(height: 8),
          Text("Refund: ${appt.refundPercentage.toStringAsFixed(0)}% issued"),
          if (appt.refundReason?.isNotEmpty == true)
            Text("Reason: ${appt.refundReason}"),
        ],
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: () => _openPatientProfile(appt),
          icon: const Icon(Icons.person_outline_rounded),
          label: const Text("View Profile"),
        ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _updateMedicalReport(appt),
          icon: const Icon(Icons.description_rounded),
          label: const Text("Update Medical Report"),
        ),
        if (appt.status == "confirmed" && appt.type.toLowerCase() == "online")
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
                  "Call ended: ${appt.callEndedAt!.toLocal()}".split('.').first,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => cancelAppointment(appt),
                child: const Text("Cancel Online Consultation"),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => completeAppointment(appt),
                child: const Text("Completed"),
              ),
            ],
          ),
        if (appt.status == "confirmed" && appt.type.toLowerCase() != "online")
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => completeAppointment(appt),
                child: const Text("Completed"),
              ),
            ],
          ),
        if (appt.status == "completed") ...[
          Text(
            "Completed at: ${appt.completedAt?.toLocal().toString().split('.').first ?? '-'}",
          ),
          if (appt.feedbackSubmitted) ...[
            const SizedBox(height: 8),
            Text("Patient feedback: ${appt.feedbackRating ?? '-'} / 5"),
            if (appt.feedbackComments?.isNotEmpty == true)
              Text("Comments: ${appt.feedbackComments}"),
          ],
        ],
      ],
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green.shade200;
      case "rejected":
        return Colors.red.shade200;
      case "completed":
        return Colors.blue.shade200;
      case "rescheduled":
        return Colors.orange.shade200;
      case "cancelled":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade300;
    }
  }
}

class _DoctorPatientProfileScreen extends StatelessWidget {
  final PatientModel patient;

  const _DoctorPatientProfileScreen({required this.patient});

  void _openProfileImage(BuildContext context, Uint8List imageBytes) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(imageBytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: "Close",
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = patient.profileImageData == null
        ? null
        : base64Decode(patient.profileImageData!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(title: const Text("Patient Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3C73), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: imageBytes == null
                        ? null
                        : () => _openProfileImage(context, imageBytes),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageBytes == null
                          ? Center(
                              child: Text(
                                patient.name.isNotEmpty
                                    ? patient.name[0].toUpperCase()
                                    : "P",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : Image.memory(imageBytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          patient.username,
                          style: const TextStyle(
                            color: Color(0xFFD7F0EC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DoctorInfoSection(
              title: "Patient details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DoctorInfoRow(label: "Name", value: patient.name),
                  _DoctorInfoRow(label: "Date of birth", value: patient.dob),
                  _DoctorInfoRow(label: "Email", value: patient.email),
                  _DoctorInfoRow(label: "Phone", value: patient.phone),
                  _DoctorInfoRow(label: "Address", value: patient.address),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DoctorInfoSection(
              title: "Medical reports",
              child: patient.medicalReports.isEmpty
                  ? const Text(
                      "No medical reports available.",
                      style: TextStyle(color: AppColors.mutedText, height: 1.5),
                    )
                  : Column(
                      children: patient.medicalReports
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _DoctorMedicalReportCard(report: report),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DoctorInfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DoctorInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DoctorInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorMedicalReportCard extends StatelessWidget {
  final MedicalReport report;

  const _DoctorMedicalReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final attachmentBytes = report.attachmentData == null
        ? null
        : base64Decode(report.attachmentData!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (attachmentBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                attachmentBytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              "Text-only medical note",
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}
