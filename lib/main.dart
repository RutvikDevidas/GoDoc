import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // ✅ IMPORTANT

import 'core/theme/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Cross-platform Firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const GoDocApp());
}

class GoDocApp extends StatelessWidget {
  const GoDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GoDoc',
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AuthGate(),
        );
      },
    );
  }
}
