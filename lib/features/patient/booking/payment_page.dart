import 'package:flutter/material.dart';

import '../../../core/utils/ids.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/doctor.dart';
import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';
import '../../../shared/stores/patient_store.dart';

class PaymentPage extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDateTime;
  final bool isOnline;

  const PaymentPage({
    super.key,
    required this.doctor,
    required this.selectedDateTime,
    required this.isOnline,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = "UPI";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Summary",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text("Doctor: ${widget.doctor.name}"),
                Text("Time: ${widget.selectedDateTime}"),
                Text("Mode: ${widget.isOnline ? "Online" : "Offline"}"),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Total: ₹499",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "Select Payment Method",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip("UPI"),
              _chip("Card"),
              _chip("NetBanking"),
              _chip("Cash"),
            ],
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _payNow,
              child: const Text("Pay Now"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    final selected = method == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) => setState(() => method = value),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  void _payNow() {
    // ✅ Auto-add appointment after payment (NEW model)
    final appt = Appointment(
      id: "a_${Ids.now()}",
      doctor: widget.doctor,
      patient: PatientStore.demoPatient,
      dateTime: widget.selectedDateTime,
      isOnline: widget.isOnline,
      fee: 499,
      status: AppointmentStatus.pending,
    );

    AppointmentStore.add(appt);

    // ✅ In-app notification
    NotificationStore.add(
      "Payment Successful ✅",
      "Appointment request sent to ${widget.doctor.name}.",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Successful ✅ Appointment Added")),
    );

    // go back to home (or first page)
    Navigator.popUntil(context, (r) => r.isFirst);
  }
}
