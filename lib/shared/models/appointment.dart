import 'doctor.dart';
import 'patient.dart';
import 'feedback.dart';

enum AppointmentStatus { pending, accepted, rejected, completed }

class Appointment {
  final String id;
  final Doctor doctor;
  final Patient patient;

  DateTime dateTime;
  bool isOnline;
  final int fee;

  AppointmentStatus status;
  FeedbackData? feedback; // patient can add after completed

  Appointment({
    required this.id,
    required this.doctor,
    required this.patient,
    required this.dateTime,
    required this.isOnline,
    required this.fee,
    this.status = AppointmentStatus.pending,
    this.feedback,
  });

  bool get isCompleted => status == AppointmentStatus.completed;
}
