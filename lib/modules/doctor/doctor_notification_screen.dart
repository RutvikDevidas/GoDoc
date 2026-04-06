import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';

class DoctorNotificationsScreen extends StatelessWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = AppState.doctorNotifications.isNotEmpty
        ? List<String>.from(AppState.doctorNotifications.reversed)
        : [
            "New appointment booked",
            "Patient left feedback",
            "Admin verified your account",
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final message = notifications[index];

          return Padding(
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        index == 0
                            ? Icons.event_available_rounded
                            : index == 1
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.verified_rounded,
                        color: AppColors.primary,
                      ),
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
          );
        },
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
