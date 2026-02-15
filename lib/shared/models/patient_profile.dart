class PatientProfile {
  final String name;
  final String email;
  final String phone;
  final String dob; // yyyy-mm-dd
  final int age;
  final String imageUrl; // local path or url

  PatientProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.age,
    required this.imageUrl,
  });
}
