import '../../core/utils/ids.dart';
import '../data/demo_data.dart';
import '../models/appointment.dart';
import 'patient_store.dart';
import '../models/feedback.dart';

class AppointmentStore {
  static final List<Appointment> _items = [
    Appointment(
      id: "a1",
      doctor: DemoData.doctors.first,
      patient: PatientStore.demoPatient,
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      isOnline: false,
      fee: 499,
      status: AppointmentStatus.pending,
    ),
    Appointment(
      id: "a2",
      doctor: DemoData.doctors[2],
      patient: PatientStore.demoPatient,
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      isOnline: true,
      fee: 499,
      status: AppointmentStatus.completed,
    ),
  ];

  static List<Appointment> all() => List.unmodifiable(_items);

  // Patient view
  static List<Appointment> patientUpcoming() =>
      _items.where((a) => a.status != AppointmentStatus.completed).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  static List<Appointment> patientHistory() =>
      _items.where((a) => a.status == AppointmentStatus.completed).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  // Doctor view
  static List<Appointment> doctorPending() =>
      _items.where((a) => a.status == AppointmentStatus.pending).toList();

  static List<Appointment> doctorAccepted() =>
      _items.where((a) => a.status == AppointmentStatus.accepted).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  static List<Appointment> doctorCompleted() =>
      _items.where((a) => a.status == AppointmentStatus.completed).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  static Appointment? byId(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static void add(Appointment appt) => _items.insert(0, appt);

  static void delete(String id) => _items.removeWhere((a) => a.id == id);

  static void reschedule(String id, DateTime newDateTime, bool isOnline) {
    final appt = byId(id);
    if (appt == null) return;
    appt.dateTime = newDateTime;
    appt.isOnline = isOnline;
  }

  // Doctor actions
  static void accept(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.accepted;
  }

  static void reject(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.rejected;
  }

  static void complete(String id) {
    final a = byId(id);
    if (a == null) return;
    a.status = AppointmentStatus.completed;
  }

  // Patient feedback
  static void addFeedback(String id, int rating, String comment) {
    final a = byId(id);
    if (a == null) return;
    if (a.status != AppointmentStatus.completed) return;
    a.feedback = FeedbackData(
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
  }

  static Appointment createNewFromBooking({required Appointment template}) {
    return Appointment(
      id: "a_${Ids.now()}",
      doctor: template.doctor,
      patient: template.patient,
      dateTime: template.dateTime,
      isOnline: template.isOnline,
      fee: template.fee,
      status: AppointmentStatus.pending,
    );
  }
}
