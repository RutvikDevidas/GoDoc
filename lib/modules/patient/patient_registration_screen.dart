import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/patient_model.dart';
import 'patient_home_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{4,20}$');
  final _phonePattern = RegExp(r'^[0-9]{7,15}$');

  final name = TextEditingController();
  final dob = TextEditingController();
  final address = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();

  String? profileImageData;
  bool _isLoading = false;

  @override
  void dispose() {
    name.dispose();
    dob.dispose();
    address.dispose();
    email.dispose();
    username.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      profileImageData = base64Encode(bytes);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dob.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> addPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      try {
        // Check whether the entered username already exists.
        final usernameTaken = await FirestoreDataService.instance
            .usernameExists(username.text.trim())
            .timeout(const Duration(seconds: 8));
        if (usernameTaken) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Username already exists. Try another one."),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      } catch (error) {
        // If Firebase is unavailable, continue with local save
        print('Error checking username: $error');
      }

      try {
        // Save the patient using the existing controllers and image state.
        await FirebaseFirestore.instance
            .collection("GODOC-app")
            .doc("data")
            .collection("patients")
            .doc(username.text.trim())
            .set({
              "username": username.text.trim(),
              "password": password.text.trim(),
              "name": name.text.trim(),
              "dob": dob.text.trim(),
              "address": address.text.trim(),
              "email": email.text.trim(),
              "phone": phone.text.trim(),
              "profileImagePath": null,
              "profileImageData": profileImageData,
              "medicalReports": <Map<String, dynamic>>[],
              "createdAt": FieldValue.serverTimestamp(),
              "updatedAt": FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 8));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient data saved successfully.")),
          );
        }
        try {
          await FirestoreDataService.instance.syncAllToAppState().timeout(
            const Duration(seconds: 8),
          );
        } catch (_) {}
      } catch (error) {
        print('Error saving to Firebase: $error');
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

      final patient2 = PatientModel(
        username: username.text.trim(),
        password: password.text.trim(),
        name: name.text.trim(),
        dob: dob.text.trim(),
        address: address.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        profileImageData: profileImageData,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PatientHomeScreen(patient: patient2)),
        (route) => false,
      );
    } catch (error) {
      print('Unexpected error in registration: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${error.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    await addPatient();
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
                Form(
                  key: _formKey,
                  child: Container(
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
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: _ProfilePicker(imageData: profileImageData),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Personal details",
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(name, "Full name"),
                        _buildField(
                          dob,
                          "Date of birth",
                          readOnly: true,
                          onTap: _pickDate,
                          suffixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                        _buildField(address, "Address", maxLines: 3),
                        _buildField(
                          email,
                          "Email",
                          keyboardType: TextInputType.emailAddress,
                          extraValidator: (value) =>
                              _emailPattern.hasMatch(value)
                              ? null
                              : "Enter a valid email",
                        ),
                        _buildField(
                          phone,
                          "Phone number",
                          keyboardType: TextInputType.phone,
                          extraValidator: (value) =>
                              _phonePattern.hasMatch(value)
                              ? null
                              : "Enter a valid phone number",
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Account setup",
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          username,
                          "Username",
                          extraValidator: (value) =>
                              _usernamePattern.hasMatch(value)
                              ? null
                              : "Use 4-20 letters, numbers, or _",
                        ),
                        _buildField(
                          password,
                          "Password",
                          obscure: true,
                          extraValidator: (value) => value.length >= 6
                              ? null
                              : "Password must be at least 6 characters",
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Create patient account"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Patient registration",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Create your account to manage appointments, reports, and your health profile in one place.",
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

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String value)? extraValidator,
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
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return "Required";
          return extraValidator?.call(trimmed);
        },
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      ),
    );
  }
}

class _ProfilePicker extends StatelessWidget {
  final String? imageData;

  const _ProfilePicker({required this.imageData});

  @override
  Widget build(BuildContext context) {
    final bytes = imageData == null ? null : base64Decode(imageData!);

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null)
            Image.memory(bytes, fit: BoxFit.cover)
          else
            const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 42,
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
