import 'package:flutter/material.dart';

import '../../../shared/data/demo_data.dart';
import '../../../shared/models/doctor.dart';
import '../../../shared/models/specialization.dart';
import '../../../shared/stores/doctor_registry_store.dart';
import '../../../shared/stores/notification_store.dart';
import '../../../shared/widgets/app_image.dart';
import '../doctors/doctor_detail_page.dart';
import '../doctors/doctors_list_page.dart';
import '../notifications/notifications_center_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    DoctorRegistryStore.seedIfEmpty(DemoData.doctors);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(
                    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200",
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Hello Patient!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: NotificationStore.itemsVN,
                  builder: (_, __, ___) {
                    final unread = NotificationStore.unreadCount();
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsCenterPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_none),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search doctor",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Services",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 6),
                itemCount: DemoData.specializations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final spec = DemoData.specializations[index];
                  return _serviceCard(spec);
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Top Doctor’s",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: DoctorRegistryStore.doctorsVN,
              builder: (_, __, ___) {
                final visibleDoctors = DoctorRegistryStore.visibleForPatients();
                final filtered = visibleDoctors
                    .where(
                      (d) =>
                          d.name.toLowerCase().contains(search.toLowerCase()),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        "No verified doctors available yet.",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((d) => _doctorCard(d)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(Specialization spec) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorsListPage(spec: spec)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B8F4D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spec.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              spec.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(Doctor doctor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailPage(doctor: doctor)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2BB673).withOpacity(0.22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            AppImage(
              pathOrUrl: doctor.imageUrl,
              width: 72,
              height: 72,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.title,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(${doctor.reviews} reviews)",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
