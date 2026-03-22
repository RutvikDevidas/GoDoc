// PARTIALLY CONFIGURED FILE
//
// Android values below were aligned with `android/app/google-services.json`.
// Other platforms may still point at a different Firebase project until
// `flutterfire configure` is run again with the intended app registrations.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Replace the values below with your Firebase project values (from the
/// Firebase console). The easiest way to do that is to run:
///   flutterfire configure
/// and allow it to generate this file for you.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return fuchsia;
    }
  }

  static String get currentPlatformName {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static bool get isCurrentPlatformConfigured =>
      !hasPlaceholderValues(currentPlatform);

  static bool hasPlaceholderValues(FirebaseOptions options) {
    return (options.apiKey).startsWith('YOUR_') ||
        (options.appId).startsWith('YOUR_') ||
        (options.messagingSenderId).startsWith('YOUR_') ||
        (options.projectId).startsWith('YOUR_') ||
        (options.storageBucket ?? '').startsWith('YOUR_') ||
        (kIsWeb && (options.authDomain ?? '').startsWith('YOUR_')) ||
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS) &&
            (options.iosBundleId ?? '').startsWith('YOUR_'));
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7d3gRu3nP7k3k2iSqbT7fy9ZHBkpkRN8',
    appId: '1:298580599577:web:fc315e25ac7124fc1d1b88',
    messagingSenderId: '298580599577',
    projectId: 'godoc-4d7a8',
    authDomain: 'godoc-4d7a8.firebaseapp.com',
    storageBucket: 'godoc-4d7a8.firebasestorage.app',
    measurementId: 'G-KWX327CLDZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFfnc5VXosHvY3tp3pBgXxdndP9s6hGak',
    appId: '1:206537940834:android:97a66bc52f88dc11d5d63b',
    messagingSenderId: '206537940834',
    projectId: 'project-c19ca',
    storageBucket: 'project-c19ca.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCI7eL6Cx69UerTrt_EyFqxTpL5sMe1PFY',
    appId: '1:298580599577:ios:adb5eeae40da36a41d1b88',
    messagingSenderId: '298580599577',
    projectId: 'godoc-4d7a8',
    storageBucket: 'godoc-4d7a8.firebasestorage.app',
    iosBundleId: 'com.example.godoc',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7d3gRu3nP7k3k2iSqbT7fy9ZHBkpkRN8',
    appId: '1:298580599577:web:8d6c6f6db0210c1e1d1b88',
    messagingSenderId: '298580599577',
    projectId: 'godoc-4d7a8',
    authDomain: 'godoc-4d7a8.firebaseapp.com',
    storageBucket: 'godoc-4d7a8.firebasestorage.app',
    measurementId: 'G-CPRDYHSE89',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions fuchsia = FirebaseOptions(
    apiKey: 'YOUR_FUCHSIA_API_KEY',
    appId: 'YOUR_FUCHSIA_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
