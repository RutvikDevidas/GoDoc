import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';
import '../auth/unified_login_screen.dart';
import 'doctor_detail_screen.dart';
import 'patient_appointments_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_notification_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientHomeScreen({super.key, required this.patient});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int selectedIndex = 0;
  String? selectedCategory;
  final TextEditingController searchController = TextEditingController();

  final Set<String> _notifiedCallIds = {};
  StreamSubscription<List<AppointmentModel>>? _appointmentSubscription;
  StreamSubscription<List<DoctorModel>>? _doctorSubscription;

  List<DoctorModel> get _verifiedDoctors =>
      AppState.doctors.where((doctor) => doctor.verified).toList();

  List<DoctorModel> get _filteredDoctors {
    final query = searchController.text.trim().toLowerCase();

    return _verifiedDoctors.where((doctor) {
      final matchesCategory = selectedCategory == null
          ? true
          : _matchesCategory(doctor.specialization, selectedCategory!);
      final matchesQuery = query.isEmpty
          ? true
          : doctor.name.toLowerCase().contains(query) ||
                doctor.specialization.toLowerCase().contains(query) ||
                doctor.clinicName.toLowerCase().contains(query) ||
                doctor.clinicAddress.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  int get _upcomingAppointments => AppState.appointments
      .where(
        (appointment) => appointment.patientUsername == widget.patient.username,
      )
      .where(
        (appointment) =>
            appointment.status == "confirmed" ||
            appointment.status == "pending",
      )
      .length;

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      (route) => false,
    );
  }

  void _openAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAppointmentsScreen(patient: widget.patient),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientNotificationsScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientProfileScreen(patient: widget.patient),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _subscribeToDoctorUpdates();
    _subscribeToAppointmentUpdates();
  }

  @override
  void dispose() {
    _doctorSubscription?.cancel();
    _appointmentSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _subscribeToDoctorUpdates() {
    _doctorSubscription = FirestoreDataService.instance.watchDoctors().listen((
      doctors,
    ) {
      AppState.doctors = doctors;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _subscribeToAppointmentUpdates() {
    _appointmentSubscription = FirestoreDataService.instance
        .watchAppointments(patientUsername: widget.patient.username)
        .listen((appointments) {
          // Keep AppState in sync for the rest of the UI.
          AppState.appointments = appointments;

          for (final appt in appointments) {
            final shouldNotify =
                appt.callStarted &&
                appt.callEndedAt == null &&
                !_notifiedCallIds.contains(appt.id);
            if (shouldNotify && mounted) {
              _notifiedCallIds.add(appt.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Video call ready for Dr. ${appt.doctorUsername}',
                  ),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientAppointmentsScreen(
                            patient: widget.patient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }

          if (mounted) setState(() {});
        });
  }

  bool _matchesCategory(String specialization, String category) {
    final normalizedSpecialization = specialization.toLowerCase();

    switch (category) {
      case "Cardiology":
        return normalizedSpecialization.contains("cardio");
      case "Neurology":
        return normalizedSpecialization.contains("neuro");
      case "General":
        return normalizedSpecialization.contains("general");
      case "Pediatrics":
        return normalizedSpecialization.contains("pediatric");
      case "Dermatology":
        return normalizedSpecialization.contains("derma");
      default:
        return normalizedSpecialization.contains(category.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            16,
            compact ? 16 : 20,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildHeroCard(),
              const SizedBox(height: 28),
              _buildSectionTitle("Care categories", "Explore specialties"),
              const SizedBox(height: 14),
              SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ServiceCard(
                      icon: Icons.favorite_outline_rounded,
                      title: "Cardiology",
                      selected: selectedCategory == "Cardiology",
                      onTap: () =>
                          setState(() => selectedCategory = "Cardiology"),
                    ),
                    ServiceCard(
                      icon: Icons.psychology_outlined,
                      title: "Neurology",
                      selected: selectedCategory == "Neurology",
                      onTap: () =>
                          setState(() => selectedCategory = "Neurology"),
                    ),
                    ServiceCard(
                      icon: Icons.medical_services_outlined,
                      title: "General",
                      selected: selectedCategory == "General",
                      onTap: () => setState(() => selectedCategory = "General"),
                    ),
                    ServiceCard(
                      icon: Icons.child_care_outlined,
                      title: "Pediatrics",
                      selected: selectedCategory == "Pediatrics",
                      onTap: () =>
                          setState(() => selectedCategory = "Pediatrics"),
                    ),
                    ServiceCard(
                      icon: Icons.healing_outlined,
                      title: "Dermatology",
                      selected: selectedCategory == "Dermatology",
                      onTap: () =>
                          setState(() => selectedCategory = "Dermatology"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildDoctorsHeader(),
              const SizedBox(height: 14),
              if (_filteredDoctors.isEmpty)
                const _EmptyDoctorsState()
              else
                ..._filteredDoctors.map(
                  (doctor) => DoctorCard(
                    doctor: doctor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorDetailScreen(
                            doctor: doctor,
                            patient: widget.patient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });

            if (index == 1) {
              _openAppointments();
            } else if (index == 2) {
              _openProfile();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: "Appointments",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accent,
                  backgroundImage: widget.patient.profileImageData == null
                      ? null
                      : MemoryImage(
                          base64Decode(widget.patient.profileImageData!),
                        ),
                  child: widget.patient.profileImageData == null
                      ? Text(
                          widget.patient.name.isNotEmpty
                              ? widget.patient.name[0]
                              : "P",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Patient workspace",
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Hello, ${widget.patient.name}",
                        style: TextStyle(
                          fontSize: compact ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TopActionButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: _openNotifications,
                ),
                _TopActionButton(icon: Icons.logout_rounded, onTap: _logout),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Container(
          padding: EdgeInsets.all(compact ? 18 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 24 : 30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.22),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Find the right doctor, faster.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Manage appointments, browse trusted specialists, and keep your health journey organized.",
                style: TextStyle(
                  color: const Color(0xFFD7F0EC),
                  fontSize: compact ? 14 : 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Search by doctor or specialty",
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
            Text(subtitle, style: const TextStyle(color: AppColors.mutedText)),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorsHeader() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedCategory == null ? "Top doctors" : selectedCategory!,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedCategory == null
                  ? "Verified specialists"
                  : "Doctors matching your selected category",
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
        if (selectedCategory != null)
          TextButton(
            onPressed: () => setState(() => selectedCategory = null),
            child: const Text("All doctors"),
          ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 120,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.16)
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.darkText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDoctorsState extends StatelessWidget {
  const _EmptyDoctorsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.primary, size: 34),
          SizedBox(height: 12),
          Text(
            "No doctors found in this category",
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try another specialty or switch back to all doctors.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const DoctorCard({super.key, required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDoctorText()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildArrow(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDoctorText()),
                      const SizedBox(width: 10),
                      _buildArrow(),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
  );

  Widget _buildDoctorText() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        doctor.name,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 6),
      Text(
        doctor.specialization,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              doctor.clinicAddress,
              style: const TextStyle(color: AppColors.mutedText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildArrow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
  );
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.darkText),
      ),
    );
  }
}
