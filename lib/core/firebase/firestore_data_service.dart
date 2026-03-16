import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_state.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';

class FirestoreDataService {
  FirestoreDataService._();

  static final FirestoreDataService instance = FirestoreDataService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctors =>
      _firestore.collection('doctors');

  CollectionReference<Map<String, dynamic>> get _patients =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  /// Watch appointment documents matching the given filters.
  Stream<List<AppointmentModel>> watchAppointments({
    String? doctorUsername,
    String? patientUsername,
  }) {
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
    final snapshot = await _patients
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PatientModel.fromMap(snapshot.docs.first.data());
  }

  Future<void> saveDoctor(DoctorModel doctor) async {
    await _doctors.doc(doctor.username).set(doctor.toMap());
  }

  Future<void> savePatient(PatientModel patient) async {
    await _patients.doc(patient.username).set(patient.toMap());
  }

  Future<void> saveAppointment(AppointmentModel appointment) async {
    await _appointments.doc(appointment.id).set(appointment.toMap());
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
