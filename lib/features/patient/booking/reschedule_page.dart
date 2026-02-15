import 'package:flutter/material.dart';

import '../../../shared/models/appointment.dart';

class ReschedulePage extends StatefulWidget {
  final Appointment appointment;
  const ReschedulePage({super.key, required this.appointment});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.appointment.dateTime;
    selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, "0")}-${selectedDate.day.toString().padLeft(2, "0")}";
    final timeText = selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Reschedule")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard(),
            const SizedBox(height: 12),

            _pickerTile(
              title: "Select Date",
              value: dateText,
              icon: Icons.calendar_month_rounded,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.isBefore(DateTime.now())
                      ? DateTime.now()
                      : selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),

            const SizedBox(height: 12),

            _pickerTile(
              title: "Select Time",
              value: timeText,
              icon: Icons.schedule_rounded,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final dt = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  Navigator.pop(context, dt); // ✅ return DateTime
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Save New Schedule"),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final a = widget.appointment;
    final when =
        "${a.dateTime.year}-${a.dateTime.month.toString().padLeft(2, "0")}-${a.dateTime.day.toString().padLeft(2, "0")}  "
        "${_time12(a.dateTime)}";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF2BB673).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFF0B8F4D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "Current: $when",
                  style: TextStyle(color: Colors.black.withOpacity(0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2BB673).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0B8F4D)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  String _time12(DateTime dt) {
    final hh = dt.hour;
    final mm = dt.minute.toString().padLeft(2, "0");
    final ampm = hh >= 12 ? "PM" : "AM";
    final h12 = (hh % 12 == 0) ? 12 : (hh % 12);
    return "$h12:$mm $ampm";
  }
}
