import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/doctor_model.dart';
import 'doctor_success_screen.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  static const List<String> _specializations = [
    "Cardiologist",
    "Neurologist",
    "General Physician",
    "Dermatologist",
    "Pediatrician",
    "Orthopedic",
    "Gynecologist",
    "Dentist",
    "Psychiatrist",
    "ENT Specialist",
    "Ophthalmologist",
    "Urologist",
  ];

  final username = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final dob = TextEditingController();
  final prNumber = TextEditingController();
  final nmcNumber = TextEditingController();
  final licenceNumber = TextEditingController();
  final specialization = TextEditingController();
  final phone = TextEditingController();
  final clinicName = TextEditingController();
  final clinicAddress = TextEditingController();

  int currentStep = 0;
  String? selectedSpecialization;
  double? selectedLatitude;
  double? selectedLongitude;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    name.dispose();
    dob.dispose();
    prNumber.dispose();
    nmcNumber.dispose();
    licenceNumber.dispose();
    specialization.dispose();
    phone.dispose();
    clinicName.dispose();
    clinicAddress.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dob.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _hasValues([username, password, name, dob]);
      case 1:
        return _hasValues([prNumber, nmcNumber, licenceNumber]) &&
            _validateSpecialization();
      case 2:
        return _hasValues([phone, clinicName, clinicAddress]) &&
            _validateClinicLocation();
      default:
        return false;
    }
  }

  bool _hasValues(List<TextEditingController> controllers) {
    final hasMissing = controllers.any((controller) => controller.text.trim().isEmpty);
    if (!hasMissing) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please complete all fields on this step.")),
    );
    return false;
  }

  bool _validateSpecialization() {
    if (selectedSpecialization != null && selectedSpecialization!.isNotEmpty) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a specialization.")),
    );
    return false;
  }

  bool _validateClinicLocation() {
    if (selectedLatitude != null && selectedLongitude != null) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select the clinic location on the map.")),
    );
    return false;
  }

  void _nextStep() {
    if (!_validateStep(currentStep)) return;

    setState(() {
      currentStep += 1;
    });
  }

  void _previousStep() {
    setState(() {
      currentStep -= 1;
    });
  }

  Future<void> _submit() async {
    if (!_validateStep(2)) return;

    final doctor = DoctorModel(
      username: username.text.trim(),
      password: password.text.trim(),
      name: name.text.trim(),
      dob: dob.text.trim(),
      prNumber: prNumber.text.trim(),
      nmcNumber: nmcNumber.text.trim(),
      licenceNumber: licenceNumber.text.trim(),
      specialization: selectedSpecialization ?? "",
      phone: phone.text.trim(),
      clinicName: clinicName.text.trim(),
      clinicAddress: clinicAddress.text.trim(),
      clinicLocation: _clinicLocationLabel,
      clinicLatitude: selectedLatitude,
      clinicLongitude: selectedLongitude,
    );

    final usernameTaken = AppState.doctors.any(
      (existing) => existing.username == doctor.username,
    );
    if (usernameTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username already exists. Try another one.")),
      );
      return;
    }

    try {
      await FirestoreDataService.instance.saveDoctor(doctor);
      await FirestoreDataService.instance.syncAllToAppState();
    } catch (_) {
      AppState.doctors.add(doctor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Saved locally. Firebase sync is not available right now.",
            ),
          ),
        );
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DoctorSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFB), AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 20),
                _StepIndicator(currentStep: currentStep),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _StepPage(
                    key: ValueKey(currentStep),
                    title: _stepTitle(currentStep),
                    subtitle: _stepSubtitle(currentStep),
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text("Back"),
                        ),
                      ),
                    if (currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: currentStep == 2 ? _submit : _nextStep,
                        child: Text(
                          currentStep == 2 ? "Submit application" : "Continue",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 1:
        return "Professional credentials";
      case 2:
        return "Clinic details";
      default:
        return "Account setup";
    }
  }

  String _stepSubtitle(int step) {
    switch (step) {
      case 1:
        return "Add your registration and licence details for admin review.";
      case 2:
        return "Tell patients where you practice and how to contact you.";
      default:
        return "Start with your login credentials and basic identity details.";
    }
  }

  Widget _buildHeroCard() {
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
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doctor registration",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Complete your onboarding in a few clear steps so the admin team can review and approve your profile quickly.",
            style: TextStyle(
              color: Color(0xFFD7F0EC),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return Column(
          children: [
            _buildField(prNumber, "PR number"),
            _buildField(nmcNumber, "NMC number"),
            _buildField(licenceNumber, "Licence number"),
            _buildSpecializationDropdown(),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildField(phone, "Phone number", keyboardType: TextInputType.phone),
            _buildField(clinicName, "Clinic name"),
            _buildField(clinicAddress, "Clinic address", maxLines: 3),
            const SizedBox(height: 4),
            _MapSelectionHint(label: _clinicLocationLabel),
            const SizedBox(height: 12),
            _ClinicMapPicker(
              latitude: selectedLatitude,
              longitude: selectedLongitude,
              onChanged: (latitude, longitude) {
                setState(() {
                  selectedLatitude = latitude;
                  selectedLongitude = longitude;
                });
              },
            ),
          ],
        );
      default:
        return Column(
          children: [
            _buildField(username, "Username"),
            _buildField(password, "Password", obscure: true),
            _buildField(name, "Full name"),
            _buildField(
              dob,
              "Date of birth",
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.calendar_today_rounded),
            ),
          ],
        );
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSpecializationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedSpecialization,
        items: _specializations
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedSpecialization = value;
            specialization.text = value ?? "";
          });
        },
        decoration: const InputDecoration(
          labelText: "Specialization",
        ),
      ),
    );
  }

  String get _clinicLocationLabel {
    if (selectedLatitude == null || selectedLongitude == null) {
      return "Tap the map to pin your clinic location";
    }

    return "${selectedLatitude!.toStringAsFixed(4)}, ${selectedLongitude!.toStringAsFixed(4)}";
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ["Account", "Professional", "Clinic"];

    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == currentStep;
        final completed = index < currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 10,
                      decoration: BoxDecoration(
                        color: completed || active
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: active || completed
                            ? AppColors.darkText
                            : AppColors.mutedText,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != labels.length - 1) const SizedBox(width: 10),
            ],
          ),
        );
      }),
    );
  }
}

class _StepPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _MapSelectionHint extends StatelessWidget {
  final String label;

  const _MapSelectionHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClinicMapPicker extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onChanged;

  const _ClinicMapPicker({
    required this.latitude,
    required this.longitude,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 220.0;

        Offset? markerOffset;
        if (latitude != null && longitude != null) {
          final dx = ((longitude! - 68) / 29).clamp(0.0, 1.0) * width;
          final dy = ((37 - latitude!) / 29).clamp(0.0, 1.0) * height;
          markerOffset = Offset(dx, dy);
        }

        return GestureDetector(
          onTapDown: (details) {
            final dx = details.localPosition.dx.clamp(0.0, width);
            final dy = details.localPosition.dy.clamp(0.0, height);
            final longitude = 68 + (dx / width) * 29;
            final latitude = 37 - (dy / height) * 29;
            onChanged(latitude, longitude);
          },
          child: Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE7F3FF), Color(0xFFE8F8F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
                const Positioned(
                  left: 16,
                  top: 14,
                  child: Text(
                    "Clinic map",
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  top: 36,
                  child: Text(
                    "Tap to drop a location pin",
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (markerOffset != null)
                  Positioned(
                    left: markerOffset.dx - 14,
                    top: markerOffset.dy - 28,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.danger,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x332F6E6E)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = const Color(0x220B6E6E)
      ..strokeWidth = 3;

    for (double x = 24; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(22, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.38,
        size.width * 0.48,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.78,
        size.width - 18,
        size.height * 0.34,
      );

    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
