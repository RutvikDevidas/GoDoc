import 'package:flutter/material.dart';
import '../../../shared/stores/doctor_store.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  late List<DoctorScheduleSlot> schedule;

  @override
  void initState() {
    super.initState();
    schedule = DoctorStore.schedule
        .map((s) => DoctorScheduleSlot(day: s.day, times: [...s.times]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Schedule")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...schedule.map((slot) => _dayCard(slot)),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                DoctorStore.updateSchedule(schedule);
                Navigator.pop(context);
              },
              child: const Text("Save Schedule"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(DoctorScheduleSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slot.day, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...slot.times.map(
                (t) => Chip(
                  label: Text(t),
                  onDeleted: () {
                    setState(() => slot.times.remove(t));
                  },
                ),
              ),
              ActionChip(
                label: const Text("+ Add time"),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (picked == null) return;
                  final timeStr =
                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  setState(() => slot.times.add(timeStr));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
