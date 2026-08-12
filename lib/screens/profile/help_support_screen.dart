import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<dynamic> _faqs = [];
  List<dynamic> _categories = [];
  List<dynamic> _myTickets = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _priority = 'medium';
  bool _submitting = false;

  // Premium Project Purple Palette
  static const Color primaryOrange = Color(0xFF8B5CF6);
  static const Color warmBrown = Color(0xFF9333EA);
  Color get bgCream => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF4FBF7);
  Color get cardWhite => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get textDark => Provider.of<AuthProvider>(context).isDarkMode ? Colors.white : const Color(0xFF1A0D08);
  Color get textMedium => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[300]! : const Color(0xFF5D4037);
  Color get textLight => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[400]! : const Color(0xFF8D6E63);
  static const Color accentGold = Color(0xFFFF6B00);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color dangerRed = Color(0xFFE74C3C);
  Color get softOrange => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0F2F1);
  static const Color infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await Future.wait([_loadFaqs(), _loadCategories(), _loadMyTickets()]);
    } catch (e) {
      debugPrint('Error loading support data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFaqs() async {
    try {
      final data = await _api.getFaqs();
      if (data['success'] == true && mounted) {
        setState(() => _faqs = data['faqs'] ?? []);
      }
    } catch (e) {
      debugPrint('loadFaqs error: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.getFaqCategories();
      if (data['success'] == true && mounted) {
        setState(() => _categories = data['categories'] ?? []);
      }
    } catch (e) {
      debugPrint('loadCategories error: $e');
    }
  }

  Future<void> _loadMyTickets() async {
    try {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isLoggedIn || auth.userId == null) return;
      final data = await _api.getUserTickets(auth.userId!);
      if (data['success'] == true && mounted) {
        setState(() => _myTickets = data['tickets'] ?? []);
      }
    } catch (e) {
      debugPrint('loadMyTickets error: $e');
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to submit a ticket'),
          backgroundColor: accentGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await _api.submitTicket(
        auth.userId!,
        _subjectCtrl.text.trim(),
        _messageCtrl.text.trim(),
        priority: _priority,
      );

      if (mounted) {
        setState(() => _submitting = false);
        if (data['success'] == true) {
          _subjectCtrl.clear();
          _messageCtrl.clear();
          await _loadMyTickets();
          _tabController.animateTo(2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket submitted successfully!'),
              backgroundColor: successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Submission failed'),
              backgroundColor: dangerRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed. Check server.'),
            backgroundColor: dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Color _ticketStatusColor(String? s) {
    switch (s) {
      case 'open':
        return accentGold;
      case 'in_progress':
        return infoBlue;
      case 'resolved':
        return successGreen;
      case 'closed':
        return textLight;
      default:
        return textLight;
    }
  }

  String _ticketStatusLabel(String? s) {
    switch (s) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return s ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFaqsTab(),
                    _buildSubmitTicketTab(),
                    _buildMyTicketsTab(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: cardWhite,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Text(
        'Help & Support',
        style: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.3,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: softOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: primaryOrange,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: primaryOrange.withAlpha(25)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryOrange, warmBrown],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: textLight,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'FAQs'),
              Tab(text: 'Submit Ticket'),
              Tab(text: 'My Tickets'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: primaryOrange,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading support...',
                  style: TextStyle(
                    color: textMedium,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _build247CustomerSupportBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '24/7 Customer Support',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'We are always available to assist you',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickSupportButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call Us',
                  color: const Color(0xFF10B981),
                  onTap: () async {
                    final uri = Uri.parse('tel:18001234567');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _quickSupportButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/919876543210');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _quickSupportButton(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: const Color(0xFF3B82F6),
                  onTap: () async {
                    final uri = Uri.parse('mailto:support@dziinfinity.com');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _quickSupportButton(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Ticket',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickSupportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(50), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _effectiveFaqs {
    if (_faqs.isNotEmpty) return _faqs;
    return [
      {
        'category_name': 'General & Account',
        'question': 'How can I contact 24/7 Customer Support?',
        'answer': 'You can reach us 24/7 via Call (1800-123-4567), WhatsApp chat, Email (support@dziinfinity.com), or by creating a support ticket in this app.',
      },
      {
        'category_name': 'General & Account',
        'question': 'What are your support working hours?',
        'answer': 'Our customer support team is active 24/7, 365 days a year to resolve your queries and service requests instantly.',
      },
      {
        'category_name': 'Services & Payments',
        'question': 'How do I check my application or ticket status?',
        'answer': 'You can track all your submitted service applications under "My Applications" and all support tickets under the "My Tickets" tab in this screen.',
      },
      {
        'category_name': 'Services & Payments',
        'question': 'What should I do if a payment fails?',
        'answer': 'If money is deducted during a failed transaction, it will be automatically refunded within 24-48 hours. You can also raise a ticket directly under "Submit Ticket".',
      },
    ];
  }

  // ==================== FAQs TAB ====================

  Widget _buildFaqsTab() {
    final Map<String, List<dynamic>> grouped = {};
    for (final faq in _effectiveFaqs) {
      final cat = (faq['category_name'] ?? 'General').toString();
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(faq);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _build247CustomerSupportBanner(),
        ...grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: softOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryOrange.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: primaryOrange,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryOrange.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value.length} articles',
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.asMap().entries.map((faqEntry) {
              final index = faqEntry.key;
              final faq = faqEntry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: primaryOrange.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.question_answer_outlined,
                              color: primaryOrange,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            faq['question'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textDark,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 1,
                                    color: Colors.grey[100],
                                    margin: const EdgeInsets.only(bottom: 12),
                                  ),
                                  Text(
                                    faq['answer'] ?? '',
                                    style: TextStyle(
                                      color: textMedium,
                                      fontSize: 13,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            SizedBox(height: 16),
          ],
        );
      }),
    ],
  );
}

  // ==================== SUBMIT TICKET TAB ====================

  Widget _buildSubmitTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: primaryOrange.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.support_agent,
                                  color: primaryOrange,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Support Ticket',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'We will get back to you shortly',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8D6E63),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Subject Field
                          TextFormField(
                            controller: _subjectCtrl,
                            style: TextStyle(color: textDark),
                            decoration: InputDecoration(
                              labelText: 'Subject *',
                              labelStyle: TextStyle(
                                color: textLight,
                                fontSize: 13,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryOrange.withAlpha(12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.subject,
                                  color: primaryOrange,
                                  size: 18,
                                ),
                              ),
                              filled: true,
                              fillColor: bgCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primaryOrange,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Subject is required'
                                : null,
                          ),
                          SizedBox(height: 14),

                          // Message Field
                          TextFormField(
                            controller: _messageCtrl,
                            maxLines: 5,
                            style: TextStyle(color: textDark),
                            decoration: InputDecoration(
                              labelText: 'Describe your issue *',
                              labelStyle: TextStyle(
                                color: textLight,
                                fontSize: 13,
                              ),
                              alignLabelWithHint: true,
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(left: 8, top: 8),
                                decoration: BoxDecoration(
                                  color: primaryOrange.withAlpha(12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.message_outlined,
                                  color: primaryOrange,
                                  size: 18,
                                ),
                              ),
                              filled: true,
                              fillColor: bgCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primaryOrange,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Message is required'
                                : null,
                          ),
                          SizedBox(height: 14),

                          // Priority Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            style: TextStyle(
                              color: textDark,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              labelStyle: TextStyle(
                                color: textLight,
                                fontSize: 13,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryOrange.withAlpha(12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.flag_outlined,
                                  color: primaryOrange,
                                  size: 18,
                                ),
                              ),
                              filled: true,
                              fillColor: bgCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primaryOrange,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low - General inquiry'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium - Need assistance'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High - Urgent issue'),
                              ),
                              DropdownMenuItem(
                                value: 'urgent',
                                child: Text('Urgent - Critical problem'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _priority = v ?? 'medium'),
                          ),
                          SizedBox(height: 24),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryOrange, warmBrown],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryOrange.withAlpha(90),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submitTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _submitting
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Submit Ticket',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MY TICKETS TAB ====================

  Widget _buildMyTicketsTab() {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: softOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 44,
                      color: primaryOrange,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Login Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign in to view your support tickets',
                    style: TextStyle(color: textMedium, fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, b) =>
                              const HomeScreen(isGuest: true),
                          transitionsBuilder: (_, animation, _, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go to Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (_myTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgCream,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No tickets submitted',
              style: TextStyle(color: textLight, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Use the Submit Ticket tab to raise one',
              style: TextStyle(color: textLight, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: cardWhite,
      onRefresh: _loadMyTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTickets.length,
        itemBuilder: (context, index) {
          final t = _myTickets[index];
          final statusColor = _ticketStatusColor(t['status']?.toString());
          final createdAt = (t['created_at'] ?? '').toString();
          final dateStr = createdAt.length >= 10
              ? createdAt.substring(0, 10)
              : createdAt;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 60)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.support_agent,
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        t['subject'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textDark,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _ticketStatusLabel(t['status']?.toString()),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: textLight,
                          ),
                          SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 10, color: textLight),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 1,
                                color: Colors.grey[100],
                                margin: const EdgeInsets.only(bottom: 12),
                              ),
                              Text(
                                'Your Message:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgCream,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMedium,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              if (t['admin_reply'] != null) ...[
                                SizedBox(height: 14),
                                Text(
                                  'Admin Reply:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: successGreen,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: successGreen.withAlpha(10),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: successGreen.withAlpha(30),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: successGreen,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          t['admin_reply'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textDark,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            },
          );
        },
      ),
    );
  }
}
