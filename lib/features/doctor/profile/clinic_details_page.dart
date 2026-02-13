import 'package:flutter/material.dart';
import '../../../shared/stores/doctor_store.dart';

class ClinicDetailsPage extends StatefulWidget {
  const ClinicDetailsPage({super.key});

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  late TextEditingController clinicNameCtrl;
  late TextEditingController clinicAddressCtrl;

  @override
  void initState() {
    super.initState();
    clinicNameCtrl = TextEditingController(
      text: DoctorStore.profile.clinicName,
    );
    clinicAddressCtrl = TextEditingController(
      text: DoctorStore.profile.clinicAddress,
    );
  }

  @override
  void dispose() {
    clinicNameCtrl.dispose();
    clinicAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              children: [
                TextField(
                  controller: clinicNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Clinic Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clinicAddressCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Clinic Address",
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
                final p = DoctorStore.profile;
                DoctorStore.updateProfile(
                  DoctorProfileData(
                    name: p.name,
                    email: p.email,
                    phone: p.phone,
                    bio: p.bio,
                    clinicName: clinicNameCtrl.text.trim(),
                    clinicAddress: clinicAddressCtrl.text.trim(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ),
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
