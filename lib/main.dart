import 'package:flutter/material.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/unified_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _bootstrapCompleted = false;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    await bootstrapFirebase();
    if (!mounted) return;
    setState(() {
      _bootstrapCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const UnifiedLoginScreen(),
        if (!_bootstrapCompleted)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
