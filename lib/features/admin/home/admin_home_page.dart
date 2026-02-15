import 'package:flutter/material.dart';

import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/doctor_registry_store.dart';
import '../../../shared/stores/notification_store.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6E4FF), Color(0xFFC7DAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Admin Dashboard",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: NotificationStore.itemsVN,
                  builder: (_, __, ___) {
                    final unread = NotificationStore.unreadCount();
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: DoctorRegistryStore.doctorsVN,
              builder: (_, __, ___) {
                final pendingDoctors =
                    DoctorRegistryStore.pendingForAdmin().length;
                final verifiedDoctors =
                    DoctorRegistryStore.visibleForPatients().length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Pending Doctors",
                            pendingDoctors.toString(),
                            Icons.pending_actions_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            "Verified Doctors",
                            verifiedDoctors.toString(),
                            Icons.verified_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ValueListenableBuilder(
                      valueListenable: AppointmentStore.itemsVN,
                      builder: (_, __, ___) {
                        final totalAppts = AppointmentStore.all().length;
                        final upcoming = AppointmentStore.upcoming().length;

                        return Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                "Appointments",
                                totalAppts.toString(),
                                Icons.event_note_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                "Upcoming",
                                upcoming.toString(),
                                Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1E5BFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1E5BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.black.withOpacity(0.65)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
