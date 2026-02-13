import 'package:flutter/material.dart';
import '../../../shared/models/doctor.dart';
import 'payment_page.dart';

class AppointmentPage extends StatefulWidget {
  final Doctor doctor;
  const AppointmentPage({super.key, required this.doctor});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int selectedDayIndex = 1;
  int selectedTimeIndex = 0;
  bool isOnline = false;

  final days = const [
    {"day": "Sun", "date": "3"},
    {"day": "Mon", "date": "4"},
    {"day": "Tue", "date": "5"},
    {"day": "Wed", "date": "6"},
    {"day": "Thu", "date": "7"},
  ];

  final times = const ["9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointment")),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(widget.doctor.imageUrl, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 60),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF48D07D),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.doctor.title,
                      style: TextStyle(color: Colors.white.withOpacity(0.95)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.doctor.hospital,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.95)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Appointment",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 74,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final isSelected = i == selectedDayIndex;
                          return InkWell(
                            onTap: () => setState(() => selectedDayIndex = i),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 64,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF48D07D)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[i]["day"]!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    days[i]["date"]!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Available Time",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(times.length, (i) {
                        final selected = i == selectedTimeIndex;
                        return InkWell(
                          onTap: () => setState(() => selectedTimeIndex = i),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF48D07D)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              times[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isOnline,
                          onChanged: (v) => setState(() => isOnline = v!),
                        ),
                        const Text("Offline"),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: true,
                          groupValue: isOnline,
                          onChanged: (v) => setState(() => isOnline = v!),
                        ),
                        const Text("Online"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final dt = _buildSelectedDateTime();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          doctor: widget.doctor,
                          selectedDateTime: dt,
                          isOnline: isOnline,
                        ),
                      ),
                    );
                  },
                  child: const Text("Proceed to Payment"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _buildSelectedDateTime() {
    final now = DateTime.now();
    final dayNum = int.parse(days[selectedDayIndex]["date"]!);
    final hour = _parseHour(times[selectedTimeIndex]);
    final minute = _parseMinute(times[selectedTimeIndex]);

    // demo: uses current month/year + selected day number
    return DateTime(now.year, now.month, dayNum, hour, minute);
  }

  int _parseHour(String t) {
    final parts = t.split(" ");
    final hm = parts[0].split(":");
    var h = int.parse(hm[0]);
    final isPm = parts[1] == "PM";
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return h;
  }

  int _parseMinute(String t) {
    final parts = t.split(" ");
    final hm = parts[0].split(":");
    return int.parse(hm[1]);
  }
}
