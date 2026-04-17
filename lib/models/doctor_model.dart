class DoctorAvailability {
  final DateTime date;
  final List<String> timeSlots;

  DoctorAvailability({required this.date, required this.timeSlots});

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String(), 'timeSlots': timeSlots};
  }

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    final rawTimeSlots = map['timeSlots'];

    return DoctorAvailability(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      timeSlots: rawTimeSlots is List
          ? rawTimeSlots
                .where((slot) => slot != null)
                .map((slot) => slot.toString())
                .where((slot) => slot.trim().isNotEmpty)
                .toList()
          : const <String>[],
    );
  }
}

DateTime _calendarDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<DoctorAvailability> normalizeUpcomingAvailability(
  Iterable<DoctorAvailability> availability,
) {
  final today = _calendarDay(DateTime.now());

  final normalized = availability
      .map(
        (slot) => DoctorAvailability(
          date: _calendarDay(slot.date),
          timeSlots: slot.timeSlots
              .map((time) => time.trim())
              .where((time) => time.isNotEmpty)
              .toList(),
        ),
      )
      .where((slot) => !slot.date.isBefore(today) && slot.timeSlots.isNotEmpty)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return normalized;
}

class DoctorModel {
  String username;
  String password;

  String name;
  String dob;

  String prNumber;
  String nmcNumber;
  String licenceNumber;

  String specialization;
  String phone;
  String clinicName;
  String clinicAddress;
  String clinicLocation;
  double? clinicLatitude;
  double? clinicLongitude;
  String bio;
  String upiId;
  String bankAccountHolder;
  String bankName;
  String bankAccountNumber;
  String bankIfscCode;
  String? profileImageData;
  double consultationFee;
  List<DoctorAvailability> availability;

  bool verified;
  bool rejected;

  DoctorModel({
    required this.username,
    required this.password,
    required this.name,
    required this.dob,
    required this.prNumber,
    required this.nmcNumber,
    required this.licenceNumber,
    required this.specialization,
    required this.phone,
    required this.clinicName,
    required this.clinicAddress,
    String? clinicLocation,
    this.clinicLatitude,
    this.clinicLongitude,
    String? bio,
    String? upiId,
    String? bankAccountHolder,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfscCode,
    this.profileImageData,
    this.consultationFee = 500,
    List<DoctorAvailability>? availability,
    this.verified = false,
    this.rejected = false,
  }) : clinicLocation = clinicLocation ?? clinicAddress,
       bio = bio ?? _defaultBio(name, specialization, clinicName),
       upiId = upiId ?? '',
       bankAccountHolder = bankAccountHolder ?? '',
       bankName = bankName ?? '',
       bankAccountNumber = bankAccountNumber ?? '',
       bankIfscCode = bankIfscCode ?? '',
       availability = normalizeUpcomingAvailability(
         availability ?? _defaultAvailability(),
       );

  static String _defaultBio(
    String name,
    String specialization,
    String clinicName,
  ) {
    return "$name is a trusted $specialization offering patient-focused care, "
        "clear guidance, and consistent follow-up through $clinicName.";
  }

  static List<DoctorAvailability> _defaultAvailability() {
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return [
      DoctorAvailability(
        date: startDate,
        timeSlots: const ["10:00 AM", "11:00 AM", "01:30 PM"],
      ),
      DoctorAvailability(
        date: startDate.add(const Duration(days: 1)),
        timeSlots: const ["09:30 AM", "12:00 PM", "03:30 PM"],
      ),
      DoctorAvailability(
        date: startDate.add(const Duration(days: 3)),
        timeSlots: const ["10:30 AM", "02:00 PM", "05:00 PM"],
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'dob': dob,
      'prNumber': prNumber,
      'nmcNumber': nmcNumber,
      'licenceNumber': licenceNumber,
      'specialization': specialization,
      'phone': phone,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'clinicLocation': clinicLocation,
      'clinicLatitude': clinicLatitude,
      'clinicLongitude': clinicLongitude,
      'bio': bio,
      'upiId': upiId,
      'bankAccountHolder': bankAccountHolder,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankIfscCode': bankIfscCode,
      'profileImageData': profileImageData,
      'consultationFee': consultationFee,
      'availability': availability.map((slot) => slot.toMap()).toList(),
      'verified': verified,
      'rejected': rejected,
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    final rawAvailability = map['availability'];

    return DoctorModel(
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      prNumber: map['prNumber']?.toString() ?? '',
      nmcNumber: map['nmcNumber']?.toString() ?? '',
      licenceNumber: map['licenceNumber']?.toString() ?? '',
      specialization: map['specialization']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      clinicName: map['clinicName']?.toString() ?? '',
      clinicAddress: map['clinicAddress']?.toString() ?? '',
      clinicLocation: map['clinicLocation']?.toString(),
      clinicLatitude: (map['clinicLatitude'] as num?)?.toDouble(),
      clinicLongitude: (map['clinicLongitude'] as num?)?.toDouble(),
      bio: map['bio']?.toString(),
      upiId: map['upiId']?.toString(),
      bankAccountHolder: map['bankAccountHolder']?.toString(),
      bankName: map['bankName']?.toString(),
      bankAccountNumber: map['bankAccountNumber']?.toString(),
      bankIfscCode: map['bankIfscCode']?.toString(),
      profileImageData: map['profileImageData']?.toString(),
      consultationFee: (map['consultationFee'] as num?)?.toDouble() ?? 500,
      availability: rawAvailability is List
          ? normalizeUpcomingAvailability(
              rawAvailability
                  .whereType<Map>()
                  .map(
                    (slot) => DoctorAvailability.fromMap(
                      Map<String, dynamic>.from(slot),
                    ),
                  ),
            )
          : null,
      verified: map['verified'] == true,
      rejected: map['rejected'] == true,
    );
  }
}
