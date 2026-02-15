import 'package:flutter/material.dart';

import '../../../shared/stores/appointment_store.dart';
import '../../../shared/stores/notification_store.dart';

class FeedbackPage extends StatefulWidget {
  final String appointmentId;
  const FeedbackPage({super.key, required this.appointmentId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int rating = 5;
  final c = TextEditingController();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback")),
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
            const Text(
              "Rate the appointment",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: List.generate(5, (i) {
                final v = i + 1;
                return ChoiceChip(
                  label: Text("$v ⭐"),
                  selected: rating == v,
                  onSelected: (_) => setState(() => rating = v),
                );
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write feedback...",
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppointmentStore.addFeedback(
                    widget.appointmentId,
                    rating,
                    c.text,
                  );
                  NotificationStore.add("Feedback Saved ✅", "Thanks!");
                  Navigator.pop(context);
                },
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
