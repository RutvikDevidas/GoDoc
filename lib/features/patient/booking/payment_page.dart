import 'package:flutter/material.dart';

import '../../../shared/models/doctor.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/stores/notification_store.dart';

class PaymentPage extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;
  final String time;

  const PaymentPage({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final amount = 499;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  AppImage(
                    pathOrUrl: doctor.imageUrl,
                    width: 70,
                    height: 70,
                    radius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$time • ${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}",
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹$amount",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _card("Payment Method", "UPI / Card / Netbanking (Mock)"),
            const SizedBox(height: 10),
            _card(
              "Note",
              "This is a demo payment screen. Tap Pay Now to confirm.",
            ),

            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  NotificationStore.add(
                    "Payment Successful ✅",
                    "Appointment confirmed with ${doctor.name} at $time.",
                  );
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                child: const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}
