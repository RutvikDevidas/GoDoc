import 'package:flutter/material.dart';
import '../../../shared/data/demo_data.dart';
import '../../../shared/models/specialization.dart';
import 'doctor_detail_page.dart';

class DoctorsListPage extends StatelessWidget {
  final Specialization spec;
  const DoctorsListPage({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    final doctors = DemoData.doctorsBySpec(spec.id);

    return Scaffold(
      appBar: AppBar(title: Text("${spec.name} Doctors")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: doctors.isEmpty
            ? [const Center(child: Text("No doctors found"))]
            : doctors
                  .map(
                    (d) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          d.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        d.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(d.title),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailPage(doctor: d),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
