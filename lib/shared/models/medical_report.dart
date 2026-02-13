class MedicalReport {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final DateTime date;
  final String fileUrl; // demo link

  const MedicalReport({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.date,
    required this.fileUrl,
  });
}
