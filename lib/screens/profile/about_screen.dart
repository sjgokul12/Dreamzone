import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Premium Project Teal Palette
  static const Color primaryTeal = Color(0xFF00A896);
  static const Color secondaryTeal = Color(0xFF0284C7);
  static const Color headerGradientStart = Color(0xFF0F766E);
  static const Color headerGradientEnd = Color(0xFF0284C7);
  static const Color textDarkHeading = Color(0xFF0F172A);
  static const Color textSubdued = Color(0xFF64748B);
  static const Color bgCanvas = Color(0xFFF1F5F9);
  static const Color cardSurface = Colors.white;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 800 ? (screenSize.width - 680) / 2 : 16.0;

    return Scaffold(
      backgroundColor: bgCanvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Curved Hero Container
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: 26,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerGradientStart, headerGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: primaryTeal,
                          child: const Icon(Icons.assured_workload_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'DZI Infinity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'All Digital Services in One Trusted App',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                  child: Column(
                    children: [
                      // Highlights Bar (Stats)
                      _buildStatsRow(),

                      const SizedBox(height: 20),

                      // About Company Card
                      _buildAboutSection(),

                      const SizedBox(height: 20),

                      // Services Grid Card
                      _buildServicesSection(),

                      const SizedBox(height: 20),

                      // Contact Us Card
                      _buildContactSection(),

                      const SizedBox(height: 20),

                      // Legal Policies Card
                      _buildLegalSection(),

                      const SizedBox(height: 28),

                      // Footer
                      _buildFooter(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'val': '50+', 'label': 'Digital Services'},
      {'val': '100%', 'label': 'Secure Payments'},
      {'val': '24/7', 'label': 'Customer Care'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((st) {
          return Column(
            children: [
              Text(
                st['val']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                st['label']!,
                style: const TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.business_outlined, 'About DreamZone India'),
          const SizedBox(height: 12),
          const Text(
            'DZI Infinity is a comprehensive digital services platform under DreamZoneIndia, '
            'providing a wide range of essential services including PAN card applications, '
            'GST registration, ITR filing, Passport services, Voter ID, Fastag purchase, FSSAI, MSME, '
            'banking, bill payments, and e-governance solutions across India.',
            style: TextStyle(
              color: textSubdued,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryTeal.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryTeal.withAlpha(35)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: primaryTeal, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Our mission is to empower every Indian citizen and business with fast, transparent, and hassle-free online documentation.',
                    style: TextStyle(
                      color: primaryTeal,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      {'icon': Icons.badge_outlined, 'title': 'PAN & Aadhaar'},
      {'icon': Icons.receipt_long_outlined, 'title': 'GST & MSME'},
      {'icon': Icons.assignment_ind_outlined, 'title': 'Passport Services'},
      {'icon': Icons.restaurant_outlined, 'title': 'FSSAI License'},
      {'icon': Icons.directions_car_outlined, 'title': 'Fastag Purchase'},
      {'icon': Icons.how_to_vote_outlined, 'title': 'Voter ID & PCC'},
      {'icon': Icons.phone_android_rounded, 'title': 'Recharge & BBPS'},
      {'icon': Icons.account_balance_rounded, 'title': 'Municipal Taxes'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.apps_rounded, 'Key Services Supported'),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(s['icon'] as IconData, color: primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s['title'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textDarkHeading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.headset_mic_outlined, 'Contact Support'),
          const SizedBox(height: 14),
          _contactTile(Icons.location_on_outlined, 'Head Office', 'NO-79, 5TH CROSS, RAMESHNAGAR, OPP POST OFFICE, Bengaluru Urban, Karnataka 560037'),
          const SizedBox(height: 8),
          _contactTile(Icons.phone_outlined, 'Helpline', '+91 9880885551'),
          const SizedBox(height: 8),
          _contactTile(Icons.email_outlined, 'Email Support', 'dreamzone.infinity@gmail.com'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:+919880885551'),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call Helpline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl('mailto:dreamzone.infinity@gmail.com'),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Email Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactTile(IconData icon, String title, String val) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSubdued)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textDarkHeading)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.gavel_outlined, 'Legal & Policy Information'),
          const SizedBox(height: 8),
          _legalTile(
            Icons.description_outlined,
            'Terms & Conditions',
            'Read service usage agreement',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _LegalPage(
                  title: 'Terms & Conditions',
                  content: _termsContent,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _legalTile(
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            'How we protect & handle user data',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _LegalPage(
                  title: 'Privacy Policy',
                  content: _privacyContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTeal.withAlpha(16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryTeal, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textDarkHeading),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: textSubdued)),
      trailing: const Icon(Icons.chevron_right, color: primaryTeal, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primaryTeal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: primaryTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textDarkHeading,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'DZI Infinity • DreamZone India Services',
          style: TextStyle(color: textDarkHeading, fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(
          '© 2026 DreamZoneIndia. All rights reserved.',
          style: TextStyle(color: textSubdued, fontSize: 11),
        ),
      ],
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String content;

  const _LegalPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF0F766E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 13.5, height: 1.7, color: Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}

const String _termsContent = '''
Terms & Conditions

Last Updated: June 2026

1. Acceptance of Terms
By accessing and using DZI Infinity services, you agree to be bound by these Terms & Conditions.

2. Services Description
DZI Infinity provides digital documentation and e-governance services including PAN card applications, GST registration, Passport services, Voter ID, Fastag, MSME, and bill payments.

3. User Responsibilities
• You must provide accurate and complete information
• You must be 18 years or older to use our services

4. Payment Terms
• All service charges and government fees are displayed prior to submission
• Payments are processed securely via encrypted gateways

5. Governing Law
• Governed by the laws of India under jurisdiction of Bengaluru courts.
''';

const String _privacyContent = '''
Privacy Policy

Last Updated: June 2026

1. Information We Collect
We collect identity information and documents strictly necessary to process official government application forms on your behalf.

2. Data Protection & Storage
• All documents are encrypted with 256-bit SSL protocols
• Data is strictly handled in accordance with IT Act regulations

3. Contact
Email: dreamzone.infinity@gmail.com | Phone: +91 9880885551
''';