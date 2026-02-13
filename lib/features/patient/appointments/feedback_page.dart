import 'package:flutter/material.dart';
import '../../../shared/stores/appointment_store.dart';

class FeedbackPage extends StatefulWidget {
  final String appointmentId;
  const FeedbackPage({super.key, required this.appointmentId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int rating = 5;
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AppointmentStore.byId(widget.appointmentId);

    return Scaffold(
      appBar: AppBar(title: const Text("Feedback")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (a == null)
            const Text("Appointment not found")
          else ...[
            Text(
              a.doctor.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rating",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () => setState(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Write your feedback",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  AppointmentStore.addFeedback(a.id, rating, ctrl.text);
                  Navigator.pop(context, true);
                },
                child: const Text("Submit Feedback"),
              ),
            ),
          ],
        ],
      ),
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
}
