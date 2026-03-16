import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';
import '../../models/appointment_model.dart';

class AppState {
  // ================= DOCTORS =================

  static List<DoctorModel> doctors = [];

  // ================= PATIENTS =================

  static List<PatientModel> patients = [];

  // ================= APPOINTMENTS =================

  static List<AppointmentModel> appointments = [];

  static List<String> notifications = [];
}
