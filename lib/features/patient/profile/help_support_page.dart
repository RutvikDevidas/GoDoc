import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            "FAQs",
            "Find answers about booking, payment, and rescheduling.",
          ),
          const SizedBox(height: 12),
          _card(
            context,
            "Contact Support",
            "Email: support@godoc.com\nPhone: +91 90000 00000",
          ),
          const SizedBox(height: 12),
          _card(
            context,
            "Report a Problem",
            "Tell us what happened and we will help you quickly.",
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}
