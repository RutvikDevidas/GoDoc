import 'package:flutter/material.dart';
import '../doctors/doctor_detail_page.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctors = [
      {
        "id": "1",
        "name": "Dr. Hamza Tariq",
        "specialization": "Senior Surgeon",
        "rating": "4.9",
        "time": "10:30 AM - 3:30",
      },
      {
        "id": "2",
        "name": "Dr. Alina Fatima",
        "specialization": "Senior Surgeon",
        "rating": "5.0",
        "time": "10:30 AM - 3:30",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFB9F0C7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // HEADER
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=3",
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Hello Hamza !",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.notifications_none),
                ],
              ),

              const SizedBox(height: 15),

              // SEARCH
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Services",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _ServiceCard("Odontology", Icons.medical_services),
                    _ServiceCard("Neurology", Icons.psychology),
                    _ServiceCard("Cardiology", Icons.favorite),
                    _ServiceCard("Orthopedic", Icons.accessibility),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Top Doctor’s",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Column(
                children: doctors
                    .map(
                      (doc) => _DoctorCard(
                        id: doc["id"]!,
                        name: doc["name"]!,
                        specialization: doc["specialization"]!,
                        rating: doc["rating"]!,
                        time: doc["time"]!,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ServiceCard(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F9D58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String id;
  final String name;
  final String specialization;
  final String rating;
  final String time;

  const _DoctorCard({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2BB673),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  specialization,
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(time, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 16),
                  Text(rating, style: const TextStyle(color: Colors.white)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailPage(doctorId: id),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
