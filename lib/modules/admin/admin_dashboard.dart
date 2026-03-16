import 'package:flutter/material.dart';
import 'dart:convert';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';
import '../auth/unified_login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncAdminData();
  }

  Future<void> _syncAdminData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await FirestoreDataService.instance.syncAllToAppState();
    } catch (_) {
      // Keep the dashboard usable even if Firebase is unavailable.
    }

    if (!mounted) return;
    setState(() {
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOverview(),
      _buildDoctors(),
      _buildPatients(),
      _buildAppointments(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Administration",
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
            Text(
              _titleForIndex(selectedIndex),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
            onPressed: _isSyncing ? null : _syncAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Logout",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFB), AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.mutedText,
            type: BottomNavigationBarType.fixed,
            onTap: (i) {
              setState(() {
                selectedIndex = i;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: "Overview",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.verified_user_outlined),
                activeIcon: Icon(Icons.verified_user_rounded),
                label: "Doctors",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: "Patients",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: "Visits",
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
        return "Doctor approvals";
      case 2:
        return "Patient directory";
      case 3:
        return "Appointment log";
      default:
        return "Admin control center";
    }
  }

  Widget _buildOverview() {
    final totalDoctors = AppState.doctors.length;
    final verifiedDoctors = AppState.doctors.where((d) => d.verified).length;
    final pendingDoctors = AppState.doctors
        .where((d) => !d.verified && !d.rejected)
        .length;
    final rejectedDoctors = AppState.doctors.where((d) => d.rejected).length;
    final totalPatients = AppState.patients.length;
    final totalAppointments = AppState.appointments.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminHeroCard(
            pendingDoctors: pendingDoctors,
            totalAppointments: totalAppointments,
          ),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetricCard(
                  title: "Doctors",
                  value: totalDoctors.toString(),
                  subtitle: "All registered",
                  icon: Icons.medical_services_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 14),
                _MetricCard(
                  title: "Verified",
                  value: verifiedDoctors.toString(),
                  subtitle: "Approved doctors",
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 14),
                _MetricCard(
                  title: "Pending",
                  value: pendingDoctors.toString(),
                  subtitle: "Need attention",
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 14),
                _MetricCard(
                  title: "Patients",
                  value: totalPatients.toString(),
                  subtitle: "User accounts",
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF0F3C73),
                ),
                const SizedBox(width: 14),
                _MetricCard(
                  title: "Rejected",
                  value: rejectedDoctors.toString(),
                  subtitle: "Review outcomes",
                  icon: Icons.block_rounded,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Priority queue",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          _PriorityCard(
            icon: Icons.verified_user_rounded,
            title: "Doctor verification",
            subtitle:
                pendingDoctors == 0
                    ? "All doctor applications are currently reviewed."
                    : "$pendingDoctors doctor application(s) are waiting for approval.",
          ),
          const SizedBox(height: 14),
          _PriorityCard(
            icon: Icons.calendar_month_rounded,
            title: "Platform activity",
            subtitle:
                "$totalAppointments total appointment(s) are currently tracked across the app.",
          ),
        ],
      ),
    );
  }

  Widget _buildDoctors() {
    final doctors = AppState.doctors;
    final pendingDoctors = doctors
        .where((doctor) => !doctor.verified && !doctor.rejected)
        .toList();
    final verifiedDoctors =
        doctors.where((doctor) => doctor.verified).toList();
    final rejectedDoctors =
        doctors.where((doctor) => doctor.rejected).toList();

    if (doctors.isEmpty) {
      return const _EmptyState(message: "No doctors registered yet.");
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _DoctorSection(
          title: "Pending approval",
          subtitle: "Doctors waiting for admin review",
          count: pendingDoctors.length,
          emptyMessage: "No pending doctor approvals.",
          children: pendingDoctors
              .map(
                (doctor) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DoctorReviewCard(
                    doctor: doctor,
                    onVerify: () {
                      setState(() {
                        doctor.verified = true;
                        doctor.rejected = false;
                      });
                    },
                    onReject: () {
                      setState(() {
                        doctor.rejected = true;
                        doctor.verified = false;
                      });
                    },
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _DoctorSection(
          title: "Verified doctors",
          subtitle: "Approved and active doctor profiles",
          count: verifiedDoctors.length,
          emptyMessage: "No verified doctors yet.",
          children: verifiedDoctors
              .map(
                (doctor) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DoctorReviewCard(
                    doctor: doctor,
                    onVerify: () {},
                    onReject: () {
                      setState(() {
                        doctor.rejected = true;
                        doctor.verified = false;
                      });
                    },
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _DoctorSection(
          title: "Rejected doctors",
          subtitle: "Profiles that were not approved",
          count: rejectedDoctors.length,
          emptyMessage: "No rejected doctors.",
          children: rejectedDoctors
              .map(
                (doctor) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DoctorReviewCard(
                    doctor: doctor,
                    onVerify: () {
                      setState(() {
                        doctor.verified = true;
                        doctor.rejected = false;
                      });
                    },
                    onReject: () {},
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPatients() {
    final patients = AppState.patients;

    if (patients.isEmpty) {
      return const _EmptyState(message: "No patients found.");
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PatientDirectoryCard(patient: patient),
        );
      },
    );
  }

  Widget _buildAppointments() {
    final appointments = AppState.appointments;
    final confirmedAppointments = appointments
        .where((appointment) => appointment.status == "confirmed")
        .toList();
    final pendingAppointments = appointments
        .where((appointment) => appointment.status == "pending")
        .toList();
    final rejectedAppointments = appointments
        .where((appointment) => appointment.status == "rejected")
        .toList();
    final rescheduledAppointments = appointments
        .where((appointment) => appointment.status == "rescheduled")
        .toList();

    if (appointments.isEmpty) {
      return const _EmptyState(message: "No appointments yet.");
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _DoctorSection(
          title: "Confirmed visits",
          subtitle: "Appointments that are ready to proceed",
          count: confirmedAppointments.length,
          emptyMessage: "No confirmed appointments.",
          children: confirmedAppointments
              .map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AppointmentLogCard(appointment: appt),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _DoctorSection(
          title: "Pending visits",
          subtitle: "Appointments waiting for doctor action",
          count: pendingAppointments.length,
          emptyMessage: "No pending appointments.",
          children: pendingAppointments
              .map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AppointmentLogCard(appointment: appt),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _DoctorSection(
          title: "Rejected visits",
          subtitle: "Appointments that were declined",
          count: rejectedAppointments.length,
          emptyMessage: "No rejected appointments.",
          children: rejectedAppointments
              .map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AppointmentLogCard(appointment: appt),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _DoctorSection(
          title: "Rescheduled visits",
          subtitle: "Appointments moved to a new time",
          count: rescheduledAppointments.length,
          emptyMessage: "No rescheduled appointments.",
          children: rescheduledAppointments
              .map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AppointmentLogCard(appointment: appt),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  final int pendingDoctors;
  final int totalAppointments;

  const _AdminHeroCard({
    required this.pendingDoctors,
    required this.totalAppointments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF082F49), AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "Operations overview",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Monitor approvals, keep records organized, and stay ahead of platform activity.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "The admin workspace gives you a quick pulse on doctors, patients, and appointment flow.",
            style: TextStyle(
              color: Color(0xFFD7F0EC),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _HeroChip(
                  label: "Pending approvals",
                  value: pendingDoctors.toString(),
                ),
              ),
              SizedBox(
                width: 220,
                child: _HeroChip(
                  label: "Appointments tracked",
                  value: totalAppointments.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroChip({required this.label, required this.value});

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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PriorityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorReviewCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _DoctorReviewCard({
    required this.doctor,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = doctor.verified
        ? "Verified"
        : doctor.rejected
            ? "Rejected"
            : "Pending review";
    final statusColor = doctor.verified
        ? AppColors.success
        : doctor.rejected
            ? AppColors.danger
            : AppColors.warning;
    final imageBytes = doctor.profileImageData == null
        ? null
        : base64Decode(doctor.profileImageData!);

    return Container(
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
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes == null
                    ? const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : Image.memory(imageBytes, fit: BoxFit.cover),
              ),
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DetailRow(label: "Username", value: doctor.username),
          _DetailRow(label: "Clinic", value: doctor.clinicName),
          _DetailRow(label: "Phone", value: doctor.phone),
          _DetailRow(label: "PR / NMC", value: "${doctor.prNumber} / ${doctor.nmcNumber}"),
          _DetailRow(label: "Licence", value: doctor.licenceNumber),
          if (!doctor.verified && !doctor.rejected) ...[
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;

                if (compact) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: onVerify,
                        child: const Text("Verify"),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text("Reject"),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onVerify,
                        child: const Text("Verify"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else if (doctor.verified) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              child: const Text("Move to rejected"),
            ),
          ] else if (doctor.rejected) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onVerify,
              child: const Text("Approve now"),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoctorSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final String emptyMessage;
  final List<Widget> children;

  const _DoctorSection({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.emptyMessage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (children.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.mutedText,
                height: 1.5,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _PatientDirectoryCard extends StatelessWidget {
  final PatientModel patient;

  const _PatientDirectoryCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final imageBytes = patient.profileImageData == null
        ? null
        : base64Decode(patient.profileImageData!);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes == null
                ? Center(
                    child: Text(
                      patient.name.isNotEmpty ? patient.name[0].toUpperCase() : "P",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  )
                : Image.memory(imageBytes, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  patient.email,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 6),
                Text(
                  patient.phone,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              "${patient.medicalReports.length} reports",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentLogCard extends StatelessWidget {
  final dynamic appointment;

  const _AppointmentLogCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (appointment.status) {
      "confirmed" => AppColors.success,
      "rejected" => AppColors.danger,
      "rescheduled" => AppColors.warning,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  "${appointment.date} at ${appointment.time}",
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(label: "Doctor", value: appointment.doctorUsername),
          _DetailRow(label: "Patient", value: appointment.patientUsername),
          _DetailRow(label: "Type", value: appointment.type),
          if (appointment.rescheduledDate != null &&
              appointment.rescheduledTime != null)
            _DetailRow(
              label: "Rescheduled to",
              value: "${appointment.rescheduledDate} at ${appointment.rescheduledTime}",
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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
              value,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
