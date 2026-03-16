class MedicalReport {
  String title;
  String? attachmentData;
  String? attachmentName;

  MedicalReport({
    required this.title,
    this.attachmentData,
    this.attachmentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'attachmentData': attachmentData,
      'attachmentName': attachmentName,
    };
  }

  factory MedicalReport.fromMap(Map<String, dynamic> map) {
    return MedicalReport(
      title: map['title']?.toString() ?? '',
      attachmentData: map['attachmentData']?.toString(),
      attachmentName: map['attachmentName']?.toString(),
    );
  }
}

class PatientModel {
  String username;
  String password;

  String name;
  String dob;
  String address;
  String email;
  String phone;
  String? profileImagePath;
  String? profileImageData;
  List<MedicalReport> medicalReports;

  PatientModel({
    required this.username,
    required this.password,
    required this.name,
    required this.dob,
    required this.address,
    required this.email,
    required this.phone,
    this.profileImagePath,
    this.profileImageData,
    List<MedicalReport>? medicalReports,
  }) : medicalReports = medicalReports ?? [];

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'dob': dob,
      'address': address,
      'email': email,
      'phone': phone,
      'profileImagePath': profileImagePath,
      'profileImageData': profileImageData,
      'medicalReports': medicalReports.map((report) => report.toMap()).toList(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      profileImagePath: map['profileImagePath']?.toString(),
      profileImageData: map['profileImageData']?.toString(),
      medicalReports: (map['medicalReports'] as List<dynamic>?)
          ?.map(
            (report) => MedicalReport.fromMap(
              Map<String, dynamic>.from(report as Map),
            ),
          )
          .toList(),
    );
  }
}
