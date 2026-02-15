import 'doctor.dart';
import 'patient_profile.dart';

enum AppointmentStatus { pending, accepted, rejected, cancelled, completed }

class FeedbackData {
  final int rating;
  final String comment;
  final DateTime createdAt;

  FeedbackData({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class Appointment {
  String id;
  final Doctor doctor;
  final PatientProfile? patient;

  DateTime dateTime;
  bool isOnline;
  int fee;

  AppointmentStatus status;
  FeedbackData? feedback;

  Appointment({
    required this.id,
    required this.doctor,
    required this.patient,
    required this.dateTime,
    required this.isOnline,
    required this.fee,
    required this.status,
    required this.feedback,
  });
}
