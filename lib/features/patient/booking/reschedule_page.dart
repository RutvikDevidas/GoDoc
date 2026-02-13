import 'package:flutter/material.dart';
import '../../../shared/stores/appointment_store.dart';

class ReschedulePage extends StatefulWidget {
  final String appointmentId;
  const ReschedulePage({super.key, required this.appointmentId});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    final appt = AppointmentStore.byId(widget.appointmentId);
    if (appt != null) {
      selectedDate = DateTime(
        appt.dateTime.year,
        appt.dateTime.month,
        appt.dateTime.day,
      );
      selectedTime = TimeOfDay(
        hour: appt.dateTime.hour,
        minute: appt.dateTime.minute,
      );
      isOnline = appt.isOnline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = AppointmentStore.byId(widget.appointmentId);

    return Scaffold(
      appBar: AppBar(title: const Text("Reschedule")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (appt != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2BB673).withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      appt.doctor.imageUrl,
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
                          appt.doctor.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appt.doctor.title,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          _pickTile(
            icon: Icons.calendar_month,
            title: "Select Date",
            value:
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: selectedDate,
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),

          const SizedBox(height: 12),

          _pickTile(
            icon: Icons.access_time,
            title: "Select Time",
            value: selectedTime.format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) setState(() => selectedTime = picked);
            },
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text(
                  "Mode",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text("Offline"),
                  selected: !isOnline,
                  onSelected: (_) => setState(() => isOnline = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Online"),
                  selected: isOnline,
                  onSelected: (_) => setState(() => isOnline = true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final newDt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                AppointmentStore.reschedule(
                  widget.appointmentId,
                  newDt,
                  isOnline,
                );
                Navigator.pop(context, true);
              },
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon),
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
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
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
}
