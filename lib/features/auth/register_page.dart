import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/models/user_role.dart';

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
  File? profileImage;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
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
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!)
                      : null,
                  child: profileImage == null
                      ? const Icon(Icons.camera_alt)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              if (isPatient) _patientFields(),
              if (!isPatient) _doctorFields(),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text("Register")),
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
        if (dob != null)
          Text(
            "Age: $age years",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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

    if (profileImage == null || dob == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Complete all fields")));
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // Create Auth account
      final cred = await auth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      // Upload image
      final ref = storage.ref().child('profile_images/$uid.jpg');
      await ref.putFile(profileImage!);
      final imageUrl = await ref.getDownloadURL();

      if (role == UserRole.patient) {
        // Unique username check
        final existing = await firestore
            .collection('patients')
            .where('username', isEqualTo: usernameCtrl.text.trim())
            .get();

        if (existing.docs.isNotEmpty) {
          throw Exception("Username already exists");
        }

        await firestore.collection('users').doc(uid).set({
          'role': 'patient',
          'isVerified': true,
          'profileImage': imageUrl,
          'createdAt': Timestamp.now(),
        });

        await firestore.collection('patients').doc(uid).set({
          'name': nameCtrl.text,
          'username': usernameCtrl.text,
          'dob': dob,
          'age': age,
          'address': addressCtrl.text,
          'email': emailCtrl.text,
          'phone': phoneCtrl.text,
        });
      } else {
        await firestore.collection('users').doc(uid).set({
          'role': 'doctor',
          'isVerified': false,
          'profileImage': imageUrl,
          'createdAt': Timestamp.now(),
        });

        await firestore.collection('doctors').doc(uid).set({
          'name': nameCtrl.text,
          'clinicName': clinicNameCtrl.text,
          'address': addressCtrl.text,
          'clinicAddress': clinicAddressCtrl.text,
          'dob': dob,
          'licenseNo': licenseCtrl.text,
          'prNumber': prCtrl.text,
          'specialization': specializationCtrl.text,
          'experience': experienceCtrl.text,
          'kmcNumber': kmcCtrl.text,
          'isVerified': false,
        });

        await firestore.collection('doctor_verifications').doc(uid).set({
          'status': 'pending',
          'submittedAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
