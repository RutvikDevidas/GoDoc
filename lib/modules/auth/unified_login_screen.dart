import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../core/firebase/firebase_state.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';
import '../admin/admin_dashboard.dart';
import '../doctor/doctor_dashboard.dart';
import '../doctor/doctor_registration_screen.dart';
import '../patient/patient_home_screen.dart';
import '../patient/patient_registration_screen.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool isDoctor = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final user = username.text.trim();
    final pass = password.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter both username and password.")),
      );
      return;
    }

    if (user == "admin" && pass == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
      return;
    }

    if (isDoctor) {
      DoctorModel? doctor;
      try {
        doctor = await FirestoreDataService.instance.findDoctorByCredentials(
          username: user,
          password: pass,
        );
      } catch (_) {
        doctor = AppState.doctors.where((d) => d.username == user && d.password == pass).firstOrNull;
      }

      if (!mounted) return;

      if (doctor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid doctor credentials.")),
        );
        return;
      }

      if (!doctor.verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor account is awaiting approval.")),
        );
        return;
      }

      try {
        await FirestoreDataService.instance.syncAllToAppState();
      } catch (_) {}
      if (!mounted) return;

      final resolvedDoctor = doctor;
      final syncedDoctor = AppState.doctors.firstWhere(
        (d) => d.username == resolvedDoctor.username,
        orElse: () => resolvedDoctor,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorDashboard(doctor: syncedDoctor)),
      );
      return;
    }

    PatientModel? patient;
    try {
      patient = await FirestoreDataService.instance.findPatientByCredentials(
        username: user,
        password: pass,
      );
    } catch (_) {
      patient = AppState.patients.where((p) => p.username == user && p.password == pass).firstOrNull;
    }

    if (!mounted) return;

    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid patient credentials.")),
      );
      return;
    }

    try {
      await FirestoreDataService.instance.syncAllToAppState();
    } catch (_) {}
    if (!mounted) return;

    final resolvedPatient = patient;
    final syncedPatient = AppState.patients.firstWhere(
      (p) => p.username == resolvedPatient.username,
      orElse: () => resolvedPatient,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PatientHomeScreen(patient: syncedPatient)),
    );
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isDoctor
            ? const DoctorRegistrationScreen()
            : const PatientRegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FBFA), Color(0xFFE8F3F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -40,
              child: _GlowCircle(
                size: 220,
                color: AppColors.secondary.withOpacity(0.18),
              ),
            ),
            Positioned(
              right: -70,
              bottom: 100,
              child: _GlowCircle(
                size: 260,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildLoginCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Container(
          padding: EdgeInsets.all(compact ? 20 : 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(compact ? 24 : 32),
            border: Border.all(color: Colors.white),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: compact ? 160 : 180,
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2F8FF), Color(0xFFF1FBF7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: _PortalPill(
                          icon: Icons.person_outline_rounded,
                          label: "Patient",
                          tint: Color(0xFFE7F3FF),
                          iconColor: Color(0xFF0F3C73),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _PortalPill(
                          icon: Icons.local_hospital_outlined,
                          label: "Doctor",
                          tint: Color(0xFFE4F7F2),
                          iconColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue to your patient or doctor workspace.",
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: compact ? 14 : 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: "Patient",
                        selected: !isDoctor,
                        onTap: () => setState(() => isDoctor = false),
                      ),
                    ),
                    Expanded(
                      child: _RoleChip(
                        label: "Doctor",
                        selected: isDoctor,
                        onTap: () => setState(() => isDoctor = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text(isDoctor ? "Login as Doctor" : "Login as Patient"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: goToRegister,
                child: Text(
                  isDoctor ? "Create doctor account" : "Create patient account",
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              if (!firebaseAvailable) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF4D58D)),
                  ),
                  child: Text(
                    "Firebase is offline for this run. $firebaseUnavailableMessage",
                    style: const TextStyle(
                      color: AppColors.darkText,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Admin sign-in is also available using the configured admin credentials.",
                      style: TextStyle(color: AppColors.mutedText, height: 1.4),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PortalPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final Color iconColor;

  const _PortalPill({
    required this.icon,
    required this.label,
    required this.tint,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.darkText : AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
