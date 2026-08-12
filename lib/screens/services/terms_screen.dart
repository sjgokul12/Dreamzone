import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFF1A237E))), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Color(0xFF1A237E))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Terms & Conditions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        SizedBox(height: 20),
        Text('Last Updated: May 2026', style: TextStyle(color: Colors.grey)),
        SizedBox(height: 16),
        _Section(title: '1. Acceptance of Terms', content: 'By accessing and using DZI Infinity services, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our services.'),
        _Section(title: '2. Services Description', content: 'DZI Infinity provides digital services including PAN card applications, GST registration, ITR filing, Aadhaar services, banking, payments, travel booking, insurance, and e-governance services through our authorized partners.'),
        _Section(title: '3. User Responsibilities', content: 'You must provide accurate information. You are responsible for maintaining confidentiality of your account. You must be 18 years or older to use our services.'),
        _Section(title: '4. Payment Terms', content: 'All fees are displayed before submission. Payments are processed securely. Refund policies vary by service type.'),
        _Section(title: '5. Privacy', content: 'Your data is protected under our Privacy Policy. We do not share personal information without consent.'),
        _Section(title: '6. Limitation of Liability', content: 'DZI Infinity acts as a facilitator. We are not liable for delays caused by government agencies or third parties.'),
        _Section(title: '7. Contact', content: 'Email: dreamzone.infinity@gmail.com\nPhone: +91 9986074786'),
      ])),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
      ]),
    );
  }
}