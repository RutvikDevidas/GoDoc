import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../models/patient_model.dart';

class DoctorNotificationsScreen extends StatelessWidget {
  const DoctorNotificationsScreen({super.key});

  PatientModel? _findPatientFromMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;

    final firstToken = trimmed.split(RegExp(r'\s+')).first.trim();
    for (final patient in AppState.patients) {
      if (patient.username == firstToken) {
        return patient;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = AppState.doctorNotifications.isNotEmpty
        ? List<String>.from(AppState.doctorNotifications.reversed)
        : [
            "New appointment booked",
            "Patient left feedback",
            "Admin verified your account",
          ];

    // Categorize notifications
    final newAppointments = notifications
        .where(
          (msg) =>
              msg.toLowerCase().contains("appointment request") ||
              msg.toLowerCase().contains("new appointment"),
        )
        .toList();
    final paymentUpdates = notifications
        .where(
          (msg) =>
              msg.toLowerCase().contains("payment") ||
              msg.toLowerCase().contains("paid") ||
              msg.toLowerCase().contains("unpaid") ||
              msg.toLowerCase().contains("refund"),
        )
        .toList();
    final feedbacks = notifications
        .where((msg) => msg.toLowerCase().contains("feedback"))
        .toList();
    final others = notifications
        .where(
          (msg) =>
              !newAppointments.contains(msg) &&
              !paymentUpdates.contains(msg) &&
              !feedbacks.contains(msg),
        )
        .toList();

    Widget buildSection(String title, List<String> items, IconData icon) {
      if (items.isEmpty) return const SizedBox();
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
          ...items.map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: InkWell(
                onTap: () => _showNotificationDetails(context, message),
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0F172A),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationAvatar(
                        patient: _findPatientFromMessage(message),
                        fallbackIcon: icon,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Doctor activity",
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection(
              "New Appointments",
              newAppointments,
              Icons.event_available_rounded,
            ),
            buildSection(
              "Payment Updates",
              paymentUpdates,
              Icons.payment_rounded,
            ),
            buildSection(
              "Feedback",
              feedbacks,
              Icons.chat_bubble_outline_rounded,
            ),
            buildSection("Other", others, Icons.info_outline_rounded),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final PatientModel? patient;
  final IconData fallbackIcon;

  const _NotificationAvatar({
    required this.patient,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = patient?.profileImageData?.isNotEmpty == true
        ? base64Decode(patient!.profileImageData!)
        : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(imageBytes, fit: BoxFit.cover)
          : Icon(fallbackIcon, color: AppColors.primary),
    );
  }
}
