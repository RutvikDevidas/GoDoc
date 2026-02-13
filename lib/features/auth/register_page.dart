import 'package:flutter/material.dart';

import '../../core/utils/ids.dart';
import '../../shared/models/doctor.dart';
import '../../shared/models/user_role.dart';
import '../../shared/stores/auth_store.dart';
import '../../shared/stores/doctor_registry_store.dart';
import '../../shared/stores/notification_store.dart';
import 'auth_gate.dart';

class RegisterPage extends StatefulWidget {
  final UserRole initialRole;
  const RegisterPage({super.key, this.initialRole = UserRole.patient});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  late UserRole role;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = role == UserRole.patient;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCCF4D2), Color(0xFFB9F0C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  const Text(
                    "GoDoc",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isPatient ? "Patient Register" : "Doctor Register",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
              const SizedBox(height: 16),

              _roleToggle(),

              const SizedBox(height: 16),

              _card(
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password (min 4 chars)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        child: const Text("Create Account"),
                      ),
                    ),
                    if (role == UserRole.doctor) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Note: Doctor profile will be visible to patients only after Admin verification.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.65)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleToggle() {
    final isPatient = role == UserRole.patient;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => role = UserRole.patient),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPatient
                      ? const Color(0xFF2BB673)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Patient",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isPatient ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => role = UserRole.doctor),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isPatient
                      ? const Color(0xFF2BB673)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Doctor",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: !isPatient ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  void _register() {
    // Admin cannot register here
    if (role == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin cannot register here.")),
      );
      return;
    }

    final ok = AuthStore.register(
      name: nameCtrl.text,
      email: emailCtrl.text,
      password: passCtrl.text,
      role: role,
    );

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid details")),
      );
      return;
    }

    // ✅ If doctor registers: add to registry as PENDING + notify admin
    if (role == UserRole.doctor) {
      final pendingDoctor = Doctor(
        id: "d_${Ids.now()}",
        name: nameCtrl.text.trim(),
        title: "Doctor",
        specializationId:
            "cardio", // default; admin can verify then patient can see
        rating: 0,
        reviews: 0,
        imageUrl:
            "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=800",
        hospital: "Pending Verification",
        about: "Doctor profile is pending verification by Admin.",
        address: "—",
      );

      DoctorRegistryStore.addPendingDoctor(pendingDoctor);

      NotificationStore.add(
        "Doctor Registration Pending 🕒",
        "New doctor registered: ${pendingDoctor.name}. Verify from Admin panel.",
      );

      // (Optional) Also tell doctor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registered ✅ Waiting for Admin verification."),
        ),
      );
    } else {
      NotificationStore.add("Account Created ✅", "Welcome Patient!");
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
