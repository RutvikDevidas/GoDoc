import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'firestore_data_service.dart';
import 'firebase_state.dart';
import '../../firebase_options.dart';

Future<void> bootstrapFirebase() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!DefaultFirebaseOptions.isCurrentPlatformConfigured) {
      firebaseAvailable = false;
      firebaseUnavailableReason =
          'Firebase is not configured for ${DefaultFirebaseOptions.currentPlatformName}. '
          'Update lib/firebase_options.dart with FlutterFire.';
      debugPrint('Firebase skipped: $firebaseUnavailableReason');
      return;
    }

    await Firebase.initializeApp(options: options);
    firebaseAvailable = true;
    firebaseUnavailableReason = null;
    debugPrint(
      'Firebase initialized successfully on ${DefaultFirebaseOptions.currentPlatformName}.',
    );

    if (kIsWeb) {
      // Firestore requests on localhost can hang with WebChannel on some
      // networks or browser setups. Long-polling is more reliable here.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        webExperimentalForceLongPolling: true,
        webExperimentalAutoDetectLongPolling: false,
      );
    }

    try {
      // Avoid blocking startup if the first Firestore sync is slow.
      await FirestoreDataService.instance
          .seedAndSync()
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      firebaseUnavailableReason = 'Initial Firestore sync skipped: $error';
      debugPrint('Firestore sync failed: $error');
    }
  } catch (error) {
    firebaseAvailable = false;
    firebaseUnavailableReason = 'Firebase initialization failed: $error';
    debugPrint('Firebase initialization failed: $firebaseUnavailableReason');
  }
}
