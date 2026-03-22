import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

    // Seed local app state into Firestore (if empty) and keep app state in sync.
    await FirestoreDataService.instance.seedAndSync();
    debugPrint(
      'Firebase initialized successfully on ${DefaultFirebaseOptions.currentPlatformName}.',
    );
  } catch (error) {
    firebaseAvailable = false;
    firebaseUnavailableReason = error.toString();
    debugPrint('Firebase initialization failed: $firebaseUnavailableReason');
  }
}
