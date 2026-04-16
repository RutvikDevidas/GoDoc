import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../core/firebase/firebase_state.dart';
import '../../models/doctor_model.dart';
import '../shared/clinic_location_picker_screen.dart';
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
  final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{4,20}$');
  final _phonePattern = RegExp(r'^[0-9]{7,15}$');
  final _credentialPattern = RegExp(r'^[A-Za-z0-9/-]{4,30}$');

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

  Future<void> _pickClinicLocation() async {
    final result = await Navigator.push<ClinicLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicLocationPickerScreen(
          initialLatitude: selectedLatitude,
          initialLongitude: selectedLongitude,
          initialAddress: clinicAddress.text.trim().isEmpty
              ? null
              : clinicAddress.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      selectedLatitude = result.latitude;
      selectedLongitude = result.longitude;
      clinicAddress.text = result.address;
    });
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _hasValues([username, password, name, dob]) &&
            _validateAccountStep();
      case 1:
        return _hasValues([prNumber, nmcNumber, licenceNumber]) &&
            _validateProfessionalStep() &&
            _validateSpecialization();
      case 2:
        return _hasValues([phone, clinicName, clinicAddress]) &&
            _validateClinicStep() &&
            _validateClinicLocation();
      default:
        return false;
    }
  }

  bool _hasValues(List<TextEditingController> controllers) {
    final hasMissing = controllers.any(
      (controller) => controller.text.trim().isEmpty,
    );
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

  bool _validateAccountStep() {
    if (!_usernamePattern.hasMatch(username.text.trim())) {
      _showMessage(
        "Username must be 4-20 characters using letters, numbers, or _.",
      );
      return false;
    }
    if (password.text.trim().length < 6) {
      _showMessage("Password must be at least 6 characters.");
      return false;
    }
    return true;
  }

  bool _validateProfessionalStep() {
    final values = [
      prNumber.text.trim(),
      nmcNumber.text.trim(),
      licenceNumber.text.trim(),
    ];
    if (values.any((value) => !_credentialPattern.hasMatch(value))) {
      _showMessage(
        "Professional IDs should be 4-30 characters and only use letters, numbers, - or /.",
      );
      return false;
    }
    return true;
  }

  bool _validateClinicStep() {
    if (!_phonePattern.hasMatch(phone.text.trim())) {
      _showMessage("Enter a valid phone number.");
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateClinicLocation() {
    if (selectedLatitude != null && selectedLongitude != null) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select the clinic location on the map."),
      ),
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

  Future<void> addDoctor() async {
    if (!_validateStep(2)) return;

    // Prevent duplicate usernames before writing the doctor document.
    final usernameTaken = await FirestoreDataService.instance.usernameExists(
      username.text.trim(),
    ).timeout(const Duration(seconds: 8));
    if (usernameTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username already exists. Try another one."),
        ),
      );
      return;
    }

    final duplicateCredential =
        await FirestoreDataService.instance.duplicateDoctorCredentialLabel(
          prNumber: prNumber.text.trim(),
          nmcNumber: nmcNumber.text.trim(),
          licenceNumber: licenceNumber.text.trim(),
        ).timeout(const Duration(seconds: 8));
    if (duplicateCredential != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$duplicateCredential already exists. Please enter a unique value.",
          ),
        ),
      );
      return;
    }

    try {
      // Store the current form values directly from the existing controllers.
      await FirebaseFirestore.instance
          .collection("GODOC-app")
          .doc("data")
          .collection("doctors")
          .doc(username.text.trim())
          .set({
            "username": username.text.trim(),
            "password": password.text.trim(),
            "name": name.text.trim(),
            "dob": dob.text.trim(),
            "prNumber": prNumber.text.trim(),
            "nmcNumber": nmcNumber.text.trim(),
            "licenceNumber": licenceNumber.text.trim(),
            "specialization": specialization.text.trim(),
            "phone": phone.text.trim(),
            "clinicName": clinicName.text.trim(),
            "clinicAddress": clinicAddress.text.trim(),
            "clinicLocation": _clinicLocationLabel,
            "clinicLatitude": selectedLatitude,
            "clinicLongitude": selectedLongitude,
            "bio":
                "${name.text.trim()} is a trusted ${specialization.text.trim()} offering patient-focused care, clear guidance, and consistent follow-up through ${clinicName.text.trim()}.",
            "upiId": "",
            "bankAccountHolder": "",
            "bankName": "",
            "bankAccountNumber": "",
            "bankIfscCode": "",
            "profileImageData": null,
            "consultationFee": 500,
            "availability": [
              DoctorAvailability(
                date: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ).add(const Duration(days: 1)),
                timeSlots: const ["10:00 AM", "11:00 AM", "01:30 PM"],
              ),
              DoctorAvailability(
                date: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ).add(const Duration(days: 2)),
                timeSlots: const ["09:30 AM", "12:00 PM", "03:30 PM"],
              ),
              DoctorAvailability(
                date: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ).add(const Duration(days: 4)),
                timeSlots: const ["10:30 AM", "02:00 PM", "05:00 PM"],
              ),
            ].map((slot) => slot.toMap()).toList(),
            "verified": false,
            "rejected": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor data saved successfully.")),
        );
      }
      try {
        await FirestoreDataService.instance
            .syncAllToAppState()
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save to Firestore. ${error.toString()}"),
          ),
        );
      }
      return;
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

  Future<void> _submit() async {
    await addDoctor();
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
            _buildField(
              phone,
              "Phone number",
              keyboardType: TextInputType.phone,
            ),
            _buildField(clinicName, "Clinic name"),
            _buildField(clinicAddress, "Clinic address", maxLines: 3),
            const SizedBox(height: 4),
            _MapSelectionHint(label: _clinicLocationLabel),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickClinicLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.map_outlined, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Choose clinic location",
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedLatitude == null || selectedLongitude == null
                          ? "Open the map picker to pin your clinic for patients."
                          : "Pinned at ${selectedLatitude!.toStringAsFixed(4)}, ${selectedLongitude!.toStringAsFixed(4)}",
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _pickClinicLocation,
                        icon: const Icon(Icons.place_outlined),
                        label: const Text("Open map picker"),
                      ),
                    ),
                  ],
                ),
              ),
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
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      ),
    );
  }

  Widget _buildSpecializationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedSpecialization,
        items: _specializations
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedSpecialization = value;
            specialization.text = value ?? "";
          });
        },
        decoration: const InputDecoration(labelText: "Specialization"),
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
            style: const TextStyle(color: AppColors.mutedText, height: 1.5),
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
