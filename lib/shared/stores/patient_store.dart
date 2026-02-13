import '../models/patient.dart';
import '../models/medical_report.dart';

class PatientStore {
  static const Patient demoPatient = Patient(
    id: "p1",
    name: "Hamza",
    email: "hamza@email.com",
    phone: "+91 90000 00000",
    avatarUrl:
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200",
  );

  static final List<MedicalReport> _reports = [
    MedicalReport(
      id: "r1",
      patientId: "p1",
      title: "Blood Test Report",
      description: "Routine blood test results summary.",
      date: DateTime(2026, 1, 18),
      fileUrl: "https://example.com/blood-report.pdf",
    ),
    MedicalReport(
      id: "r2",
      patientId: "p1",
      title: "X-Ray Report",
      description: "Chest x-ray consultation report.",
      date: DateTime(2026, 2, 2),
      fileUrl: "https://example.com/xray.pdf",
    ),
  ];

  static List<MedicalReport> reportsFor(String patientId) =>
      _reports.where((r) => r.patientId == patientId).toList();

  static void addReport(MedicalReport report) {
    _reports.insert(0, report);
  }
}
