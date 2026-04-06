import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isSubmitting = false;

  bool _isSameCalendarDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DoctorAvailability? _findMatchingAvailability(
    List<DoctorAvailability> dates,
    DoctorAvailability? selected,
  ) {
    if (selected == null) return null;

    for (final date in dates) {
      if (_isSameCalendarDay(date.date, selected.date)) {
        return date;
      }
    }

    return null;
  }

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

    selectedAvailability =
        _findMatchingAvailability(dates, selectedAvailability) ?? dates.first;

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

  AppointmentModel _buildAppointment({
    required String paymentStatus,
    String? paymentMethod,
    String? paymentReference,
    DateTime? paymentPaidAt,
  }) {
    return AppointmentModel(
      id:
          "appt-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}",
      doctorUsername: widget.doctor.username,
      patientUsername: widget.patient.username,
      date: _formatAppointmentDate(selectedAvailability!.date),
      time: selectedTime!,
      type: type,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      paymentAmount: widget.doctor.consultationFee,
      paymentPaidAt: paymentPaidAt,
    );
  }

  bool get _onlinePaymentConfigured => widget.doctor.upiId.trim().isNotEmpty;

  bool _hasRequiredPayment(AppointmentModel appointment) {
    if (appointment.type.toLowerCase() != 'online') {
      return true;
    }

    return appointment.paymentStatus.toLowerCase() == 'paid' &&
        (appointment.paymentReference?.trim().isNotEmpty ?? false);
  }

  Uri _buildUpiPaymentUri(String reference) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': widget.doctor.upiId.trim(),
        'pn': widget.doctor.name.trim(),
        'am': widget.doctor.consultationFee.toStringAsFixed(2),
        'cu': 'INR',
        'tn':
            'GoDoc consultation for ${widget.patient.name} (${reference.trim()})',
        'tr': reference.trim(),
      },
    );
  }

  Future<String?> _showPaymentSheet() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final suggestedReference =
            'PAY-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';
        final referenceController = TextEditingController(
          text: suggestedReference,
        );
        var upiLaunchAttempted = false;
        var upiLaunchSucceeded = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> openUpiApp() async {
              final reference = referenceController.text.trim().isEmpty
                  ? suggestedReference
                  : referenceController.text.trim();
              referenceController.text = reference;

              final launched = await launchUrl(
                _buildUpiPaymentUri(reference),
                mode: LaunchMode.platformDefault,
              );

              if (!context.mounted) return;

              setModalState(() {
                upiLaunchAttempted = true;
                upiLaunchSucceeded = launched;
              });

              if (!launched) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No UPI app was opened. You can still complete payment and enter the reference manually.',
                    ),
                  ),
                );
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  28 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPI payment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pay Rs ${widget.doctor.consultationFee.toStringAsFixed(0)} to ${widget.doctor.name} for this online consultation. Open your UPI app, complete the transfer, then confirm the payment reference here.',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PaymentPreviewRow(
                      label: 'Doctor UPI',
                      value: widget.doctor.upiId,
                    ),
                    _PaymentPreviewRow(
                      label: 'Amount',
                      value:
                          'Rs ${widget.doctor.consultationFee.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Payment reference',
                        hintText: 'Enter UPI transaction ID / reference',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tip: keep the suggested reference or replace it with the final transaction ID shown by your payment app.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                    if (upiLaunchAttempted) ...[
                      const SizedBox(height: 10),
                      Text(
                        upiLaunchSucceeded
                            ? 'UPI app opened. Complete the payment there, then come back and confirm.'
                            : 'No UPI app opened on this device. After paying another way, enter the payment reference and confirm.',
                        style: TextStyle(
                          color: upiLaunchSucceeded
                              ? AppColors.primary
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: openUpiApp,
                        child: const Text('Open UPI app'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final reference = referenceController.text.trim();
                          if (reference.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter the payment reference before confirming payment.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context, reference);
                        },
                        child: const Text('I have completed payment'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> bookAppointment() async {
    if (selectedAvailability == null || selectedTime == null) return;
    if (_isSubmitting) return;
    if (type == 'Online' && !_onlinePaymentConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online consultation is unavailable because the doctor has not added payment details yet.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String paymentStatus = 'pay_on_visit';
      String? paymentMethod;
      String? paymentReference;
      DateTime? paymentPaidAt;

      if (type == 'Online') {
        final paymentRef = await _showPaymentSheet();
        if (paymentRef == null) {
          return;
        }

        paymentStatus = 'paid';
        paymentMethod = 'upi';
        paymentReference = paymentRef;
        paymentPaidAt = DateTime.now();
      }

      final appointment = _buildAppointment(
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        paymentPaidAt: paymentPaidAt,
      );

      if (!_hasRequiredPayment(appointment)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment is compulsory for online consultation. Complete payment to continue.',
            ),
          ),
        );
        return;
      }

      await FirestoreDataService.instance.saveAppointment(appointment);

      try {
        await FirestoreDataService.instance.syncAllToAppState();
      } catch (_) {}
      AppState.doctorNotifications.add(
        "New appointment request from ${widget.patient.name}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment booked successfully.")),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not save appointment: $error")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    await bookAppointment();
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
                            isSelected:
                                selectedAvailability != null &&
                                _isSameCalendarDay(
                                  selectedAvailability!.date,
                                  slot.date,
                                ),
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
                    subtitle: "Payment is compulsory before the booking is created.",
                    icon: Icons.videocam_outlined,
                    isSelected: type == "Online",
                    onTap: () => setState(() => type = "Online"),
                  ),
                ],
              ),
            ),
            if (type == "Online") ...[
              const SizedBox(height: 16),
              _Panel(
                title: "Payment details",
                child: _PaymentDetailsCard(doctor: widget.doctor),
              ),
            ],
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
          onPressed: dates.isEmpty || _isSubmitting ? null : _submitBooking,
          child: Text(
            _isSubmitting
                ? "Saving..."
                : type == "Online"
                ? "Pay & Book Appointment"
                : "Book Appointment",
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF123C73), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.accent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
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

class _PaymentDetailsCard extends StatelessWidget {
  final DoctorModel doctor;

  const _PaymentDetailsCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final hasBankDetails =
        doctor.bankAccountHolder.trim().isNotEmpty ||
        doctor.bankName.trim().isNotEmpty ||
        doctor.bankAccountNumber.trim().isNotEmpty ||
        doctor.bankIfscCode.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Consultation fee: Rs ${doctor.consultationFee.toStringAsFixed(0)}",
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (doctor.upiId.trim().isNotEmpty)
            Text(
              "UPI ID: ${doctor.upiId}",
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (doctor.upiId.trim().isNotEmpty && hasBankDetails)
            const SizedBox(height: 10),
          if (hasBankDetails) ...[
            if (doctor.bankAccountHolder.trim().isNotEmpty)
              Text("Account holder: ${doctor.bankAccountHolder}"),
            if (doctor.bankName.trim().isNotEmpty)
              Text("Bank: ${doctor.bankName}"),
            if (doctor.bankAccountNumber.trim().isNotEmpty)
              Text("Account number: ${doctor.bankAccountNumber}"),
            if (doctor.bankIfscCode.trim().isNotEmpty)
              Text("IFSC: ${doctor.bankIfscCode}"),
            const SizedBox(height: 10),
          ],
          const Text(
            "Payment is compulsory for online consultations. The booking is created only after payment is marked successful.",
            style: TextStyle(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentPreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
