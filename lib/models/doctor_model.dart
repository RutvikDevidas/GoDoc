class DoctorAvailability {
  final DateTime date;
  final List<String> timeSlots;

  DoctorAvailability({required this.date, required this.timeSlots});

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String(), 'timeSlots': timeSlots};
  }

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    return DoctorAvailability(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      timeSlots: _normalizeTimeSlots(map['timeSlots']),
    );
  }
}

class DoctorWeeklyAvailability {
  final int weekday;
  final List<String> timeSlots;

  DoctorWeeklyAvailability({required this.weekday, required this.timeSlots});

  Map<String, dynamic> toMap() {
    return {'weekday': weekday, 'timeSlots': timeSlots};
  }

  factory DoctorWeeklyAvailability.fromMap(Map<String, dynamic> map) {
    final parsedWeekday = int.tryParse(map['weekday']?.toString() ?? '');
    return DoctorWeeklyAvailability(
      weekday: parsedWeekday == null || parsedWeekday < 1 || parsedWeekday > 7
          ? DateTime.monday
          : parsedWeekday,
      timeSlots: _normalizeTimeSlots(map['timeSlots']),
    );
  }
}

DateTime _calendarDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<String> _normalizeTimeSlots(dynamic rawTimeSlots) {
  if (rawTimeSlots is! List) return <String>[];

  final slots =
      rawTimeSlots
          .where((slot) => slot != null)
          .map((slot) => slot.toString().trim())
          .where((slot) => slot.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  return slots;
}

List<DoctorWeeklyAvailability> normalizeWeeklyAvailability(
  Iterable<DoctorWeeklyAvailability> availability,
) {
  final grouped = <int, Set<String>>{};

  for (final slot in availability) {
    if (slot.weekday < DateTime.monday || slot.weekday > DateTime.sunday) {
      continue;
    }
    grouped
        .putIfAbsent(slot.weekday, () => <String>{})
        .addAll(
          slot.timeSlots
              .map((time) => time.trim())
              .where((time) => time.isNotEmpty),
        );
  }

  final normalized =
      grouped.entries
          .map(
            (entry) => DoctorWeeklyAvailability(
              weekday: entry.key,
              timeSlots: entry.value.toList()..sort(),
            ),
          )
          .toList()
        ..sort((a, b) => a.weekday.compareTo(b.weekday));

  return normalized;
}

List<DoctorAvailability> normalizeAvailabilityOverrides(
  Iterable<DoctorAvailability> availability,
) {
  final grouped = <DateTime, Set<String>>{};

  for (final slot in availability) {
    final day = _calendarDay(slot.date);
    grouped
        .putIfAbsent(day, () => <String>{})
        .addAll(
          slot.timeSlots
              .map((time) => time.trim())
              .where((time) => time.isNotEmpty),
        );
  }

  final normalized =
      grouped.entries
          .map(
            (entry) => DoctorAvailability(
              date: entry.key,
              timeSlots: entry.value.toList()..sort(),
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  return normalized;
}

List<DoctorWeeklyAvailability> defaultDoctorWeeklyAvailability() {
  return normalizeWeeklyAvailability([
    DoctorWeeklyAvailability(
      weekday: DateTime.monday,
      timeSlots: const ["10:00 AM", "11:00 AM", "01:30 PM"],
    ),
    DoctorWeeklyAvailability(
      weekday: DateTime.wednesday,
      timeSlots: const ["09:30 AM", "12:00 PM", "03:30 PM"],
    ),
    DoctorWeeklyAvailability(
      weekday: DateTime.friday,
      timeSlots: const ["10:30 AM", "02:00 PM", "05:00 PM"],
    ),
  ]);
}

List<DoctorWeeklyAvailability> deriveWeeklyAvailabilityFromDates(
  Iterable<DoctorAvailability> availability,
) {
  final grouped = <int, Set<String>>{};

  for (final slot in availability) {
    grouped
        .putIfAbsent(slot.date.weekday, () => <String>{})
        .addAll(slot.timeSlots);
  }

  if (grouped.isEmpty) {
    return defaultDoctorWeeklyAvailability();
  }

  return normalizeWeeklyAvailability(
    grouped.entries.map(
      (entry) => DoctorWeeklyAvailability(
        weekday: entry.key,
        timeSlots: entry.value.toList(),
      ),
    ),
  );
}

List<DoctorAvailability> buildUpcomingAvailability({
  required Iterable<DoctorWeeklyAvailability> weeklyAvailability,
  required Iterable<DoctorAvailability> availabilityOverrides,
  int horizonDays = 30,
}) {
  final today = _calendarDay(DateTime.now());
  final weekly = normalizeWeeklyAvailability(weeklyAvailability);
  final overrides = {
    for (final slot in normalizeAvailabilityOverrides(availabilityOverrides))
      _calendarDay(slot.date): slot,
  };

  final generated = <DoctorAvailability>[];
  for (var offset = 0; offset < horizonDays; offset++) {
    final date = today.add(Duration(days: offset));
    final override = overrides[date];
    if (override != null) {
      if (override.timeSlots.isNotEmpty) {
        generated.add(
          DoctorAvailability(date: date, timeSlots: override.timeSlots),
        );
      }
      continue;
    }

    final weeklySlot = weekly
        .where((slot) => slot.weekday == date.weekday)
        .firstOrNull;
    if (weeklySlot == null || weeklySlot.timeSlots.isEmpty) continue;

    generated.add(
      DoctorAvailability(
        date: date,
        timeSlots: List<String>.from(weeklySlot.timeSlots),
      ),
    );
  }

  return generated;
}

List<DoctorAvailability> normalizeUpcomingAvailability(
  Iterable<DoctorAvailability> availability,
) {
  final today = _calendarDay(DateTime.now());

  final normalized =
      availability
          .map(
            (slot) => DoctorAvailability(
              date: _calendarDay(slot.date),
              timeSlots: _normalizeTimeSlots(slot.timeSlots),
            ),
          )
          .where(
            (slot) => !slot.date.isBefore(today) && slot.timeSlots.isNotEmpty,
          )
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
  List<DoctorWeeklyAvailability> weeklyAvailability;
  List<DoctorAvailability> availabilityOverrides;
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
    List<DoctorWeeklyAvailability>? weeklyAvailability,
    List<DoctorAvailability>? availabilityOverrides,
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
       weeklyAvailability = normalizeWeeklyAvailability(
         weeklyAvailability ??
             deriveWeeklyAvailabilityFromDates(
               availability ?? _defaultAvailability(),
             ),
       ),
       availabilityOverrides = normalizeAvailabilityOverrides(
         availabilityOverrides ?? const <DoctorAvailability>[],
       ),
       availability = const <DoctorAvailability>[] {
    refreshAvailability();
  }

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
        date: startDate.add(const Duration(days: 2)),
        timeSlots: const ["09:30 AM", "12:00 PM", "03:30 PM"],
      ),
      DoctorAvailability(
        date: startDate.add(const Duration(days: 4)),
        timeSlots: const ["10:30 AM", "02:00 PM", "05:00 PM"],
      ),
    ];
  }

  void refreshAvailability({int horizonDays = 30}) {
    weeklyAvailability = normalizeWeeklyAvailability(weeklyAvailability);
    availabilityOverrides =
        normalizeAvailabilityOverrides(availabilityOverrides)
            .where((slot) => !slot.date.isBefore(_calendarDay(DateTime.now())))
            .toList();
    availability = buildUpcomingAvailability(
      weeklyAvailability: weeklyAvailability,
      availabilityOverrides: availabilityOverrides,
      horizonDays: horizonDays,
    );
  }

  List<String> timeSlotsForWeekday(int weekday) {
    return weeklyAvailability
            .where((slot) => slot.weekday == weekday)
            .firstOrNull
            ?.timeSlots ??
        const <String>[];
  }

  bool removeTimeSlotFromDate(DateTime date, String time) {
    final day = _calendarDay(date);
    final overrideIndex = availabilityOverrides.indexWhere(
      (slot) => _calendarDay(slot.date) == day,
    );

    List<String> timeSlots;
    if (overrideIndex >= 0) {
      timeSlots = List<String>.from(
        availabilityOverrides[overrideIndex].timeSlots,
      );
    } else {
      timeSlots = List<String>.from(timeSlotsForWeekday(day.weekday));
    }

    final removed = timeSlots.remove(time);
    if (!removed) return false;

    final updatedOverride = DoctorAvailability(date: day, timeSlots: timeSlots);
    if (overrideIndex >= 0) {
      availabilityOverrides[overrideIndex] = updatedOverride;
    } else {
      availabilityOverrides.add(updatedOverride);
    }

    refreshAvailability();
    return true;
  }

  Map<String, dynamic> toMap() {
    refreshAvailability();

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
      'weeklyAvailability': weeklyAvailability
          .map((slot) => slot.toMap())
          .toList(),
      'availabilityOverrides': availabilityOverrides
          .map((slot) => slot.toMap())
          .toList(),
      'availability': availability.map((slot) => slot.toMap()).toList(),
      'verified': verified,
      'rejected': rejected,
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    final rawAvailability = map['availability'];
    final rawWeeklyAvailability = map['weeklyAvailability'];
    final rawAvailabilityOverrides = map['availabilityOverrides'];

    final doctor = DoctorModel(
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
      weeklyAvailability: rawWeeklyAvailability is List
          ? rawWeeklyAvailability
                .whereType<Map>()
                .map(
                  (slot) => DoctorWeeklyAvailability.fromMap(
                    Map<String, dynamic>.from(slot),
                  ),
                )
                .toList()
          : null,
      availabilityOverrides: rawAvailabilityOverrides is List
          ? rawAvailabilityOverrides
                .whereType<Map>()
                .map(
                  (slot) => DoctorAvailability.fromMap(
                    Map<String, dynamic>.from(slot),
                  ),
                )
                .toList()
          : null,
      availability: rawAvailability is List
          ? rawAvailability
                .whereType<Map>()
                .map(
                  (slot) => DoctorAvailability.fromMap(
                    Map<String, dynamic>.from(slot),
                  ),
                )
                .toList()
          : null,
      verified: map['verified'] == true,
      rejected: map['rejected'] == true,
    );

    doctor.refreshAvailability();
    return doctor;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
