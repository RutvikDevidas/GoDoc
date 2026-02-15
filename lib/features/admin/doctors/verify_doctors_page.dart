import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/stores/doctor_registry_store.dart';
import '../../../shared/stores/notification_store.dart';
import '../../../shared/stores/doctor_kyc_store.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/clinic_map_preview.dart';

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
                if (pending.isEmpty) _empty("No pending doctors"),
                ...pending.map((d) => _doctorCard(context, d, verified: false)),

                const SizedBox(height: 16),

                _sectionTitle("Verified Doctors (${verified.length})"),
                const SizedBox(height: 8),
                if (verified.isEmpty) _empty("No verified doctors yet"),
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

  Widget _empty(String text) {
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
    return InkWell(
      onTap: verified ? null : () => _openKycSheet(context, d.id, d.name),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            AppImage(pathOrUrl: d.imageUrl, width: 64, height: 64, radius: 14),
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
                    verified ? "Verified ✅" : "Pending ⏳ (Tap to view KYC)",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: verified ? const Color(0xFF1E5BFF) : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (!verified)
              const Icon(Icons.arrow_forward_ios, size: 16)
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
      ),
    );
  }

  void _openKycSheet(BuildContext context, String doctorId, String doctorName) {
    final kyc = DoctorKycStore.byDoctorId(doctorId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (kyc == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "KYC Details",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text("No KYC found for $doctorName"),
                const SizedBox(height: 16),
              ],
            ),
          );
        }

        final mapLink =
            "https://www.google.com/maps/search/?api=1&query=${kyc.clinicLat},${kyc.clinicLng}";

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.84,
          maxChildSize: 0.95,
          minChildSize: 0.55,
          builder: (context, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Doctor KYC",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    AppImage(
                      pathOrUrl: kyc.imageUrl,
                      width: 70,
                      height: 70,
                      radius: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kyc.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text("Age: ${kyc.age}"),
                          Text("Phone: ${kyc.phone}"),
                          Text("Email: ${kyc.email}"),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ✅ REAL MAP PREVIEW
                ClinicMapPreview(lat: kyc.clinicLat, lng: kyc.clinicLng),
                const SizedBox(height: 14),

                _info("License No.", kyc.licenseNo),
                _info("Year of Passing", kyc.yearOfPassing.toString()),
                _info("Clinic Name", kyc.clinicName),
                _info("Clinic Address", kyc.clinicAddress),
                _info("Doctor Address", kyc.doctorAddress),
                _info("Specializations", kyc.specializations.join(", ")),
                _info(
                  "Clinic Geo Location",
                  "${kyc.clinicLat}, ${kyc.clinicLng}",
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5BFF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          mapLink,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: "Copy",
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: mapLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Map link copied ✅")),
                          );
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      DoctorRegistryStore.markVerified(doctorId, true);
                      NotificationStore.add(
                        "Doctor Verified ✅",
                        "${kyc.name} is now visible to patients.",
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Verified: ${kyc.name}")),
                      );
                    },
                    child: const Text("Verify Doctor"),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  Widget _info(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
