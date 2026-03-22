class AppointmentModel {
  String id;
  String doctorUsername;
  String patientUsername;

  String date;
  String time;
  String type; // Online / Offline

  String status;
  // pending
  // confirmed
  // rejected
  // rescheduled
  // cancelled

  String? rescheduledDate;
  String? rescheduledTime;
  bool refundIssued;
  double refundPercentage;
  String? refundReason;
  DateTime? refundedAt;

  // Video call state (doctor initiates; patient joins)
  bool callStarted;
  String? callRoom;
  DateTime? callStartedAt;
  DateTime? callEndedAt;

  // Feedback from patient after appointment
  bool feedbackSubmitted;
  String? feedbackComments;
  int? feedbackRating;

  AppointmentModel({
    required this.id,
    required this.doctorUsername,
    required this.patientUsername,
    required this.date,
    required this.time,
    required this.type,
    this.status = "pending",
    this.rescheduledDate,
    this.rescheduledTime,
    this.refundIssued = false,
    this.refundPercentage = 0,
    this.refundReason,
    this.refundedAt,
    this.callStarted = false,
    this.callRoom,
    this.callStartedAt,
    this.callEndedAt,
    this.feedbackSubmitted = false,
    this.feedbackComments,
    this.feedbackRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorUsername': doctorUsername,
      'patientUsername': patientUsername,
      'date': date,
      'time': time,
      'type': type,
      'status': status,
      'rescheduledDate': rescheduledDate,
      'rescheduledTime': rescheduledTime,
      'refundIssued': refundIssued,
      'refundPercentage': refundPercentage,
      'refundReason': refundReason,
      'refundedAt': refundedAt?.toIso8601String(),
      'callStarted': callStarted,
      'callRoom': callRoom,
      'callStartedAt': callStartedAt?.toIso8601String(),
      'callEndedAt': callEndedAt?.toIso8601String(),
      'feedbackSubmitted': feedbackSubmitted,
      'feedbackComments': feedbackComments,
      'feedbackRating': feedbackRating,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id']?.toString() ?? '',
      doctorUsername: map['doctorUsername']?.toString() ?? '',
      patientUsername: map['patientUsername']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      rescheduledDate: map['rescheduledDate']?.toString(),
      rescheduledTime: map['rescheduledTime']?.toString(),
      refundIssued: map['refundIssued'] == true,
      refundPercentage: (map['refundPercentage'] as num?)?.toDouble() ?? 0,
      refundReason: map['refundReason']?.toString(),
      refundedAt: DateTime.tryParse(map['refundedAt']?.toString() ?? ''),
      callStarted: map['callStarted'] == true,
      callRoom: map['callRoom']?.toString(),
      callStartedAt: DateTime.tryParse(map['callStartedAt']?.toString() ?? ''),
      callEndedAt: DateTime.tryParse(map['callEndedAt']?.toString() ?? ''),
      feedbackSubmitted: map['feedbackSubmitted'] == true,
      feedbackComments: map['feedbackComments']?.toString(),
      feedbackRating: (map['feedbackRating'] as num?)?.toInt(),
    );
  }
}
