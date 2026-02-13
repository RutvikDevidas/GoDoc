import 'package:flutter/material.dart';
import '../../../shared/stores/doctor_registry_store.dart';
import '../../../shared/stores/notification_store.dart';

class VerifyDoctorsPage extends StatelessWidget {
  const VerifyDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6E4FF), Color(0xFFC7DAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: DoctorRegistryStore.doctorsVN,
          builder: (_, __, ___) {
            final pending = DoctorRegistryStore.pendingForAdmin();
            final verified = DoctorRegistryStore.visibleForPatients();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Verify Doctors",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),

                _sectionTitle("Pending Verification (${pending.length})"),
                const SizedBox(height: 8),
                if (pending.isEmpty) _empty(context, "No pending doctors"),
                ...pending.map((d) => _doctorCard(context, d, verified: false)),

                const SizedBox(height: 16),
                _sectionTitle("Verified Doctors (${verified.length})"),
                const SizedBox(height: 8),
                if (verified.isEmpty)
                  _empty(context, "No verified doctors yet"),
                ...verified.map((d) => _doctorCard(context, d, verified: true)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w900));
  }

  Widget _empty(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _doctorCard(
    BuildContext context,
    dynamic d, {
    required bool verified,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              d.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(d.title),
                const SizedBox(height: 4),
                Text(
                  verified ? "Verified ✅" : "Pending ⏳",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: verified ? const Color(0xFF1E5BFF) : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          if (!verified)
            ElevatedButton(
              onPressed: () {
                DoctorRegistryStore.markVerified(d.id, true);
                NotificationStore.add(
                  "Doctor Verified ✅",
                  "${d.name} is now visible to patients.",
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Verified: ${d.name}")));
              },
              child: const Text("Verify"),
            )
          else
            OutlinedButton(
              onPressed: () {
                DoctorRegistryStore.markVerified(d.id, false);
                NotificationStore.add(
                  "Doctor Unverified ⚠️",
                  "${d.name} has been hidden from patients.",
                );
              },
              child: const Text("Unverify"),
            ),
        ],
      ),
    );
  }
}
