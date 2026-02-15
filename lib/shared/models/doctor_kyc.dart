class DoctorKyc {
  final String doctorId;

  final String name;
  final DateTime dob;
  final int yearOfPassing;
  final String licenseNo;
  final String phone;
  final String email;

  final String clinicName;
  final String clinicAddress;
  final double clinicLat;
  final double clinicLng;

  final String doctorAddress;
  final List<String> specializations; // ids or names
  final String imageUrl;

  const DoctorKyc({
    required this.doctorId,
    required this.name,
    required this.dob,
    required this.yearOfPassing,
    required this.licenseNo,
    required this.phone,
    required this.email,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicLat,
    required this.clinicLng,
    required this.doctorAddress,
    required this.specializations,
    required this.imageUrl,
  });

  int get age {
    final now = DateTime.now();
    int a = now.year - dob.year;
    final hadBirthday =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) a--;
    return a;
  }
}
