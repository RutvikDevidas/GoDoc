import 'package:flutter/material.dart';
import 'payment_page.dart';

class AppointmentPage extends StatefulWidget {
  final String doctorName;
  final String specialization;
  final String imageUrl;

  const AppointmentPage({
    super.key,
    required this.doctorName,
    required this.specialization,
    required this.imageUrl,
  });

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int selectedDayIndex = 2;
  String selectedTime = "10:00 AM";
  String consultationType = "Offline";

  final List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu"];
  final List<String> dates = ["3", "4", "5", "6", "7"];

  final List<String> times = [
    "9:00 AM",
    "9:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9F0C7),
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Doctor Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  child: Image.network(
                    widget.imageUrl,
                    height: 220,
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
                    Center(
                      child: Text(
                        widget.doctorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        widget.specialization,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Appointment",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 15),

                    // 📅 Day Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(days.length, (index) {
                        final isSelected = selectedDayIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDayIndex = index;
                            });
                          },
                          child: Container(
                            width: 55,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2BB673)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  days[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dates[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Available Time",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: times.map((time) {
                        final isSelected = selectedTime == time;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTime = time;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2BB673)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Consultation Type",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Row(
                      children: [
                        Radio(
                          value: "Offline",
                          groupValue: consultationType,
                          activeColor: const Color(0xFF2BB673),
                          onChanged: (value) {
                            setState(() {
                              consultationType = value.toString();
                            });
                          },
                        ),
                        const Text("Offline"),
                        const SizedBox(width: 20),
                        Radio(
                          value: "Online",
                          groupValue: consultationType,
                          activeColor: const Color(0xFF2BB673),
                          onChanged: (value) {
                            setState(() {
                              consultationType = value.toString();
                            });
                          },
                        ),
                        const Text("Online"),
                      ],
                    ),

                    const SizedBox(height: 30),

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
                              builder: (_) => PaymentPage(
                                doctorName: widget.doctorName,
                                date:
                                    "${days[selectedDayIndex]} ${dates[selectedDayIndex]}",
                                time: selectedTime,
                                type: consultationType,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Proceed to Payment",
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
