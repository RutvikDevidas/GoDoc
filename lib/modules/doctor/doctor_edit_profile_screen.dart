import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/doctor_model.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorEditProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController name;
  late final TextEditingController username;
  late final TextEditingController specialization;
  late final TextEditingController phone;
  late final TextEditingController clinicName;
  late final TextEditingController clinicAddress;
  late final TextEditingController clinicLocation;
  late final TextEditingController bio;
  late final TextEditingController upiId;
  late final TextEditingController consultationFee;
  late List<DoctorAvailability> availability;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.doctor.name);
    username = TextEditingController(text: widget.doctor.username);
    specialization = TextEditingController(text: widget.doctor.specialization);
    phone = TextEditingController(text: widget.doctor.phone);
    clinicName = TextEditingController(text: widget.doctor.clinicName);
    clinicAddress = TextEditingController(text: widget.doctor.clinicAddress);
    clinicLocation = TextEditingController(text: widget.doctor.clinicLocation);
    bio = TextEditingController(text: widget.doctor.bio);
    upiId = TextEditingController(text: widget.doctor.upiId);
    consultationFee = TextEditingController(
      text: widget.doctor.consultationFee.toStringAsFixed(0),
    );
    availability = widget.doctor.availability
        .map(
          (slot) => DoctorAvailability(
            date: slot.date,
            timeSlots: List<String>.from(slot.timeSlots),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    specialization.dispose();
    phone.dispose();
    clinicName.dispose();
    clinicAddress.dispose();
    clinicLocation.dispose();
    bio.dispose();
    upiId.dispose();
    consultationFee.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    widget.doctor.name = name.text.trim();
    widget.doctor.username = username.text.trim();
    widget.doctor.specialization = specialization.text.trim();
    widget.doctor.phone = phone.text.trim();
    widget.doctor.clinicName = clinicName.text.trim();
    widget.doctor.clinicAddress = clinicAddress.text.trim();
    widget.doctor.clinicLocation = clinicLocation.text.trim();
    widget.doctor.bio = bio.text.trim();
    widget.doctor.upiId = upiId.text.trim();
    widget.doctor.consultationFee =
        double.tryParse(consultationFee.text.trim()) ?? widget.doctor.consultationFee;
    widget.doctor.availability = availability
        .map(
          (slot) => DoctorAvailability(
            date: slot.date,
            timeSlots: List<String>.from(slot.timeSlots),
          ),
        )
        .toList();

    await FirestoreDataService.instance.saveDoctor(widget.doctor);
    await FirestoreDataService.instance.syncAllToAppState();
    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      widget.doctor.profileImageData = base64Encode(bytes);
    });
  }

  Future<void> _addAvailabilityDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return;

    setState(() {
      availability.add(
        DoctorAvailability(
          date: DateTime(picked.year, picked.month, picked.day),
          timeSlots: <String>[],
        ),
      );
      availability.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Future<void> _addTimeSlot(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      availability[index].timeSlots.add(picked.format(context));
    });
  }

  void _removeAvailabilityDay(int index) {
    setState(() {
      availability.removeAt(index);
    });
  }

  void _removeTimeSlot(int dayIndex, int slotIndex) {
    setState(() {
      availability[dayIndex].timeSlots.removeAt(slotIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormSection(
                title: "Profile photo",
                child: Row(
                  children: [
                    _ProfileAvatar(imageData: widget.doctor.profileImageData),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickProfilePhoto,
                        child: const Text("Upload profile photo"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: "Personal details",
                child: Column(
                  children: [
                    _buildField(name, "Full name"),
                    _buildField(username, "Username"),
                    _buildField(specialization, "Specialization"),
                    _buildField(phone, "Phone number", keyboardType: TextInputType.phone),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: "Clinic details",
                child: Column(
                  children: [
                    _buildField(clinicName, "Clinic name"),
                    _buildField(clinicAddress, "Clinic address", maxLines: 2),
                    _buildField(clinicLocation, "Clinic location"),
                    _buildField(
                      consultationFee,
                      "Consultation fee",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildField(upiId, "UPI ID"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: "About you",
                child: _buildField(bio, "Bio", maxLines: 5),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: "Schedule",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (availability.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No schedule added yet. Add an available day to get started.",
                          style: TextStyle(
                            color: AppColors.mutedText,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      ...availability.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AvailabilityEditorCard(
                            availability: entry.value,
                            onAddSlot: () => _addTimeSlot(entry.key),
                            onRemoveDay: () => _removeAvailabilityDay(entry.key),
                            onRemoveSlot: (slotIndex) =>
                                _removeTimeSlot(entry.key, slotIndex),
                          ),
                        ),
                      ),
                    OutlinedButton(
                      onPressed: _addAvailabilityDay,
                      child: const Text("Add available day"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({required this.title, required this.child});

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

class _ProfileAvatar extends StatelessWidget {
  final String? imageData;

  const _ProfileAvatar({required this.imageData});

  @override
  Widget build(BuildContext context) {
    final imageBytes = imageData == null ? null : base64Decode(imageData!);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes == null
          ? const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.primary,
              size: 34,
            )
          : Image.memory(imageBytes, fit: BoxFit.cover),
    );
  }
}

class _AvailabilityEditorCard extends StatelessWidget {
  final DoctorAvailability availability;
  final VoidCallback onAddSlot;
  final VoidCallback onRemoveDay;
  final ValueChanged<int> onRemoveSlot;

  const _AvailabilityEditorCard({
    required this.availability,
    required this.onAddSlot,
    required this.onRemoveDay,
    required this.onRemoveSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(availability.date),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemoveDay,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (availability.timeSlots.isEmpty)
            const Text(
              "No time slots added yet.",
              style: TextStyle(color: AppColors.mutedText),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availability.timeSlots.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  onDeleted: () => onRemoveSlot(entry.key),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAddSlot,
            child: const Text("Add time slot"),
          ),
        ],
      ),
    );
  }
}
