import '../models/doctor_kyc.dart';

class DoctorKycStore {
  static final Map<String, DoctorKyc> _map = {};

  static void save(DoctorKyc kyc) {
    _map[kyc.doctorId] = kyc;
  }

  static DoctorKyc? byDoctorId(String id) => _map[id];
}
