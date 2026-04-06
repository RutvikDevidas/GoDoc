import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../auth/unified_login_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_notification_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDashboard({super.key, required this.doctor});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int selectedIndex = 0;

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 430;

    final appointments = AppState.appointments
        .where((appointment) => appointment.doctorUsername == widget.doctor.username)
        .toList();

    final pending = appointments.where((item) => item.status == "pending").length;
    final confirmed =
        appointments.where((item) => item.status == "confirmed").length;
    final completed =
        appointments.where((item) => item.status == "completed").length;
    final rescheduled =
        appointments.where((item) => item.status == "rescheduled").length;

    final pages = [
      _buildHome(
        appointments: appointments,
        pending: pending,
        confirmed: confirmed,
        completed: completed,
        rescheduled: rescheduled,
        isCompact: isCompact,
      ),
      DoctorAppointmentsScreen(doctor: widget.doctor),
      const DoctorNotificationsScreen(),
      DoctorProfileScreen(doctor: widget.doctor),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: isCompact ? 72 : 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Doctor workspace",
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
            Text(
              _titleForIndex(selectedIndex),
              style: TextStyle(
                fontSize: isCompact ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Logout",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 10 : 16,
          0,
          isCompact ? 10 : 16,
          18,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: "Visits",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                activeIcon: Icon(Icons.notifications_rounded),
                label: "Alerts",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return "Appointments";
      case 2:
        return "Alerts center";
      case 3:
        return "Doctor profile";
      default:
        return "Dashboard overview";
    }
  }

  Widget _buildHome({
    required List<AppointmentModel> appointments,
    required int pending,
    required int confirmed,
    required int completed,
    required int rescheduled,
    required bool isCompact,
  }) {
    final totalPatients = appointments
        .map((appointment) => appointment.patientUsername)
        .toSet()
        .length;

    final nextAppointment = appointments.isNotEmpty ? appointments.first : null;
    final appointmentsToday = appointments.take(3).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7FBFA), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(
              totalAppointments: appointments.length,
              confirmed: confirmed,
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MetricCard(
                    label: "Pending",
                    value: pending.toString(),
                    caption: "Needs review",
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    label: "Confirmed",
                    value: confirmed.toString(),
                    caption: "Ready to consult",
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    label: "Completed",
                    value: completed.toString(),
                    caption: "Waiting for feedback",
                    color: const Color(0xFF2563EB),
                    icon: Icons.task_alt_rounded,
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    label: "Patients",
                    value: totalPatients.toString(),
                    caption: "Unique patients",
                    color: AppColors.primary,
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(width: 14),
                  _MetricCard(
                    label: "Rescheduled",
                    value: rescheduled.toString(),
                    caption: "Needs follow-up",
                    color: AppColors.danger,
                    icon: Icons.update_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _GlassInfoCard(
              title: "Today at a glance",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightRow(
                    icon: Icons.medical_services_rounded,
                    label: "Consultation fee",
                    value:
                        "Rs. ${widget.doctor.consultationFee.toStringAsFixed(0)}",
                  ),
                  const SizedBox(height: 14),
                  _HighlightRow(
                    icon: Icons.location_on_outlined,
                    label: "Clinic location",
                    value: widget.doctor.clinicLocation,
                  ),
                  const SizedBox(height: 14),
                  _HighlightRow(
                    icon: Icons.phone_outlined,
                    label: "Contact",
                    value: widget.doctor.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Quick actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 14),
            isCompact
                ? Column(
                    children: [
                      _ActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: "Manage bookings",
                        subtitle: "Confirm, reject, or reschedule requests.",
                        onTap: () => setState(() => selectedIndex = 1),
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.notifications_active_rounded,
                        title: "Check alerts",
                        subtitle: "See new updates from patients instantly.",
                        onTap: () => setState(() => selectedIndex = 2),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.calendar_month_rounded,
                          title: "Manage bookings",
                          subtitle: "Confirm, reject, or reschedule requests.",
                          onTap: () => setState(() => selectedIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.notifications_active_rounded,
                          title: "Check alerts",
                          subtitle: "See new updates from patients instantly.",
                          onTap: () => setState(() => selectedIndex = 2),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 14),
            _WideActionBanner(
              onTap: () => setState(() => selectedIndex = 3),
              doctor: widget.doctor,
            ),
            const SizedBox(height: 28),
            const Text(
              "Upcoming visits",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 14),
            if (appointmentsToday.isNotEmpty)
              ...appointmentsToday.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AppointmentPreviewCard(appointment: appointment),
                ),
              )
            else
              const _EmptyStateCard(
                title: "No appointments yet",
                message:
                    "Once patients book with you, upcoming sessions will show here.",
              ),
            if (nextAppointment != null) ...[
              const SizedBox(height: 14),
              _NextFocusCard(appointment: nextAppointment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required int totalAppointments,
    required int confirmed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final statWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 18 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF063939), AppColors.primary, Color(0xFF2A8C7C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 24 : 30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 28,
                offset: const Offset(0, 16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      "Care dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFFD7F0EC),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.doctor.verified ? "Verified" : "Under review",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 54 : 60,
                    height: compact ? 54 : 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: compact ? 26 : 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 20 : 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.doctor.specialization} | ${widget.doctor.clinicName}",
                          style: TextStyle(
                            color: const Color(0xFFD7F0EC),
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Stay on top of consultations, keep patients informed, and manage your day with less friction at ${widget.doctor.clinicName}.",
                style: TextStyle(
                  color: const Color(0xFFD7F0EC),
                  fontSize: compact ? 14 : 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: statWidth,
                    child: _HeroStat(
                      label: "Appointments",
                      value: totalAppointments.toString(),
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _HeroStat(
                      label: "Confirmed",
                      value: confirmed.toString(),
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _HeroStat(
                      label: "Specialty",
                      value: widget.doctor.specialization,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;

    return Container(
      width: compact ? 144 : 160,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: compact ? 26 : 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A102A43),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE7F8F4), Color(0xFFD9F0EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Text(
                  "Open",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPreviewCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentPreviewCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            appointment.patientUsername,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appointment.type,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                "${appointment.date} at ${appointment.time}",
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inbox_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _HeroStat({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD7F0EC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 15 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassInfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassInfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6FBFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 20,
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WideActionBanner extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const _WideActionBanner({
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D4D4D), AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Profile polish",
                    style: TextStyle(
                      color: Color(0xFFD7F0EC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Keep ${doctor.clinicName} up to date for better patient trust.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextFocusCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _NextFocusCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F4),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Next focus",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Prepare for ${appointment.patientUsername}'s ${appointment.type.toLowerCase()} consultation.",
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

