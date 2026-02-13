import 'package:flutter/foundation.dart';
import '../models/doctor.dart';

class DoctorRegistryStore {
  DoctorRegistryStore._();

  static final ValueNotifier<List<Doctor>> doctorsVN =
      ValueNotifier<List<Doctor>>([]);

  static List<Doctor> get doctors => doctorsVN.value;

  static void seedIfEmpty(List<Doctor> seed) {
    if (doctorsVN.value.isNotEmpty) return;
    doctorsVN.value = List<Doctor>.from(seed);
  }

  static bool isVerifiedDoctor(Doctor d) {
    // simple rule: verified doctors have tag in address/hospital? ❌ not good
    // better: store verification in memory map:
    return _verifiedIds.contains(d.id);
  }

  static final Set<String> _verifiedIds = <String>{};

  static void markVerified(String doctorId, bool verified) {
    if (verified) {
      _verifiedIds.add(doctorId);
    } else {
      _verifiedIds.remove(doctorId);
    }
    doctorsVN.value = List<Doctor>.from(doctorsVN.value); // trigger listeners
  }

  static List<Doctor> visibleForPatients() {
    return doctors.where((d) => _verifiedIds.contains(d.id)).toList();
  }

  static List<Doctor> pendingForAdmin() {
    return doctors.where((d) => !_verifiedIds.contains(d.id)).toList();
  }

  static void addPendingDoctor(Doctor doctor) {
    doctorsVN.value = [doctor, ...doctorsVN.value];
  }

  static Doctor? byId(String id) {
    try {
      return doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
