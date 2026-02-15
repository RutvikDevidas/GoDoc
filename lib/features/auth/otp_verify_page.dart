import 'package:flutter/material.dart';
import '../../shared/stores/notification_store.dart';
import 'auth_gate.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phone;
  final String otp;

  const OtpVerifyPage({super.key, required this.phone, required this.otp});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final otpCtrl = TextEditingController();

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "OTP sent to ${widget.phone}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verify,
                child: const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verify() {
    if (otpCtrl.text.trim() != widget.otp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      return;
    }

    NotificationStore.add("Phone Verified ✅", "OTP verification successful.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
