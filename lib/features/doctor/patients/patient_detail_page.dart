import 'package:flutter/material.dart';
import '../../../shared/models/patient.dart';
import '../../../shared/stores/patient_store.dart';

class PatientDetailPage extends StatelessWidget {
  final Patient patient;
  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final reports = PatientStore.reportsFor(patient.id);

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage: NetworkImage(patient.avatarUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(patient.email),
                    Text(patient.phone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            "Medical Reports",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),

          if (reports.isEmpty)
            const Text("No reports uploaded.")
          else
            ...reports.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 6),
                    Text("Date: ${r.date.toString().split(' ').first}"),
                    const SizedBox(height: 8),
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
