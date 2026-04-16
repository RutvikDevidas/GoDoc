import '../../models/admin_model.dart';
import 'demo_seed_data.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';
import '../../models/appointment_model.dart';

class AppState {
  static List<AdminModel> admins = [DemoSeedData.defaultAdmin];

  // ================= DOCTORS =================

  static List<DoctorModel> doctors = List<DoctorModel>.from(
    DemoSeedData.initialDoctors,
  );

  // ================= PATIENTS =================

  static List<PatientModel> patients = [];

  // ================= APPOINTMENTS =================

  static List<AppointmentModel> appointments = [];

  static List<String> patientNotifications = [];
  static List<String> doctorNotifications = [];
}
