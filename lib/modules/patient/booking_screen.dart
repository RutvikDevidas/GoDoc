import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';

class BookingScreen extends StatefulWidget {
  final DoctorModel doctor;
  final PatientModel patient;

  const BookingScreen({super.key, required this.doctor, required this.patient});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DoctorAvailability? selectedAvailability;
  String? selectedTime;
  String type = "Offline";

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  List<DoctorAvailability> get _availableDates {
    final dates = widget.doctor.availability
        .where((slot) => _availableTimesFor(slot).isNotEmpty)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return dates;
  }

  List<String> _availableTimesFor(DoctorAvailability availability) {
    final bookedTimes = AppState.appointments
        .where((appointment) => appointment.doctorUsername == widget.doctor.username)
        .where((appointment) => appointment.date == _formatAppointmentDate(availability.date))
        .where((appointment) => appointment.status != "rejected")
        .map((appointment) => appointment.time)
        .toSet();

    return availability.timeSlots
        .where((time) => !bookedTimes.contains(time))
        .toList();
  }

  String _formatAppointmentDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  void _syncSelection() {
    final dates = _availableDates;

    if (dates.isEmpty) {
      selectedAvailability = null;
      selectedTime = null;
      return;
    }

    selectedAvailability ??= dates.first;
    if (!dates.contains(selectedAvailability)) {
      selectedAvailability = dates.first;
    }

    final times = _availableTimesFor(selectedAvailability!);
    if (times.isEmpty) {
      selectedAvailability = dates.first;
      selectedTime = _availableTimesFor(selectedAvailability!).firstOrNull;
      return;
    }

    if (!times.contains(selectedTime)) {
      selectedTime = times.first;
    }
  }

  AppointmentModel _buildAppointment() {
    return AppointmentModel(
      id: Random().nextInt(99999).toString(),
      doctorUsername: widget.doctor.username,
      patientUsername: widget.patient.username,
      date: _formatAppointmentDate(selectedAvailability!.date),
      time: selectedTime!,
      type: type,
    );
  }

  Future<void> _submitBooking() async {
    if (selectedAvailability == null || selectedTime == null) return;

    final appointment = _buildAppointment();

    // Note: payment processing is not implemented yet.
    // Booking will proceed immediately for both offline and online appointments.
    await FirestoreDataService.instance.saveAppointment(appointment);
    await FirestoreDataService.instance.syncAllToAppState();
    AppState.notifications.add(
      "New appointment request from ${widget.patient.name}",
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    _syncSelection();
    final dates = _availableDates;
    final times = selectedAvailability == null
        ? <String>[]
        : _availableTimesFor(selectedAvailability!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Book Appointment"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF123C73), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${widget.doctor.specialization} | ${widget.doctor.clinicName}",
                    style: const TextStyle(
                      color: Color(0xFFD6F1EC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _SummaryBadge(
                        icon: Icons.location_on_outlined,
                        label: widget.doctor.clinicLocation,
                      ),
                      const SizedBox(width: 10),
                      _SummaryBadge(
                        icon: Icons.currency_rupee_rounded,
                        label: widget.doctor.consultationFee.toStringAsFixed(0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Panel(
              title: "Select date",
              child: dates.isEmpty
                  ? const _EmptyBookingState()
                  : SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final slot = dates[index];

                          return _DateChoice(
                            date: slot.date,
                            isSelected: selectedAvailability == slot,
                            onTap: () {
                              setState(() {
                                selectedAvailability = slot;
                                selectedTime = _availableTimesFor(slot).first;
                              });
                            },
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: "Select time",
              child: dates.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: times
                          .map(
                            (time) => ChoiceChip(
                              label: Text(time),
                              selected: selectedTime == time,
                              onSelected: (_) {
                                setState(() {
                                  selectedTime = time;
                                });
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: selectedTime == time
                                    ? Colors.white
                                    : AppColors.darkText,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: AppColors.border),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: "Appointment type",
              child: Column(
                children: [
                  _TypeTile(
                    title: "Offline consultation",
                    subtitle: "Visit the clinic and meet the doctor in person.",
                    icon: Icons.local_hospital_outlined,
                    isSelected: type == "Offline",
                    onTap: () => setState(() => type = "Offline"),
                  ),
                  const SizedBox(height: 12),
                  _TypeTile(
                    title: "Online consultation",
                    subtitle: "Pay with UPI and continue in your installed app.",
                    icon: Icons.videocam_outlined,
                    isSelected: type == "Online",
                    onTap: () => setState(() => type = "Online"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: dates.isEmpty ? null : _submitBooking,
          child: Text(
            type == "Online" ? "Proceed to Payment" : "Book Appointment",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DateChoice extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChoice({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.accent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white70 : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white70 : AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : const Color(0xFFF9FBFD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookingState extends StatelessWidget {
  const _EmptyBookingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        "No time slots are available right now. Please check again later.",
        style: TextStyle(
          color: AppColors.darkText,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
