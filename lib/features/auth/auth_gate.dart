import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../doctor/shell/doctor_shell.dart';
import '../patient/shell/patient_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Not logged in
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.data!.exists) {
              return const LoginPage();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;

            final role = data['role'];

            if (role == 'doctor') {
              return const DoctorShell();
            } else if (role == 'patient') {
              return const PatientShell();
            } else {
              return const LoginPage();
            }
          },
        );
      },
    );
  }
}
