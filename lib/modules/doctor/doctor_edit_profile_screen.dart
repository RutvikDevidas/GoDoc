import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/doctor_model.dart';
import '../shared/clinic_location_picker_screen.dart';

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
  final _phonePattern = RegExp(r'^[0-9]{7,15}$');
  final _upiPattern = RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$');

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

  double? _selectedLatitude;
  double? _selectedLongitude;

  late List<DoctorWeeklyAvailability> weeklyAvailability;
  late List<DoctorAvailability> availabilityOverrides;

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

    _selectedLatitude = widget.doctor.clinicLatitude;
    _selectedLongitude = widget.doctor.clinicLongitude;

    weeklyAvailability = widget.doctor.weeklyAvailability
        .map(
          (slot) => DoctorWeeklyAvailability(
            weekday: slot.weekday,
            timeSlots: List<String>.from(slot.timeSlots),
          ),
        )
        .toList();
    availabilityOverrides =
        widget.doctor.availabilityOverrides
            .map(
              (slot) => DoctorAvailability(
                date: slot.date,
                timeSlots: List<String>.from(slot.timeSlots),
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
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
    widget.doctor.specialization = specialization.text.trim();
    widget.doctor.phone = phone.text.trim();
    widget.doctor.clinicName = clinicName.text.trim();
    widget.doctor.clinicAddress = clinicAddress.text.trim();
    widget.doctor.clinicLocation = clinicLocation.text.trim();
    widget.doctor.clinicLatitude = _selectedLatitude;
    widget.doctor.clinicLongitude = _selectedLongitude;
    widget.doctor.bio = bio.text.trim();
    widget.doctor.upiId = upiId.text.trim();
    widget.doctor.bankAccountHolder = '';
    widget.doctor.bankName = '';
    widget.doctor.bankAccountNumber = '';
    widget.doctor.bankIfscCode = '';
    widget.doctor.consultationFee =
        double.tryParse(consultationFee.text.trim()) ??
        widget.doctor.consultationFee;
    widget.doctor.weeklyAvailability = weeklyAvailability
        .map(
          (slot) => DoctorWeeklyAvailability(
            weekday: slot.weekday,
            timeSlots: List<String>.from(slot.timeSlots),
          ),
        )
        .toList();
    widget.doctor.availabilityOverrides = availabilityOverrides
        .map(
          (slot) => DoctorAvailability(
            date: slot.date,
            timeSlots: List<String>.from(slot.timeSlots),
          ),
        )
        .toList();
    widget.doctor.refreshAvailability();

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

  Future<void> _pickClinicLocation() async {
    final result = await Navigator.push<ClinicLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicLocationPickerScreen(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          initialAddress: clinicAddress.text.trim().isEmpty
              ? null
              : clinicAddress.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      clinicAddress.text = result.address;
      clinicLocation.text = result.address;
    });
  }

  Future<void> _addWeeklyAvailabilityDay() async {
    final usedDays = weeklyAvailability.map((slot) => slot.weekday).toSet();
    final availableDays = List<int>.generate(
      7,
      (index) => index + 1,
    ).where((weekday) => !usedDays.contains(weekday)).toList();

    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All weekdays are already added.")),
      );
      return;
    }

    final pickedWeekday = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Choose weekday"),
          children: availableDays
              .map(
                (weekday) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, weekday),
                  child: Text(_weekdayLabel(weekday)),
                ),
              )
              .toList(),
        );
      },
    );

    if (pickedWeekday == null) return;

    setState(() {
      weeklyAvailability.add(
        DoctorWeeklyAvailability(weekday: pickedWeekday, timeSlots: <String>[]),
      );
      weeklyAvailability = normalizeWeeklyAvailability(weeklyAvailability);
    });
  }

  Future<void> _addWeeklyTimeSlot(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      final updatedSlots = List<String>.from(
        weeklyAvailability[index].timeSlots,
      )..add(picked.format(context));
      weeklyAvailability[index] = DoctorWeeklyAvailability(
        weekday: weeklyAvailability[index].weekday,
        timeSlots: updatedSlots,
      );
      weeklyAvailability = normalizeWeeklyAvailability(weeklyAvailability);
    });
  }

  void _removeWeeklyAvailabilityDay(int index) {
    setState(() {
      weeklyAvailability.removeAt(index);
    });
  }

  void _removeWeeklyTimeSlot(int dayIndex, int slotIndex) {
    setState(() {
      final updatedSlots = List<String>.from(
        weeklyAvailability[dayIndex].timeSlots,
      )..removeAt(slotIndex);
      weeklyAvailability[dayIndex] = DoctorWeeklyAvailability(
        weekday: weeklyAvailability[dayIndex].weekday,
        timeSlots: updatedSlots,
      );
      weeklyAvailability = normalizeWeeklyAvailability(weeklyAvailability);
    });
  }

  Future<void> _addSpecificDateOverride() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return;

    final date = DateTime(picked.year, picked.month, picked.day);
    final existingIndex = availabilityOverrides.indexWhere(
      (slot) => _isSameCalendarDay(slot.date, date),
    );
    if (existingIndex >= 0) return;

    final baseSlots =
        weeklyAvailability
            .where((slot) => slot.weekday == date.weekday)
            .firstOrNull
            ?.timeSlots ??
        const <String>[];

    setState(() {
      availabilityOverrides.add(
        DoctorAvailability(date: date, timeSlots: List<String>.from(baseSlots)),
      );
      availabilityOverrides = normalizeAvailabilityOverrides(
        availabilityOverrides,
      );
    });
  }

  Future<void> _addOverrideTimeSlot(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      final updatedSlots = List<String>.from(
        availabilityOverrides[index].timeSlots,
      )..add(picked.format(context));
      availabilityOverrides[index] = DoctorAvailability(
        date: availabilityOverrides[index].date,
        timeSlots: updatedSlots,
      );
      availabilityOverrides = normalizeAvailabilityOverrides(
        availabilityOverrides,
      );
    });
  }

  void _removeOverrideDate(int index) {
    setState(() {
      availabilityOverrides.removeAt(index);
    });
  }

  void _removeOverrideTimeSlot(int dayIndex, int slotIndex) {
    setState(() {
      final updatedSlots = List<String>.from(
        availabilityOverrides[dayIndex].timeSlots,
      )..removeAt(slotIndex);
      availabilityOverrides[dayIndex] = DoctorAvailability(
        date: availabilityOverrides[dayIndex].date,
        timeSlots: updatedSlots,
      );
      availabilityOverrides = normalizeAvailabilityOverrides(
        availabilityOverrides,
      );
    });
  }

  bool _isSameCalendarDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _weekdayLabel(int weekday) {
    const labels = <int, String>{
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    return labels[weekday] ?? 'Day';
  }

  List<DoctorAvailability> get _generatedPreview {
    return buildUpcomingAvailability(
      weeklyAvailability: weeklyAvailability,
      availabilityOverrides: availabilityOverrides,
      horizonDays: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final generatedPreview = _generatedPreview;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(onPressed: _saveProfile, child: const Text("Save")),
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
                    _buildField(
                      username,
                      "Username",
                      readOnly: true,
                      helperText:
                          "Username cannot be changed after registration.",
                    ),
                    _buildField(specialization, "Specialization"),
                    _buildField(
                      phone,
                      "Phone number",
                      keyboardType: TextInputType.phone,
                      extraValidator: (value) => _phonePattern.hasMatch(value)
                          ? null
                          : "Enter a valid phone number",
                    ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _pickClinicLocation,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text("Pick location on map"),
                      ),
                    ),
                    if (_selectedLatitude != null &&
                        _selectedLongitude != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Selected: ${_selectedLatitude!.toStringAsFixed(5)}, ${_selectedLongitude!.toStringAsFixed(5)}",
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                    _buildField(
                      consultationFee,
                      "Consultation fee",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
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
                    const Text(
                      "Set your weekly working days once. Upcoming dates are created automatically, and you can still customize any one date when needed.",
                      style: TextStyle(color: AppColors.mutedText, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Weekly schedule",
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (weeklyAvailability.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No weekly schedule added yet. Add the weekdays you usually work.",
                          style: TextStyle(
                            color: AppColors.mutedText,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      ...weeklyAvailability.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WeeklyAvailabilityEditorCard(
                            label: _weekdayLabel(entry.value.weekday),
                            timeSlots: entry.value.timeSlots,
                            onAddSlot: () => _addWeeklyTimeSlot(entry.key),
                            onRemoveDay: () =>
                                _removeWeeklyAvailabilityDay(entry.key),
                            onRemoveSlot: (slotIndex) =>
                                _removeWeeklyTimeSlot(entry.key, slotIndex),
                          ),
                        ),
                      ),
                    OutlinedButton(
                      onPressed: _addWeeklyAvailabilityDay,
                      child: const Text("Add weekly day"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Specific date changes",
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Use this only when one date needs different times or a day off.",
                      style: TextStyle(color: AppColors.mutedText, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    if (availabilityOverrides.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No specific date changes added yet.",
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      )
                    else
                      ...availabilityOverrides.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DateAvailabilityEditorCard(
                            availability: entry.value,
                            onAddSlot: () => _addOverrideTimeSlot(entry.key),
                            onRemoveDay: () => _removeOverrideDate(entry.key),
                            onRemoveSlot: (slotIndex) =>
                                _removeOverrideTimeSlot(entry.key, slotIndex),
                          ),
                        ),
                      ),
                    OutlinedButton(
                      onPressed: _addSpecificDateOverride,
                      child: const Text("Customize specific date"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Upcoming preview",
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (generatedPreview.isEmpty)
                      const Text(
                        "No upcoming slots will be shown to patients until you add a weekly day or date override.",
                        style: TextStyle(
                          color: AppColors.mutedText,
                          height: 1.5,
                        ),
                      )
                    else
                      ...generatedPreview
                          .take(6)
                          .map(
                            (slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SchedulePreviewRow(availability: slot),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: "UPI details",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add only the UPI ID patients should use while booking an online consultation.",
                      style: TextStyle(color: AppColors.mutedText, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      upiId,
                      "UPI ID",
                      extraValidator: (value) => _upiPattern.hasMatch(value)
                          ? null
                          : "Enter a valid UPI ID",
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
    bool readOnly = false,
    String? helperText,
    String? Function(String value)? extraValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return "Required";
          return extraValidator?.call(trimmed);
        },
        decoration: InputDecoration(labelText: label, helperText: helperText),
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

class _WeeklyAvailabilityEditorCard extends StatelessWidget {
  final String label;
  final List<String> timeSlots;
  final VoidCallback onAddSlot;
  final VoidCallback onRemoveDay;
  final ValueChanged<int> onRemoveSlot;

  const _WeeklyAvailabilityEditorCard({
    required this.label,
    required this.timeSlots,
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
                  label,
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
          if (timeSlots.isEmpty)
            const Text(
              "No time slots added yet.",
              style: TextStyle(color: AppColors.mutedText),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlots.asMap().entries.map((entry) {
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

class _DateAvailabilityEditorCard extends StatelessWidget {
  final DoctorAvailability availability;
  final VoidCallback onAddSlot;
  final VoidCallback onRemoveDay;
  final ValueChanged<int> onRemoveSlot;

  const _DateAvailabilityEditorCard({
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
              "No time slots. Leave it empty if you want this day blocked off.",
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
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

class _SchedulePreviewRow extends StatelessWidget {
  final DoctorAvailability availability;

  const _SchedulePreviewRow({required this.availability});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              DateFormat('dd MMM').format(availability.date),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              availability.timeSlots.join(' | '),
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
