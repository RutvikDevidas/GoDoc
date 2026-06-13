import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_state.dart';
import '../data/demo_seed_data.dart';
import 'firebase_state.dart';
import '../../models/admin_model.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';

class FirestoreDataService {
  FirestoreDataService._();

  static final FirestoreDataService instance = FirestoreDataService._();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get _godocRoot =>
      _firestore.collection('GODOC-app').doc('data');

  static const String _approvedDoctorsBucketId = 'approved doctors';
  static const String _pendingDoctorsBucketId = 'pending doctors';
  static const String _rejectedDoctorsBucketId = 'rejected doctors';

  CollectionReference<Map<String, dynamic>> get _doctors =>
      _godocRoot.collection('doctors');

  DocumentReference<Map<String, dynamic>> get _approvedDoctorsBucket =>
      _doctors.doc(_approvedDoctorsBucketId);

  DocumentReference<Map<String, dynamic>> get _pendingDoctorsBucket =>
      _doctors.doc(_pendingDoctorsBucketId);

  DocumentReference<Map<String, dynamic>> get _rejectedDoctorsBucket =>
      _doctors.doc(_rejectedDoctorsBucketId);

  CollectionReference<Map<String, dynamic>> _doctorProfiles(String bucketId) =>
      _doctors.doc(bucketId).collection('profiles');

  CollectionReference<Map<String, dynamic>> get _admins =>
      _godocRoot.collection('admins');

  CollectionReference<Map<String, dynamic>> get _patients =>
      _godocRoot.collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _godocRoot.collection('appointments');

  DocumentReference<Map<String, dynamic>> _patientDoc(String username) =>
      _patients.doc(username);

  CollectionReference<Map<String, dynamic>> _patientPayments(String username) =>
      _patientDoc(username).collection('payments');

  CollectionReference<Map<String, dynamic>> _patientFeedback(String username) =>
      _patientDoc(username).collection('feedback');

  CollectionReference<Map<String, dynamic>> _patientReports(String username) =>
      _patientDoc(username).collection('medical_reports');

  String _normalizedUsername(String username) => username.trim().toLowerCase();

  Iterable<String> get _doctorBucketIds => const [
    _approvedDoctorsBucketId,
    _pendingDoctorsBucketId,
    _rejectedDoctorsBucketId,
  ];

  String _doctorBucketIdFor(DoctorModel doctor) {
    if (doctor.verified) return _approvedDoctorsBucketId;
    if (doctor.rejected) return _rejectedDoctorsBucketId;
    return _pendingDoctorsBucketId;
  }

  Future<List<DoctorModel>> getDoctors({bool verifiedOnly = false}) async {
    if (!firebaseAvailable) {
      return verifiedOnly
          ? AppState.doctors.where((doctor) => doctor.verified).toList()
          : List<DoctorModel>.from(AppState.doctors);
    }

    await _ensureDoctorBucketDocs();
    await _migrateLegacyDoctorDocuments();

    final bucketIds = verifiedOnly
        ? <String>[_approvedDoctorsBucketId]
        : _doctorBucketIds.toList();
    return _getDoctorsFromBuckets(bucketIds);
  }

  Future<List<AdminModel>> getAdmins() async {
    if (!firebaseAvailable) {
      return List<AdminModel>.from(AppState.admins);
    }

    final snapshot = await _admins.get();
    return snapshot.docs.map((doc) => AdminModel.fromMap(doc.data())).toList();
  }

  Future<List<PatientModel>> getPatients() async {
    if (!firebaseAvailable) {
      print(
        'ℹ️  Firebase unavailable - returning cached patients. Count: ${AppState.patients.length}',
      );
      return List<PatientModel>.from(AppState.patients);
    }

    try {
      print('🔄 Fetching patients from Firestore...');
      final snapshot = await _patients.get();
      print('✅ Fetched ${snapshot.docs.length} patient documents');

      final patients = await _hydratePatientsWithReports(snapshot.docs);
      print(
        '✅ Successfully hydrated ${patients.length} patients with their medical reports',
      );
      return patients;
    } catch (e) {
      print('❌ Error fetching patients: $e');
      rethrow;
    }
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
      return AppState.doctors
          .where((doctor) => doctor.username == username)
          .firstOrNull;
    }

    await _ensureDoctorBucketDocs();
    await _migrateLegacyDoctorDocuments();

    for (final bucketId in _doctorBucketIds) {
      final snapshot = await _doctorProfiles(bucketId).doc(username).get();
      if (snapshot.exists && snapshot.data() != null) {
        return DoctorModel.fromMap(snapshot.data()!);
      }
    }

    return null;
  }

  Future<AdminModel?> getAdminByUsername(String username) async {
    if (!firebaseAvailable) {
      return AppState.admins
          .where((admin) => admin.username == username)
          .firstOrNull;
    }

    final snapshot = await _admins.doc(username).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AdminModel.fromMap(snapshot.data()!);
  }

  Future<PatientModel?> getPatientByUsername(String username) async {
    if (!firebaseAvailable) {
      return AppState.patients
          .where((patient) => patient.username == username)
          .firstOrNull;
    }

    final snapshot = await _patients.doc(username).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return _hydratePatientReports(PatientModel.fromMap(snapshot.data()!));
  }

  Future<AppointmentModel?> getAppointmentById(String id) async {
    if (!firebaseAvailable) {
      return AppState.appointments
          .where((appointment) => appointment.id == id)
          .firstOrNull;
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

    final bucketIds = verifiedOnly
        ? <String>[_approvedDoctorsBucketId]
        : _doctorBucketIds.toList();

    late final StreamController<List<DoctorModel>> controller;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    final snapshotsByBucket = <String, List<DoctorModel>>{
      for (final bucketId in bucketIds) bucketId: <DoctorModel>[],
    };

    void emitCombined() {
      final doctors = <DoctorModel>[];
      for (final bucketId in bucketIds) {
        doctors.addAll(snapshotsByBucket[bucketId] ?? const <DoctorModel>[]);
      }
      controller.add(doctors);
    }

    controller = StreamController<List<DoctorModel>>(
      onListen: () {
        _startWatchingDoctorBuckets(
          bucketIds: bucketIds,
          subscriptions: subscriptions,
          snapshotsByBucket: snapshotsByBucket,
          emitCombined: emitCombined,
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
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

    await _ensureDocumentExists(
      collection: _admins,
      id: DemoSeedData.defaultAdmin.username,
      data: DemoSeedData.defaultAdmin.toMap(),
    );
    await _ensureDoctorBucketDocs();
    await _seedDoctorsIfEmpty(AppState.doctors);
    await _seedCollectionIfEmpty<PatientModel>(
      collection: _patients,
      items: AppState.patients,
      idFor: (patient) => patient.username,
      mapFor: (patient) => _patientDocumentMap(patient),
    );
    await _seedCollectionIfEmpty<AppointmentModel>(
      collection: _appointments,
      items: AppState.appointments,
      idFor: (appointment) => appointment.id,
      mapFor: (appointment) => appointment.toMap(),
    );

    await syncAllToAppState();
    await _backfillPatientSubcollections();
  }

  Future<void> syncAllToAppState() async {
    if (!firebaseAvailable) {
      print('ℹ️  Firebase unavailable - sync skipped');
      return;
    }

    try {
      print('🔄 Starting full app state sync from Firestore...');

      final adminsSnapshot = await _admins.get();
      print('✅ Fetched ${adminsSnapshot.docs.length} admins');

      final patientsSnapshot = await _patients.get();
      print('✅ Fetched ${patientsSnapshot.docs.length} patient documents');

      final appointmentsSnapshot = await _appointments.get();
      print('✅ Fetched ${appointmentsSnapshot.docs.length} appointments');

      AppState.admins = adminsSnapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data()))
          .toList();
      print('✅ Updated AppState.admins (${AppState.admins.length} records)');

      AppState.doctors = await getDoctors();
      print('✅ Updated AppState.doctors (${AppState.doctors.length} records)');

      AppState.patients = await _hydratePatientsWithReports(
        patientsSnapshot.docs,
      );
      print(
        '✅ Updated AppState.patients (${AppState.patients.length} records)',
      );

      AppState.appointments = appointmentsSnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
      print(
        '✅ Updated AppState.appointments (${AppState.appointments.length} records)',
      );

      await _cleanupExpiredDoctorAvailability();
      print('✅ Full app state sync completed successfully');
    } catch (e) {
      print('❌ Error during app state sync: $e');
      print('Stack: ${StackTrace.current}');
      rethrow;
    }
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

    final doctor = await getDoctorByUsername(username.trim());
    if (doctor == null) return null;
    return doctor.password == password ? doctor : null;
  }

  Future<AdminModel?> findAdminByCredentials({
    required String username,
    required String password,
  }) async {
    if (!firebaseAvailable) {
      return AppState.admins
          .where(
            (admin) => admin.username == username && admin.password == password,
          )
          .firstOrNull;
    }

    final document = await _admins.doc(username.trim()).get();
    final data = document.data();
    if (data == null) return null;

    final admin = AdminModel.fromMap(data);
    return admin.password == password ? admin : null;
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

    final document = await _patients.doc(username.trim()).get();
    final data = document.data();
    if (data == null) return null;

    final patient = PatientModel.fromMap(data);
    return patient.password == password ? patient : null;
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

    final adminExistsLocally = AppState.admins.any((admin) {
      final adminUsername = _normalizedUsername(admin.username);
      return adminUsername == normalized;
    });
    if (adminExistsLocally) return true;

    if (!firebaseAvailable) return false;

    final doctor = await getDoctorByUsername(username.trim());
    final doctorTaken =
        doctor != null &&
        _normalizedUsername(doctor.username) != normalizedExcludedDoctor;
    if (doctorTaken) return true;

    final patientSnapshot = await _patients
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    final patientTaken = patientSnapshot.docs.any(
      (doc) => _normalizedUsername(doc.id) != normalizedExcludedPatient,
    );
    if (patientTaken) return true;

    final adminSnapshot = await _admins
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    return adminSnapshot.docs.isNotEmpty;
  }

  Future<String?> duplicateDoctorCredentialLabel({
    required String prNumber,
    required String nmcNumber,
    required String licenceNumber,
    String? excludeDoctorUsername,
  }) async {
    String normalize(String value) => value.trim().toLowerCase();

    final normalizedPrNumber = normalize(prNumber);
    final normalizedNmcNumber = normalize(nmcNumber);
    final normalizedLicenceNumber = normalize(licenceNumber);
    final normalizedExcludedDoctor = excludeDoctorUsername == null
        ? null
        : _normalizedUsername(excludeDoctorUsername);

    bool matchesExcludedDoctor(DoctorModel doctor) {
      return normalizedExcludedDoctor != null &&
          _normalizedUsername(doctor.username) == normalizedExcludedDoctor;
    }

    for (final doctor in AppState.doctors) {
      if (matchesExcludedDoctor(doctor)) continue;

      if (normalize(doctor.prNumber) == normalizedPrNumber) {
        return 'PR number';
      }
      if (normalize(doctor.nmcNumber) == normalizedNmcNumber) {
        return 'NMC number';
      }
      if (normalize(doctor.licenceNumber) == normalizedLicenceNumber) {
        return 'Licence number';
      }
    }

    if (!firebaseAvailable) return null;

    final doctors = await getDoctors();
    for (final doctor in doctors) {
      if (matchesExcludedDoctor(doctor)) continue;

      if (normalize(doctor.prNumber) == normalizedPrNumber) {
        return 'PR number';
      }
      if (normalize(doctor.nmcNumber) == normalizedNmcNumber) {
        return 'NMC number';
      }
      if (normalize(doctor.licenceNumber) == normalizedLicenceNumber) {
        return 'Licence number';
      }
    }

    return null;
  }

  Future<void> saveAdmin(AdminModel admin) async {
    if (!firebaseAvailable) {
      final index = AppState.admins.indexWhere(
        (existingAdmin) => existingAdmin.username == admin.username,
      );
      if (index >= 0) {
        AppState.admins[index] = admin;
      } else {
        AppState.admins.add(admin);
      }
      return;
    }

    await _admins.doc(admin.username).set(admin.toMap());
  }

  Future<void> saveDoctor(DoctorModel doctor) async {
    doctor.refreshAvailability();

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

    await _ensureDoctorBucketDocs();
    await _upsertDoctorInBuckets(doctor);
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

    final doctor = await getDoctorByUsername(username);
    if (doctor == null) return;
    doctor.verified = verified;
    doctor.rejected = rejected;
    await saveDoctor(doctor);
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

    await _patients.doc(patient.username).set(_patientDocumentMap(patient));
    await _syncPatientReportsSubcollection(patient);
  }

  Future<void> addMedicalReportForPatient({
    required String patientUsername,
    required MedicalReport report,
  }) async {
    if (!firebaseAvailable) {
      final patient = AppState.patients
          .where(
            (existingPatient) => existingPatient.username == patientUsername,
          )
          .firstOrNull;
      if (patient == null) return;

      patient.medicalReports = List<MedicalReport>.from(patient.medicalReports)
        ..add(report);
      return;
    }

    final reportsCollection = _patientReports(patientUsername);
    final reportCount = (await reportsCollection.count().get()).count ?? 0;
    final docId = 'report_${(reportCount + 1).toString().padLeft(3, '0')}';

    await reportsCollection.doc(docId).set({
      ...report.toMap(),
      'patientUsername': patientUsername,
      'reportIndex': reportCount,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final patientIndex = AppState.patients.indexWhere(
      (existingPatient) => existingPatient.username == patientUsername,
    );
    if (patientIndex >= 0) {
      AppState.patients[patientIndex].medicalReports = List<MedicalReport>.from(
        AppState.patients[patientIndex].medicalReports,
      )..add(report);
    }
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
    await _syncPatientAppointmentSubcollections(appointment);
  }

  void mergeAppointmentsIntoAppState(
    Iterable<AppointmentModel> appointments, {
    String? doctorUsername,
    String? patientUsername,
  }) {
    final mergedAppointments = AppState.appointments.where((appointment) {
      final matchesDoctor = doctorUsername == null
          ? true
          : appointment.doctorUsername == doctorUsername;
      final matchesPatient = patientUsername == null
          ? true
          : appointment.patientUsername == patientUsername;
      return !(matchesDoctor && matchesPatient);
    }).toList();

    mergedAppointments.addAll(appointments);
    AppState.appointments = mergedAppointments;
  }

  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
  ) async {
    if (!firebaseAvailable) {
      final appointment = AppState.appointments
          .where(
            (existingAppointment) => existingAppointment.id == appointmentId,
          )
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

    await _appointments
        .doc(appointmentId)
        .set(updates, SetOptions(merge: true));
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

    if (!firebaseAvailable) return;

    final appointment = await getAppointmentById(appointmentId);
    if (appointment == null) return;

    await _syncPatientAppointmentSubcollections(appointment);
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
    for (final bucketId in _doctorBucketIds) {
      batch.delete(_doctorProfiles(bucketId).doc(username));
    }
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
    final paymentsSnapshot = await _patientPayments(username).get();
    final feedbackSnapshot = await _patientFeedback(username).get();
    final reportsSnapshot = await _patientReports(username).get();

    final batch = _firestore.batch();
    batch.delete(_patients.doc(username));
    for (final doc in appointmentSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in paymentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in feedbackSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in reportsSnapshot.docs) {
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

  Future<void> _ensureDocumentExists({
    required CollectionReference<Map<String, dynamic>> collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final document = await collection.doc(id).get();
    if (document.exists) return;

    await collection.doc(id).set(data);
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

  Future<void> _backfillPatientSubcollections() async {
    await _ensureDoctorBucketDocs();
    await _migrateLegacyDoctorDocuments();

    for (final patient in AppState.patients) {
      await _syncPatientReportsSubcollection(patient);
      await _patientDoc(patient.username).set({
        'medicalReports': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final appointment in AppState.appointments) {
      await _syncPatientAppointmentSubcollections(appointment);
    }
  }

  Future<void> _cleanupExpiredDoctorAvailability() async {
    for (final doctor in AppState.doctors) {
      final previousWeekly = doctor.weeklyAvailability
          .map(
            (slot) => DoctorWeeklyAvailability(
              weekday: slot.weekday,
              timeSlots: List<String>.from(slot.timeSlots),
            ),
          )
          .toList();
      final previousOverrides = doctor.availabilityOverrides
          .map(
            (slot) => DoctorAvailability(
              date: slot.date,
              timeSlots: List<String>.from(slot.timeSlots),
            ),
          )
          .toList();
      final previousAvailability = doctor.availability
          .map(
            (slot) => DoctorAvailability(
              date: slot.date,
              timeSlots: List<String>.from(slot.timeSlots),
            ),
          )
          .toList();

      doctor.refreshAvailability();
      final changed =
          !_sameWeeklyAvailability(previousWeekly, doctor.weeklyAvailability) ||
          !_sameDoctorAvailability(
            previousOverrides,
            doctor.availabilityOverrides,
          ) ||
          !_sameDoctorAvailability(previousAvailability, doctor.availability);

      if (!changed) continue;

      await saveDoctor(doctor);
    }
  }

  bool _sameWeeklyAvailability(
    List<DoctorWeeklyAvailability> first,
    List<DoctorWeeklyAvailability> second,
  ) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      final left = first[index];
      final right = second[index];
      if (left.weekday != right.weekday) return false;
      if (left.timeSlots.length != right.timeSlots.length) return false;

      for (var slotIndex = 0; slotIndex < left.timeSlots.length; slotIndex++) {
        if (left.timeSlots[slotIndex] != right.timeSlots[slotIndex]) {
          return false;
        }
      }
    }

    return true;
  }

  bool _sameDoctorAvailability(
    List<DoctorAvailability> first,
    List<DoctorAvailability> second,
  ) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      final left = first[index];
      final right = second[index];
      if (left.date != right.date) return false;
      if (left.timeSlots.length != right.timeSlots.length) return false;

      for (var slotIndex = 0; slotIndex < left.timeSlots.length; slotIndex++) {
        if (left.timeSlots[slotIndex] != right.timeSlots[slotIndex]) {
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _syncPatientReportsSubcollection(PatientModel patient) async {
    final reportsCollection = _patientReports(patient.username);
    final existingReports = await reportsCollection.get();
    final batch = _firestore.batch();

    for (final doc in existingReports.docs) {
      batch.delete(doc.reference);
    }

    for (var index = 0; index < patient.medicalReports.length; index++) {
      final report = patient.medicalReports[index];
      final docId = 'report_${(index + 1).toString().padLeft(3, '0')}';
      batch.set(reportsCollection.doc(docId), {
        ...report.toMap(),
        'patientUsername': patient.username,
        'reportIndex': index,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _ensureDoctorBucketDocs() async {
    await _approvedDoctorsBucket.set({
      'label': _approvedDoctorsBucketId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _pendingDoctorsBucket.set({
      'label': _pendingDoctorsBucketId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _rejectedDoctorsBucket.set({
      'label': _rejectedDoctorsBucketId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<DoctorModel>> _getDoctorsFromBuckets(
    List<String> bucketIds,
  ) async {
    final doctors = <DoctorModel>[];
    for (final bucketId in bucketIds) {
      final snapshot = await _doctorProfiles(bucketId).get();
      doctors.addAll(
        snapshot.docs.map((doc) => DoctorModel.fromMap(doc.data())),
      );
    }
    return doctors;
  }

  Future<void> _seedDoctorsIfEmpty(List<DoctorModel> doctors) async {
    final existingDoctors = await _getDoctorsFromBuckets(
      _doctorBucketIds.toList(),
    );
    if (existingDoctors.isNotEmpty) return;

    for (final doctor in doctors) {
      await saveDoctor(doctor);
    }
  }

  Future<void> _startWatchingDoctorBuckets({
    required List<String> bucketIds,
    required List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
    subscriptions,
    required Map<String, List<DoctorModel>> snapshotsByBucket,
    required void Function() emitCombined,
  }) async {
    await _ensureDoctorBucketDocs();
    await _migrateLegacyDoctorDocuments();

    for (final bucketId in bucketIds) {
      final subscription = _doctorProfiles(bucketId).snapshots().listen((
        snapshot,
      ) {
        snapshotsByBucket[bucketId] = snapshot.docs
            .map((doc) => DoctorModel.fromMap(doc.data()))
            .toList();
        emitCombined();
      });
      subscriptions.add(subscription);
    }
  }

  Future<void> _upsertDoctorInBuckets(DoctorModel doctor) async {
    final targetBucketId = _doctorBucketIdFor(doctor);
    final batch = _firestore.batch();

    for (final bucketId in _doctorBucketIds) {
      final ref = _doctorProfiles(bucketId).doc(doctor.username);
      if (bucketId == targetBucketId) {
        batch.set(ref, {
          ...doctor.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(ref);
      }
    }

    await batch.commit();
  }

  Future<void> _migrateLegacyDoctorDocuments() async {
    final snapshot = await _doctors.get();
    final legacyDocs = snapshot.docs.where(
      (doc) =>
          !_doctorBucketIds.contains(doc.id) &&
          (doc.data()['username']?.toString().trim().isNotEmpty ?? false),
    );

    for (final doc in legacyDocs) {
      final doctor = DoctorModel.fromMap(doc.data());
      await _upsertDoctorInBuckets(doctor);
      await doc.reference.delete();
    }
  }

  Map<String, dynamic> _patientDocumentMap(PatientModel patient) {
    final data = Map<String, dynamic>.from(patient.toMap());
    data.remove('medicalReports');
    data['updatedAt'] = FieldValue.serverTimestamp();
    return data;
  }

  Future<PatientModel> _hydratePatientReports(PatientModel patient) async {
    final reportsSnapshot = await _patientReports(
      patient.username,
    ).orderBy('reportIndex').get();
    patient.medicalReports = reportsSnapshot.docs
        .map((doc) => MedicalReport.fromMap(doc.data()))
        .toList();
    return patient;
  }

  Future<List<PatientModel>> _hydratePatientsWithReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    print('🔍 Hydrating ${docs.length} patients with medical reports...');
    final patients = docs
        .map((doc) => PatientModel.fromMap(doc.data()))
        .toList();

    int successCount = 0;
    for (final patient in patients) {
      try {
        await _hydratePatientReports(patient);
        successCount++;
      } catch (e) {
        print(
          '⚠️  Failed to hydrate reports for patient ${patient.username}: $e',
        );
      }
    }
    print(
      '✅ Hydration complete: $successCount/${patients.length} patients successfully hydrated',
    );
    return patients;
  }

  Future<void> _syncPatientAppointmentSubcollections(
    AppointmentModel appointment,
  ) async {
    final patientUsername = appointment.patientUsername.trim();
    if (patientUsername.isEmpty) return;

    await _patientPayments(patientUsername).doc(appointment.id).set({
      'appointmentId': appointment.id,
      'patientUsername': appointment.patientUsername,
      'doctorUsername': appointment.doctorUsername,
      'date': appointment.date,
      'time': appointment.time,
      'type': appointment.type,
      'status': appointment.status,
      'paymentStatus': appointment.paymentStatus,
      'paymentMethod': appointment.paymentMethod,
      'paymentReference': appointment.paymentReference,
      'paymentAmount': appointment.paymentAmount,
      'paymentPaidAt': appointment.paymentPaidAt?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _patientFeedback(patientUsername).doc(appointment.id).set({
      'appointmentId': appointment.id,
      'patientUsername': appointment.patientUsername,
      'doctorUsername': appointment.doctorUsername,
      'date': appointment.date,
      'time': appointment.time,
      'type': appointment.type,
      'status': appointment.status,
      'feedbackSubmitted': appointment.feedbackSubmitted,
      'feedbackRating': appointment.feedbackRating,
      'feedbackComments': appointment.feedbackComments,
      'completedAt': appointment.completedAt?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Diagnostic method to check patient data status
  Future<String> diagnosePatientDataStatus() async {
    try {
      if (!firebaseAvailable) {
        return '⚠️ Firebase is unavailable. Using cached data.\n'
            'Cached patients: ${AppState.patients.length}';
      }

      final snapshot = await _patients.get();
      final patientCount = snapshot.docs.length;

      if (patientCount == 0) {
        return '⚠️ No patients found in Firestore.\n'
            'Patients collection exists but is empty.\n'
            'Ensure patient registration is working correctly.';
      }

      // Check if we can load the first patient's data
      if (snapshot.docs.isNotEmpty) {
        final firstPatientDoc = snapshot.docs.first;
        final username = firstPatientDoc.get('username') ?? 'unknown';

        try {
          final reportsSnapshot = await _patientReports(
            username,
          ).limit(1).get();
          return '✅ Patient data is accessible!\n'
              'Total patients: $patientCount\n'
              'Sample patient: $username\n'
              'Medical reports: ${reportsSnapshot.docs.length}';
        } catch (e) {
          return '❌ Error loading medical reports for patient $username:\n$e';
        }
      }

      return '✅ Patient data found: $patientCount patients in Firestore';
    } catch (e) {
      return '❌ Diagnostic error: $e';
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
