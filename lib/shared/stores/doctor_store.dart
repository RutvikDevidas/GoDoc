class DoctorProfileData {
  String name;
  String email;
  String phone;

  String bio;
  String clinicName;
  String clinicAddress;

  DoctorProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.clinicName,
    required this.clinicAddress,
  });
}

class DoctorScheduleSlot {
  final String day; // "Mon"
  final List<String> times; // ["09:00", "10:30"]

  DoctorScheduleSlot({required this.day, required this.times});
}

class DoctorStore {
  static DoctorProfileData profile = DoctorProfileData(
    name: "Dr. Ali Uzair",
    email: "doctor@godoc.com",
    phone: "+91 98888 88888",
    bio: "Experienced specialist. Patient-friendly consultation and treatment.",
    clinicName: "GoDoc Clinic",
    clinicAddress: "Main Road, City Center",
  );

  static List<DoctorScheduleSlot> schedule = [
    DoctorScheduleSlot(day: "Mon", times: ["09:00", "10:00", "11:00"]),
    DoctorScheduleSlot(day: "Tue", times: ["10:00", "11:30"]),
    DoctorScheduleSlot(day: "Wed", times: ["09:30", "10:30"]),
  ];

  static void updateProfile(DoctorProfileData data) {
    profile = data;
  }

  static void updateSchedule(List<DoctorScheduleSlot> newSchedule) {
    schedule = newSchedule;
  }
}
