import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/models/user_role.dart';
import '../../shared/models/patient_profile.dart';
import '../../shared/stores/patient_profile_store.dart';
import '../../shared/stores/notification_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isDoctor = false;

  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();

  // doctor only
  final yearC = TextEditingController();
  final licenseC = TextEditingController();
  final clinicNameC = TextEditingController();
  final clinicAddressC = TextEditingController();
  final specializationC = TextEditingController();

  DateTime? dob;
  int age = 0;
  String? imagePath;

  // OTP mock
  String generatedOtp = "";
  final otpC = TextEditingController();

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    yearC.dispose();
    licenseC.dispose();
    clinicNameC.dispose();
    clinicAddressC.dispose();
    specializationC.dispose();
    otpC.dispose();
    super.dispose();
  }

  int calcAge(DateTime dob) {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (x == null) return;
    setState(() => imagePath = x.path);
  }

  void sendOtp() {
    if (phoneC.text.trim().length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid phone number")));
      return;
    }
    generatedOtp = "1234"; // demo OTP
    NotificationStore.add(
      "OTP Sent",
      "OTP generated for ${phoneC.text.trim()} is $generatedOtp",
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP sent (demo: 1234)")));
  }

  void register() {
    if (nameC.text.trim().isEmpty ||
        emailC.text.trim().isEmpty ||
        phoneC.text.trim().isEmpty ||
        dob == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    if (!isDoctor) {
      // patient needs OTP check
      if (otpC.text.trim() != generatedOtp) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
        return;
      }

      final profile = PatientProfile(
        name: nameC.text.trim(),
        email: emailC.text.trim(),
        phone: phoneC.text.trim(),
        dob:
            "${dob!.year}-${dob!.month.toString().padLeft(2, "0")}-${dob!.day.toString().padLeft(2, "0")}",
        age: age,
        imageUrl: imagePath ?? "",
      );

      PatientProfileStore.current = profile;

      NotificationStore.add("Registered ✅", "Patient registered successfully");
      Navigator.pop(context);
      return;
    }

    // doctor validate extras
    if (yearC.text.trim().isEmpty ||
        licenseC.text.trim().isEmpty ||
        clinicNameC.text.trim().isEmpty ||
        clinicAddressC.text.trim().isEmpty ||
        specializationC.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill doctor details")));
      return;
    }

    NotificationStore.add(
      "Doctor Registered (Pending)",
      "Doctor ${nameC.text.trim()} registered, waiting for admin verification.",
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDoctor ? "Doctor Register" : "Patient Register",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Switch(
                  value: isDoctor,
                  onChanged: (v) => setState(() => isDoctor = v),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _field("Name", nameC),
            const SizedBox(height: 10),
            _field("Email", emailC),
            const SizedBox(height: 10),
            _field("Phone", phoneC, keyboard: TextInputType.phone),
            const SizedBox(height: 12),

            _dobCard(),

            const SizedBox(height: 12),
            _imageCard(),

            if (!isDoctor) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: sendOtp,
                      child: const Text("Send OTP"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      "Enter OTP",
                      otpC,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            if (isDoctor) ...[
              const SizedBox(height: 14),
              const Text(
                "Doctor Details",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _field("Year of Passing", yearC, keyboard: TextInputType.number),
              const SizedBox(height: 10),
              _field("License No.", licenseC),
              const SizedBox(height: 10),
              _field("Clinic Name", clinicNameC),
              const SizedBox(height: 10),
              _field("Clinic Address", clinicAddressC),
              const SizedBox(height: 10),
              _field("Specialization", specializationC),
            ],

            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: register,
                child: const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dobCard() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2005, 1, 1),
          firstDate: DateTime(1950, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked == null) return;
        setState(() {
          dob = picked;
          age = calcAge(picked);
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dob == null
                    ? "Select DOB"
                    : "DOB: ${dob!.year}-${dob!.month.toString().padLeft(2, "0")}-${dob!.day.toString().padLeft(2, "0")}  (Age: $age)",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _imageCard() {
    return InkWell(
      onTap: pickImage,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: imagePath == null
                  ? const Icon(Icons.person)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(imagePath!), fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                imagePath == null ? "Pick Profile Image" : "Selected ✅",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.upload, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String hint,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
