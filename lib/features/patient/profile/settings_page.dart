import 'package:flutter/material.dart';
import '../../../core/theme/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool appointmentAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tileSwitch(
            title: "Dark Mode",
            value: AppState.isDark,
            onChanged: (v) {
              AppState.setDark(v);
              setState(() {});
            },
          ),
          _tileSwitch(
            title: "Appointment Alerts",
            value: appointmentAlerts,
            onChanged: (v) => setState(() => appointmentAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _tileSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
