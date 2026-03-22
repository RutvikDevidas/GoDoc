import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_state.dart';
import 'firebase_state.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';

class FirestoreDataService {
  FirestoreDataService._();

  static final FirestoreDataService instance = FirestoreDataService._();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctors =>
      _firestore.collection('doctors');

  CollectionReference<Map<String, dynamic>> get _patients =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  String _normalizedUsername(String username) => username.trim().toLowerCase();

  Future<List<DoctorModel>> getDoctors({bool verifiedOnly = false}) async {
    if (!firebaseAvailable) {
      return verifiedOnly
          ? AppState.doctors.where((doctor) => doctor.verified).toList()
          : List<DoctorModel>.from(AppState.doctors);
    }

    Query<Map<String, dynamic>> query = _doctors;
    if (verifiedOnly) {
      query = query.where('verified', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => DoctorModel.fromMap(doc.data())).toList();
  }

  Future<List<PatientModel>> getPatients() async {
    if (!firebaseAvailable) {
      return List<PatientModel>.from(AppState.patients);
    }

    final snapshot = await _patients.get();
    return snapshot.docs.map((doc) => PatientModel.fromMap(doc.data())).toList();
  }

  Future<List<AppointmentModel>> getAppointments({
    String? doctorUsername,
    String? patientUsername,
  }) async {
    if (!firebaseAvailable) {
      return AppState.appointments.where((appointment) {
        final matchesDoctor = doctorUsername == null
            ? true
            : appointment.doctorUsername == doctorUsername;
        final matchesPatient = patientUsername == null
            ? true
            : appointment.patientUsername == patientUsername;
        return matchesDoctor && matchesPatient;
      }).toList();
    }

    Query<Map<String, dynamic>> query = _appointments;
    if (doctorUsername != null) {
      query = query.where('doctorUsername', isEqualTo: doctorUsername);
    }
    if (patientUsername != null) {
      query = query.where('patientUsername', isEqualTo: patientUsername);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList();
  }

  Future<DoctorModel?> getDoctorByUsername(String username) async {
    if (!firebaseAvailable) {
      return AppState.doctors.where((doctor) => doctor.username == username).firstOrNull;
    }

    final snapshot = await _doctors.doc(username).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return DoctorModel.fromMap(snapshot.data()!);
  }

  Future<PatientModel?> getPatientByUsername(String username) async {
    if (!firebaseAvailable) {
      return AppState.patients.where((patient) => patient.username == username).firstOrNull;
    }

    final snapshot = await _patients.doc(username).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return PatientModel.fromMap(snapshot.data()!);
  }

  Future<AppointmentModel?> getAppointmentById(String id) async {
    if (!firebaseAvailable) {
      return AppState.appointments.where((appointment) => appointment.id == id).firstOrNull;
    }

    final snapshot = await _appointments.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppointmentModel.fromMap(snapshot.data()!);
  }

  Stream<List<DoctorModel>> watchDoctors({bool verifiedOnly = false}) {
    if (!firebaseAvailable) {
      final doctors = verifiedOnly
          ? AppState.doctors.where((doctor) => doctor.verified).toList()
          : List<DoctorModel>.from(AppState.doctors);
      return Stream.value(doctors);
    }

    Query<Map<String, dynamic>> query = _doctors;
    if (verifiedOnly) {
      query = query.where('verified', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Watch appointment documents matching the given filters.
  Stream<List<AppointmentModel>> watchAppointments({
    String? doctorUsername,
    String? patientUsername,
  }) {
    if (!firebaseAvailable) {
      final appointments = AppState.appointments.where((appointment) {
        final matchesDoctor = doctorUsername == null
            ? true
            : appointment.doctorUsername == doctorUsername;
        final matchesPatient = patientUsername == null
            ? true
            : appointment.patientUsername == patientUsername;
        return matchesDoctor && matchesPatient;
      }).toList();

      return Stream.value(appointments);
    }

    Query<Map<String, dynamic>> query = _appointments;

    if (doctorUsername != null) {
      query = query.where('doctorUsername', isEqualTo: doctorUsername);
    }
    if (patientUsername != null) {
      query = query.where('patientUsername', isEqualTo: patientUsername);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> seedAndSync() async {
    if (!firebaseAvailable && firebaseUnavailableReason != null) {
      return;
    }

    await _seedCollectionIfEmpty<DoctorModel>(
      collection: _doctors,
      items: AppState.doctors,
      idFor: (doctor) => doctor.username,
      mapFor: (doctor) => doctor.toMap(),
    );
    await _seedCollectionIfEmpty<PatientModel>(
      collection: _patients,
      items: AppState.patients,
      idFor: (patient) => patient.username,
      mapFor: (patient) => patient.toMap(),
    );
    await _seedCollectionIfEmpty<AppointmentModel>(
      collection: _appointments,
      items: AppState.appointments,
      idFor: (appointment) => appointment.id,
      mapFor: (appointment) => appointment.toMap(),
    );

    await syncAllToAppState();
  }

  Future<void> syncAllToAppState() async {
    if (!firebaseAvailable) {
      return;
    }

    final doctorsSnapshot = await _doctors.get();
    final patientsSnapshot = await _patients.get();
    final appointmentsSnapshot = await _appointments.get();

    AppState.doctors = doctorsSnapshot.docs
        .map((doc) => DoctorModel.fromMap(doc.data()))
        .toList();
    AppState.patients = patientsSnapshot.docs
        .map((doc) => PatientModel.fromMap(doc.data()))
        .toList();
    AppState.appointments = appointmentsSnapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList();
  }

  Future<DoctorModel?> findDoctorByCredentials({
    required String username,
    required String password,
  }) async {
    if (!firebaseAvailable) {
      return AppState.doctors
          .where(
            (doctor) =>
                doctor.username == username && doctor.password == password,
          )
          .firstOrNull;
    }

    final snapshot = await _doctors
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DoctorModel.fromMap(snapshot.docs.first.data());
  }

  Future<PatientModel?> findPatientByCredentials({
    required String username,
    required String password,
  }) async {
    if (!firebaseAvailable) {
      return AppState.patients
          .where(
            (patient) =>
                patient.username == username && patient.password == password,
          )
          .firstOrNull;
    }

    final snapshot = await _patients
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PatientModel.fromMap(snapshot.docs.first.data());
  }

  Future<bool> usernameExists(
    String username, {
    String? excludeDoctorUsername,
    String? excludePatientUsername,
  }) async {
    final normalized = _normalizedUsername(username);
    final normalizedExcludedDoctor = excludeDoctorUsername == null
        ? null
        : _normalizedUsername(excludeDoctorUsername);
    final normalizedExcludedPatient = excludePatientUsername == null
        ? null
        : _normalizedUsername(excludePatientUsername);

    final doctorExistsLocally = AppState.doctors.any((doctor) {
      final doctorUsername = _normalizedUsername(doctor.username);
      return doctorUsername == normalized &&
          doctorUsername != normalizedExcludedDoctor;
    });
    if (doctorExistsLocally) return true;

    final patientExistsLocally = AppState.patients.any((patient) {
      final patientUsername = _normalizedUsername(patient.username);
      return patientUsername == normalized &&
          patientUsername != normalizedExcludedPatient;
    });
    if (patientExistsLocally) return true;

    if (!firebaseAvailable) return false;

    final doctorSnapshot = await _doctors
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    final doctorTaken = doctorSnapshot.docs.any(
      (doc) => _normalizedUsername(doc.id) != normalizedExcludedDoctor,
    );
    if (doctorTaken) return true;

    final patientSnapshot = await _patients
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    return patientSnapshot.docs.any(
      (doc) => _normalizedUsername(doc.id) != normalizedExcludedPatient,
    );
  }

  Future<void> saveDoctor(DoctorModel doctor) async {
    if (!firebaseAvailable) {
      final index = AppState.doctors.indexWhere(
        (existingDoctor) => existingDoctor.username == doctor.username,
      );
      if (index >= 0) {
        AppState.doctors[index] = doctor;
      } else {
        AppState.doctors.add(doctor);
      }
      return;
    }

    await _doctors.doc(doctor.username).set(doctor.toMap());
  }

  Future<void> updateDoctorReviewStatus({
    required String username,
    required bool verified,
    required bool rejected,
  }) async {
    if (!firebaseAvailable) {
      final doctor = AppState.doctors
          .where((existingDoctor) => existingDoctor.username == username)
          .firstOrNull;
      if (doctor != null) {
        doctor.verified = verified;
        doctor.rejected = rejected;
      }
      return;
    }

    await _doctors.doc(username).set({
      'verified': verified,
      'rejected': rejected,
    }, SetOptions(merge: true));
  }

  Future<void> savePatient(PatientModel patient) async {
    if (!firebaseAvailable) {
      final index = AppState.patients.indexWhere(
        (existingPatient) => existingPatient.username == patient.username,
      );
      if (index >= 0) {
        AppState.patients[index] = patient;
      } else {
        AppState.patients.add(patient);
      }
      return;
    }

    await _patients.doc(patient.username).set(patient.toMap());
  }

  Future<void> saveAppointment(AppointmentModel appointment) async {
    if (!firebaseAvailable) {
      final index = AppState.appointments.indexWhere(
        (existingAppointment) => existingAppointment.id == appointment.id,
      );
      if (index >= 0) {
        AppState.appointments[index] = appointment;
      } else {
        AppState.appointments.add(appointment);
      }
      return;
    }

    await _appointments.doc(appointment.id).set(appointment.toMap());
  }

  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
  ) async {
    if (!firebaseAvailable) {
      final appointment = AppState.appointments
          .where((existingAppointment) => existingAppointment.id == appointmentId)
          .firstOrNull;
      if (appointment == null) return;

      final updatedAppointment = AppointmentModel.fromMap({
        ...appointment.toMap(),
        ...updates,
      });

      final index = AppState.appointments.indexWhere(
        (existingAppointment) => existingAppointment.id == appointmentId,
      );
      if (index >= 0) {
        AppState.appointments[index] = updatedAppointment;
      }
      return;
    }

    await _appointments.doc(appointmentId).set(updates, SetOptions(merge: true));
  }

  Future<void> saveAppointmentFeedback({
    required String appointmentId,
    required int rating,
    required String comments,
  }) async {
    await updateAppointment(appointmentId, {
      'feedbackSubmitted': true,
      'feedbackRating': rating,
      'feedbackComments': comments,
    });
  }

  Future<void> deleteDoctor(String username) async {
    if (!firebaseAvailable) {
      AppState.doctors.removeWhere((doctor) => doctor.username == username);
      AppState.appointments.removeWhere(
        (appointment) => appointment.doctorUsername == username,
      );
      return;
    }

    final appointmentSnapshot = await _appointments
        .where('doctorUsername', isEqualTo: username)
        .get();

    final batch = _firestore.batch();
    batch.delete(_doctors.doc(username));
    for (final doc in appointmentSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deletePatient(String username) async {
    if (!firebaseAvailable) {
      AppState.patients.removeWhere((patient) => patient.username == username);
      AppState.appointments.removeWhere(
        (appointment) => appointment.patientUsername == username,
      );
      return;
    }

    final appointmentSnapshot = await _appointments
        .where('patientUsername', isEqualTo: username)
        .get();

    final batch = _firestore.batch();
    batch.delete(_patients.doc(username));
    for (final doc in appointmentSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteAppointment(String appointmentId) async {
    if (!firebaseAvailable) {
      AppState.appointments.removeWhere(
        (appointment) => appointment.id == appointmentId,
      );
      return;
    }

    await _appointments.doc(appointmentId).delete();
  }

  Future<void> _seedCollectionIfEmpty<T>({
    required CollectionReference<Map<String, dynamic>> collection,
    required List<T> items,
    required String Function(T item) idFor,
    required Map<String, dynamic> Function(T item) mapFor,
  }) async {
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final item in items) {
      batch.set(collection.doc(idFor(item)), mapFor(item));
    }
    await batch.commit();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
