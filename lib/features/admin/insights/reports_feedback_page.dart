import 'package:flutter/material.dart';
import '../../../shared/stores/patient_store.dart';
import '../../../shared/stores/appointment_store.dart';

class ReportsFeedbackPage extends StatelessWidget {
  const ReportsFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = PatientStore.reportsFor(PatientStore.demoPatient.id);
    final completed = AppointmentStore.patientHistory();

    final feedbacks = completed.where((a) => a.feedback != null).toList();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6E4FF), Color(0xFFC7DAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Reports & Feedback",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            _section("Medical Reports (${reports.length})"),
            const SizedBox(height: 8),
            if (reports.isEmpty) _empty("No reports"),
            ...reports.map(
              (r) => _card(
                context,
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(
                    r.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    "${r.description}\nDate: ${r.date.toString().split(' ').first}",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _section("Appointment Feedbacks (${feedbacks.length})"),
            const SizedBox(height: 8),
            if (feedbacks.isEmpty) _empty("No feedbacks"),
            ...feedbacks.map(
              (a) => _card(
                context,
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(
                    a.doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    "Rating: ${a.feedback!.rating}/5\n${a.feedback!.comment}",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w900));

  Widget _empty(String t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
