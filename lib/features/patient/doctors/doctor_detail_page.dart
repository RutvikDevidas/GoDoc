import 'package:flutter/material.dart';
import '../appointments/appointment_booking_page.dart';

class DoctorDetailPage extends StatelessWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9F0C7),
      body: SafeArea(
        child: Column(
          children: [
            // TOP IMAGE SECTION
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  child: Image.network(
                    "https://i.pravatar.cc/400?img=12",
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border, color: Colors.red),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  children: [
                    const Center(
                      child: Text(
                        "Dr. Ali Uzair",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "Senior Cardiologist and Surgeon",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star, color: Colors.orange, size: 18),
                        SizedBox(width: 4),
                        Text("4.9 (96 reviews)"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Clinic Address",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://maps.googleapis.com/maps/api/staticmap?center=London&zoom=13&size=600x300&maptype=roadmap",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "About Me",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Dr. Ali Uzair is the top most cardiologist specialist in Christ Hospital in London. He achieved several awards for heart related contribution.",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    // Book Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2BB673),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppointmentBookingPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Book Appointment",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
