import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import 'patient_profile_store.dart';
import '../utils/ids.dart';

class AppointmentStore {
  static final List<Appointment> _items = [];

  // ✅ Real-time UI
  static final ValueNotifier<int> itemsVN = ValueNotifier<int>(0);
  static void _notify() => itemsVN.value++;

  static List<Appointment> all() => List.unmodifiable(_items);

  static Appointment? byId(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  static void add(Appointment appointment) {
    _items.add(appointment);
    _notify();
  }

  static Appointment createNewFromBooking({required Appointment template}) {
    final a = Appointment(
      id: "a_${Ids.now()}",
      doctor: template.doctor,
      patient: template.patient,
      dateTime: template.dateTime,
      isOnline: template.isOnline,
      fee: template.fee,
      status: AppointmentStatus.pending,
      feedback: null,
    );
    _items.add(a);
    _notify();
    return a;
  }

  // ✅ Patient lists
  static List<Appointment> patientUpcoming() {
    final p = PatientProfileStore.current;
    if (p == null) return [];
    final now = DateTime.now();

    final list = _items.where((a) {
      return a.patient?.email == p.email &&
          a.dateTime.isAfter(now) &&
          a.status != AppointmentStatus.cancelled;
    }).toList();

    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  static List<Appointment> patientHistory() {
    final p = PatientProfileStore.current;
    if (p == null) return [];
    final now = DateTime.now();

    final list = _items.where((a) {
      final isMine = a.patient?.email == p.email;
      final isPast = a.dateTime.isBefore(now);
      final done = a.status == AppointmentStatus.completed;
      return isMine &&
          (isPast || done || a.status == AppointmentStatus.cancelled);
    }).toList();

    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  // ✅ Generic for Admin dashboard
  static List<Appointment> upcoming() {
    final now = DateTime.now();
    final list = _items
        .where(
          (a) =>
              a.dateTime.isAfter(now) &&
              a.status != AppointmentStatus.cancelled,
        )
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  // ✅ Doctor lists (fixes your missing methods)
  static List<Appointment> doctorPending(String doctorId) {
    return _items
        .where(
          (a) =>
              a.doctor.id == doctorId && a.status == AppointmentStatus.pending,
        )
        .toList();
  }

  static List<Appointment> doctorAccepted(String doctorId) {
    return _items
        .where(
          (a) =>
              a.doctor.id == doctorId && a.status == AppointmentStatus.accepted,
        )
        .toList();
  }

  static List<Appointment> doctorCompleted(String doctorId) {
    return _items
        .where(
          (a) =>
              a.doctor.id == doctorId &&
              a.status == AppointmentStatus.completed,
        )
        .toList();
  }

  // ✅ Actions
  static void delete(String id) {
    _items.removeWhere((a) => a.id == id);
    _notify();
  }

  static void cancel(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.cancelled;
    _notify();
  }

  static void reschedule(String id, DateTime newDateTime) {
    final a = byId(id);
    if (a == null) return;
    a.dateTime = newDateTime;
    a.status = AppointmentStatus.pending;
    _notify();
  }

  static void accept(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.accepted;
    _notify();
  }

  static void reject(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.rejected;
    _notify();
  }

  static void complete(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.completed;
    _notify();
  }

  static void addFeedback(String id, int rating, String comment) {
    final a = byId(id);
    if (a == null) return;
    if (a.status != AppointmentStatus.completed) return;

    a.feedback = FeedbackData(
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    _notify();
  }
}
