import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/doctor_model.dart';
import 'doctor_edit_profile_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorEditProfileScreen(doctor: doctor),
                ),
              );
              if (mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.edit_rounded),
            tooltip: "Edit profile",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: doctor.profileImageData == null
                            ? const Icon(
                                Icons.local_hospital_rounded,
                                size: 36,
                                color: Colors.white,
                              )
                            : Image.memory(
                                base64Decode(doctor.profileImageData!),
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              doctor.specialization,
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
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Badge(
                        icon: Icons.location_on_outlined,
                        label: doctor.clinicLocation,
                      ),
                      _Badge(
                        icon: Icons.currency_rupee_rounded,
                        label: "Rs. ${doctor.consultationFee.toStringAsFixed(0)}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _InfoSection(
              title: "Clinic details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: "Clinic", value: doctor.clinicName),
                  _InfoRow(label: "Address", value: doctor.clinicAddress),
                  _InfoRow(label: "Location", value: doctor.clinicLocation),
                  _InfoRow(label: "Phone", value: doctor.phone),
                  _InfoRow(label: "UPI ID", value: doctor.upiId),
                  _InfoRow(
                    label: "Consultation fee",
                    value: "Rs. ${doctor.consultationFee.toStringAsFixed(0)}",
                  ),
                  if (doctor.clinicLatitude != null &&
                      doctor.clinicLongitude != null) ...[
                    const SizedBox(height: 8),
                    _LocationPreviewCard(
                      latitude: doctor.clinicLatitude!,
                      longitude: doctor.clinicLongitude!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: "Bio",
              child: Text(
                doctor.bio,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: "Available schedule",
              child: doctor.availability.isEmpty
                  ? const Text(
                      "No available slots right now. Add a new day and time slot from Edit Profile.",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    )
                  : Column(
                      children: doctor.availability
                          .map(
                            (slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 68,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      DateFormat('dd\nMMM').format(slot.date),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE').format(slot.date),
                                          style: const TextStyle(
                                            color: AppColors.darkText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          slot.timeSlots.join(" | "),
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

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreviewCard extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _LocationPreviewCard({
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F3FF), Color(0xFFE8F8F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ProfileMapPainter()),
          ),
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.danger,
              size: 30,
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Text(
              "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}",
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

class _ProfileMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x332F6E6E)
      ..strokeWidth = 1;

    for (double x = 20; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 20; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
