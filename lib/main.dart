import 'dart:async';

import 'package:flutter/material.dart';

import 'core/data/app_state.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firestore_data_service.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'modules/admin/admin_dashboard.dart';
import 'modules/auth/unified_login_screen.dart';
import 'modules/doctor/doctor_dashboard.dart';
import 'modules/patient/patient_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const GoDocApp());
}

class GoDocApp extends StatelessWidget {
  const GoDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  late final Future<Widget> _initialScreenFuture = _resolveInitialScreen();

  Future<Widget> _resolveInitialScreen() async {
    final session = await SessionManager.loadSession();
    if (session == null) {
      return const UnifiedLoginScreen();
    }

    try {
      await FirestoreDataService.instance.syncAllToAppState();
    } catch (_) {}

    switch (session.role) {
      case AppSessionRole.admin:
        return const AdminDashboard();
      case AppSessionRole.doctor:
        final doctor = AppState.doctors
            .where((item) => item.username == session.username)
            .firstOrNull;
        if (doctor != null && doctor.verified) {
          return DoctorDashboard(doctor: doctor);
        }
        break;
      case AppSessionRole.patient:
        final patient = AppState.patients
            .where((item) => item.username == session.username)
            .firstOrNull;
        if (patient != null) {
          return PatientHomeScreen(patient: patient);
        }
        break;
    }

    await SessionManager.clearSession();
    return const UnifiedLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data ?? const UnifiedLoginScreen();
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
