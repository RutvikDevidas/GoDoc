import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/models/user_role.dart';
import '../patient/shell/patient_shell.dart';
import '../doctor/shell/doctor_shell.dart';

class RegisterPage extends StatefulWidget {
  final UserRole initialRole;

  const RegisterPage({super.key, required this.initialRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late UserRole role;

  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final clinicNameCtrl = TextEditingController();
  final clinicAddressCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  final prCtrl = TextEditingController();
  final specializationCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();
  final kmcCtrl = TextEditingController();

  DateTime? dob;
  XFile? pickedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    clinicNameCtrl.dispose();
    clinicAddressCtrl.dispose();
    licenseCtrl.dispose();
    prCtrl.dispose();
    specializationCtrl.dispose();
    experienceCtrl.dispose();
    kmcCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => pickedImage = image);
    }
  }

  Future<void> pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  int get age => dob == null ? 0 : DateTime.now().year - dob!.year;

  @override
  Widget build(BuildContext context) {
    final isPatient = role == UserRole.patient;

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _roleToggle(),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: pickedImage != null
                      ? FileImage(File(pickedImage!.path))
                      : null,
                  child: pickedImage == null
                      ? const Icon(Icons.camera_alt)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              if (isPatient) _patientFields(),
              if (!isPatient) _doctorFields(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleToggle() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile(
            title: const Text("Patient"),
            value: UserRole.patient,
            groupValue: role,
            onChanged: (value) => setState(() => role = value!),
          ),
        ),
        Expanded(
          child: RadioListTile(
            title: const Text("Doctor"),
            value: UserRole.doctor,
            groupValue: role,
            onChanged: (value) => setState(() => role = value!),
          ),
        ),
      ],
    );
  }

  Widget _patientFields() {
    return Column(
      children: [
        _field(nameCtrl, "Full Name"),
        _field(usernameCtrl, "Username (unique)"),
        _field(addressCtrl, "Address"),
        _field(emailCtrl, "Email"),
        _field(phoneCtrl, "Phone"),
        _dateField(),
        if (dob != null) Text("Age: $age years"),
        _field(passwordCtrl, "Password", obscure: true),
      ],
    );
  }

  Widget _doctorFields() {
    return Column(
      children: [
        _field(nameCtrl, "Doctor Name"),
        _field(clinicNameCtrl, "Clinic Name"),
        _field(addressCtrl, "Residential Address"),
        _field(clinicAddressCtrl, "Clinic Address"),
        _dateField(),
        _field(licenseCtrl, "License No"),
        _field(prCtrl, "PR Number"),
        _field(specializationCtrl, "Specialization"),
        _field(experienceCtrl, "Experience (years)"),
        _field(kmcCtrl, "KMC Number"),
        _field(emailCtrl, "Email"),
        _field(passwordCtrl, "Password", obscure: true),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        validator: (v) => v == null || v.isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dateField() {
    return ListTile(
      title: Text(
        dob == null
            ? "Select DOB"
            : "DOB: ${dob!.day}/${dob!.month}/${dob!.year}",
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: pickDOB,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (pickedImage == null || dob == null) {
      _showError("Complete all fields");
      return;
    }

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // Fake loading

    if (!mounted) return;

    // 🚀 Direct redirect (frontend only)
    if (role == UserRole.patient) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PatientShell()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DoctorShell()),
        (_) => false,
      );
    }

    setState(() => isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
