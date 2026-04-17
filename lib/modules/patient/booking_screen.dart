import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_state.dart';
import '../../core/firebase/firestore_data_service.dart';
import '../../core/payment/razorpay_config.dart';
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
  late final Razorpay _razorpay;
  Completer<_PaymentResult?>? _paymentCompleter;

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
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _syncSelection();
  }

  @override
  void dispose() {
    _paymentCompleter?.complete(null);
    _razorpay.clear();
    super.dispose();
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

  bool get _onlinePaymentConfigured => RazorpayConfig.isConfigured;

  bool _hasRequiredPayment(AppointmentModel appointment) {
    if (appointment.type.toLowerCase() != 'online') {
      return true;
    }

    return appointment.paymentStatus.toLowerCase() == 'paid' &&
        (appointment.paymentReference?.trim().isNotEmpty ?? false);
  }

  String _normalizePaymentReference(String reference) {
    final cleaned = reference
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._/-]'), '')
        .toUpperCase();
    final shortened = cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
    if (shortened.isNotEmpty) {
      return shortened;
    }

    return 'GODOC${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentCompleter?.complete(
      _PaymentResult(
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
    _paymentCompleter = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentCompleter?.complete(null);
    _paymentCompleter = null;

    if (!mounted) return;
    final message = response.message?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message?.isNotEmpty == true
              ? 'Payment unsuccessful: $message'
              : 'Payment unsuccessful. Please try again.',
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    final walletName = response.walletName?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          walletName?.isNotEmpty == true
              ? 'Continue the payment in $walletName.'
              : 'Continue the payment in the selected wallet.',
        ),
      ),
    );
  }

  Future<_PaymentResult?> _startRazorpayPayment() async {
    if (!RazorpayConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Online payment is unavailable until a Razorpay key is added.',
            ),
          ),
        );
      }
      return null;
    }

    final receipt = _normalizePaymentReference(
      'GODOC${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(900) + 100}',
    );

    final completer = Completer<_PaymentResult?>();
    _paymentCompleter?.complete(null);
    _paymentCompleter = completer;

    final options = {
      'key': RazorpayConfig.keyId,
      'amount': (widget.doctor.consultationFee * 100).round(),
      'name': RazorpayConfig.merchantName,
      'description': 'Consultation with ${widget.doctor.name}',
      'prefill': {
        'contact': widget.patient.phone.trim(),
        'email': widget.patient.email.trim(),
      },
      'notes': {
        'patient_username': widget.patient.username,
        'patient_name': widget.patient.name,
        'doctor_username': widget.doctor.username,
        'doctor_name': widget.doctor.name,
        'appointment_type': type,
        'receipt': receipt,
      },
      'theme': {
        'color': '#0F766E',
      },
    };

    try {
      _razorpay.open(options);
    } catch (_) {
      _paymentCompleter = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start Razorpay checkout. Please verify the Razorpay setup.',
            ),
          ),
        );
      }
      return null;
    }

    return completer.future;
  }

  Future<void> bookAppointment() async {
    if (selectedAvailability == null || selectedTime == null) return;
    if (_isSubmitting) return;
    if (type == 'Online' && !_onlinePaymentConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online payment is unavailable because Razorpay is not configured yet.',
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
        final paymentResult = await _startRazorpayPayment();
        if (paymentResult == null) {
          return;
        }

        paymentStatus = 'paid';
        paymentMethod = 'razorpay';
        paymentReference = paymentResult.reference;
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

class _PaymentResult {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  const _PaymentResult({
    this.paymentId,
    this.orderId,
    this.signature,
  });

  String get reference =>
      paymentId?.trim().isNotEmpty == true
          ? paymentId!.trim()
          : orderId?.trim().isNotEmpty == true
          ? orderId!.trim()
          : signature?.trim().isNotEmpty == true
          ? signature!.trim()
          : 'razorpay-${DateTime.now().millisecondsSinceEpoch}';
}

class _PaymentDetailsCard extends StatelessWidget {
  final DoctorModel doctor;

  const _PaymentDetailsCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
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
          if (RazorpayConfig.isConfigured)
            const Text(
              "Razorpay checkout is enabled for online consultation payments. UPI apps such as GPay should appear inside Razorpay checkout when available.",
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (!RazorpayConfig.isConfigured)
            const Text(
              "Online payment is not ready yet. Add a valid Razorpay key in the app configuration to enable online consultation booking.",
              style: TextStyle(
                color: AppColors.danger,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const SizedBox.shrink(),
          if (RazorpayConfig.isConfigured)
            const SizedBox(height: 10),
          const Text(
            "Payment is compulsory for online consultations. The booking is created only after Razorpay reports the payment as successful.",
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

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
