import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF1A237E))), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Color(0xFF1A237E))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        SizedBox(height: 20),
        Text('Last Updated: May 2026', style: TextStyle(color: Colors.grey)),
        SizedBox(height: 16),
        _Section(title: '1. Information We Collect', content: 'We collect name, mobile number, email address, Aadhaar, PAN, address, and documents required for service processing. This information is necessary to process your applications.'),
        _Section(title: '2. How We Use Information', content: 'Information is used solely for processing your service requests with government agencies and partners. We do not sell or rent your personal data.'),
        _Section(title: '3. Data Storage', content: 'Data is stored on secure servers with encryption. Documents are stored securely and accessible only to authorized personnel.'),
        _Section(title: '4. Data Sharing', content: 'We share necessary information with government portals (NSDL, GSTN, UIDAI etc.) as required for service processing.'),
        _Section(title: '5. Your Rights', content: 'You can request access, correction, or deletion of your data by contacting us. We will respond within 7 working days.'),
        _Section(title: '6. Security', content: 'We use SSL encryption, secure servers, and regular security audits to protect your data.'),
        _Section(title: '7. Cookies', content: 'We use essential cookies for app functionality. No tracking cookies are used.'),
        _Section(title: '8. Contact', content: 'Email: dreamzone.infinity@gmail.com\nPhone: +91 9880885551\nAddress: NO-79, 5TH CROSS, RAMESHNAGAR, Bengaluru, Karnataka 560037'),
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