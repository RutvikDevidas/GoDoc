import 'dart:async';

import 'package:flutter/material.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/unified_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoDocApp());
  unawaited(bootstrapFirebase());
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
  @override
  Widget build(BuildContext context) {
    return const UnifiedLoginScreen();
  }
}
