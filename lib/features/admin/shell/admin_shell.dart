import 'package:flutter/material.dart';

import '../home/admin_home_page.dart';
import '../doctors/verify_doctors_page.dart';
import '../users/admin_users_page.dart';
import '../insights/reports_feedback_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  final pages = const <Widget>[
    AdminHomePage(),
    VerifyDoctorsPage(),
    AdminUsersPage(),
    ReportsFeedbackPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1E5BFF),
            unselectedItemColor: Colors.black.withOpacity(0.55),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.verified_user_rounded),
                label: "Verify",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: "Users",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_rounded),
                label: "Insights",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
