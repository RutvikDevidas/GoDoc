import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/patient_model.dart';

class PatientEditProfileScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientEditProfileScreen({super.key, required this.patient});

  @override
  State<PatientEditProfileScreen> createState() =>
      _PatientEditProfileScreenState();
}

class _PatientEditProfileScreenState extends State<PatientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController name;
  late final TextEditingController username;
  late final TextEditingController dob;
  late final TextEditingController address;
  late final TextEditingController email;
  late final TextEditingController phone;
  final TextEditingController reportController = TextEditingController();
  String? pendingReportAttachmentData;
  String? pendingReportAttachmentName;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.patient.name);
    username = TextEditingController(text: widget.patient.username);
    dob = TextEditingController(text: widget.patient.dob);
    address = TextEditingController(text: widget.patient.address);
    email = TextEditingController(text: widget.patient.email);
    phone = TextEditingController(text: widget.patient.phone);
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    dob.dispose();
    address.dispose();
    email.dispose();
    phone.dispose();
    reportController.dispose();
    super.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    widget.patient.name = name.text.trim();
    widget.patient.username = username.text.trim();
    widget.patient.dob = dob.text.trim();
    widget.patient.address = address.text.trim();
    widget.patient.email = email.text.trim();
    widget.patient.phone = phone.text.trim();

    await FirestoreDataService.instance.savePatient(widget.patient);
    await FirestoreDataService.instance.syncAllToAppState();
    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      widget.patient.profileImageData = base64Encode(bytes);
    });
  }

  Future<void> _pickReportAttachment() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      pendingReportAttachmentData = base64Encode(bytes);
      pendingReportAttachmentName = file.name;
    });
  }

  void _addReport() {
    final report = reportController.text.trim();
    if (report.isEmpty) return;

    setState(() {
      widget.patient.medicalReports.add(
        MedicalReport(
          title: report,
          attachmentData: pendingReportAttachmentData,
          attachmentName: pendingReportAttachmentName,
        ),
      );
      reportController.clear();
      pendingReportAttachmentData = null;
      pendingReportAttachmentName = null;
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
          child: Container(
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
                Row(
                  children: [
                    _PatientAvatar(imageData: widget.patient.profileImageData),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickProfilePhoto,
                        child: const Text("Set profile photo"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                _buildField(username, "Username"),
                _buildField(
                  dob,
                  "Date of birth",
                  readOnly: true,
                  onTap: _pickDate,
                ),
                _buildField(email, "Email", keyboardType: TextInputType.emailAddress),
                _buildField(phone, "Phone number", keyboardType: TextInputType.phone),
                _buildField(address, "Address", maxLines: 3),
                const SizedBox(height: 8),
                const Text(
                  "Medical reports",
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reportController,
                        decoration: const InputDecoration(
                          labelText: "Add report name",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: OutlinedButton(
                        onPressed: _pickReportAttachment,
                        child: const Text("Photo"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 88,
                      child: ElevatedButton(
                        onPressed: _addReport,
                        child: const Text("Add"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (pendingReportAttachmentName != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pendingReportAttachmentName!,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              pendingReportAttachmentData = null;
                              pendingReportAttachmentName = null;
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                if (widget.patient.medicalReports.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "No reports added yet.",
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  )
                else
                  Column(
                    children: widget.patient.medicalReports
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EditableReportCard(
                              report: entry.value,
                              onDelete: () {
                                setState(() {
                                  widget.patient.medicalReports.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("Save changes"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: readOnly ? const Icon(Icons.calendar_today_rounded) : null,
        ),
      ),
    );
  }
}

class _PatientAvatar extends StatelessWidget {
  final String? imageData;

  const _PatientAvatar({required this.imageData});

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
              Icons.person_rounded,
              color: AppColors.primary,
              size: 34,
            )
          : Image.memory(imageBytes, fit: BoxFit.cover),
    );
  }
}

class _EditableReportCard extends StatelessWidget {
  final MedicalReport report;
  final VoidCallback onDelete;

  const _EditableReportCard({
    required this.report,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final attachmentBytes = report.attachmentData == null
        ? null
        : base64Decode(report.attachmentData!);

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
              const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (attachmentBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                attachmentBytes,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              "No photo attached",
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}
