import 'package:flutter/material.dart';
import '../../../shared/stores/patient_store.dart';

class MedicalReportsPage extends StatelessWidget {
  const MedicalReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = PatientStore.demoPatient;
    final reports = PatientStore.reportsFor(patient.id);

    return Scaffold(
      appBar: AppBar(title: const Text("Medical Reports")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (reports.isEmpty)
            const Center(child: Text("No medical reports uploaded"))
          else
            ...reports.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(r.description),
                    const SizedBox(height: 8),
                    Text("Date: ${r.date.toString().split(' ').first}"),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Open file: ${r.fileUrl}")),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Open Report"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
