import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';
import 'package:dreamzoneapp/core/payment/razorpay_service.dart';
import 'package:dreamzoneapp/screens/home/home_screen.dart';

// Premium Palette Theme Constants (Shared Globally in this file)
const Color primaryPurple      = Color(0xFF5F33E1);
const Color secondaryPurple    = Color(0xFF7C3AED);
const Color textDarkHeading    = Color(0xFF1E1B4B);
const Color textLabelDark      = Color(0xFF312E81);
const Color textSubdued        = Color(0xFF6B7280);
const Color bgCanvas           = Color(0xFFF5F3FF);
const Color cardSurface        = Colors.white;

class AadhaarServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const AadhaarServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<AadhaarServiceScreen> createState() => _AadhaarServiceScreenState();
}

class _AadhaarServiceScreenState extends State<AadhaarServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Selected Section ID: 401 = Aadhaar Card - Soft Copy, 402 = Aadhaar Card - Hard Copy
  late int _selectedSectionId;
  int _selectedCategoryTab = 1; // Default to Hard Copy Tab

  // Personal Info Controllers
  final TextEditingController _aadhaarNoCtrl = TextEditingController();
  final TextEditingController _phoneNoCtrl   = TextEditingController();

  // Address For Communication Controllers
  String _commAddressType = 'Address Per Application';
  final TextEditingController _commHouseNoCtrl  = TextEditingController();
  final TextEditingController _commStreetCtrl   = TextEditingController();
  final TextEditingController _commTehsilCtrl   = TextEditingController();
  final TextEditingController _commPincodeCtrl  = TextEditingController();
  final TextEditingController _commDistrictCtrl = TextEditingController();
  final TextEditingController _commStateCtrl    = TextEditingController();
  final TextEditingController _commCityCtrl     = TextEditingController();

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _expandedSectionIndex = 0; // Tracks currently active step index

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.preselectedSectionId ?? 402;
    _selectedCategoryTab = _selectedSectionId == 401 ? 0 : 1;

    _razorpayService.init();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _loadSavedUserData();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _aadhaarNoCtrl.dispose();
    _phoneNoCtrl.dispose();
    _commHouseNoCtrl.dispose();
    _commStreetCtrl.dispose();
    _commTehsilCtrl.dispose();
    _commPincodeCtrl.dispose();
    _commDistrictCtrl.dispose();
    _commStateCtrl.dispose();
    _commCityCtrl.dispose();
    super.dispose();
  }

  void _setCommAddressMode(String mode) {
    setState(() {
      _commAddressType = mode;
      if (mode == 'Business Partner Address') {
        _commHouseNoCtrl.text  = '#702';
        _commStreetCtrl.text   = 'KORMANAGALA';
        _commTehsilCtrl.text   = 'NETHAJI CIRCLE';
        _commPincodeCtrl.text  = '560054';
        _commDistrictCtrl.text = 'SOUTH BANGALORE';
        _commStateCtrl.text    = 'KARNATAKA';
        _commCityCtrl.text     = 'BANGALORE';
      } else {
        _commHouseNoCtrl.clear();
        _commStreetCtrl.clear();
        _commTehsilCtrl.clear();
        _commPincodeCtrl.clear();
        _commDistrictCtrl.clear();
        _commStateCtrl.clear();
        _commCityCtrl.clear();
      }
    });
  }

  Future<void> _loadSavedUserData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) return;
    try {
      final res = await _api.getUserSavedDetails(auth.userId!);
      if (res['success'] == true && res['details'] != null && mounted) {
        setState(() {
          _savedDetails = res['details'];
          if (_phoneNoCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _phoneNoCtrl.text = _savedDetails!['mobile'];
          }
          if (_aadhaarNoCtrl.text.isEmpty && _savedDetails!['aadhaar_number'] != null) {
            _aadhaarNoCtrl.text = _savedDetails!['aadhaar_number'];
          }
        });
      }
    } catch (_) {}
  }

  double get _payableAmount => _selectedSectionId == 401 ? 1.00 : 60.00;

  String get _currentAadhaarTypeName => _selectedSectionId == 401 ? 'Aadhaar Card - Soft Copy' : 'Aadhaar Card - Hard Copy';

  /// Opens Razorpay payment sheet. On success, calls [_doSubmitAadhaarForm].
  Future<void> _submitAadhaarForm() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _expandedSectionIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Please fill all required fields correctly'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    // Open Razorpay – backend call happens only on payment success
    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: _currentAadhaarTypeName,
      name: 'DZI Infinity',
      contact: _phoneNoCtrl.text.trim(),
      email: '',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitAadhaarForm(razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  /// Actual backend submission – called after successful Razorpay payment.
  Future<void> _doSubmitAadhaarForm({required String razorpayPaymentId}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _loading = true);

    Map<String, String> formData = {
      'aadhaar_type':         _currentAadhaarTypeName,
      'aadhaar_number':       _aadhaarNoCtrl.text.trim(),
      'phone_number':         _phoneNoCtrl.text.trim(),
      'comm_address_type':    _commAddressType,
      'comm_house_no':        _commHouseNoCtrl.text.trim(),
      'comm_street':          _commStreetCtrl.text.trim(),
      'comm_tehsil':          _commTehsilCtrl.text.trim(),
      'comm_pincode':         _commPincodeCtrl.text.trim(),
      'comm_district':        _commDistrictCtrl.text.trim(),
      'comm_state':           _commStateCtrl.text.trim(),
      'comm_city':            _commCityCtrl.text.trim(),
      'amount':               _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':  razorpayPaymentId,
      'payment_status':       'paid',
    };

    String finalTrackingId = 'TRK-ADH-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/aadhaar/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': auth.userId,
          'service_id': widget.service['id'] ?? 400,
          'form_id': _selectedSectionId,
          'form_data': jsonEncode(formData),
          ...formData,
        }),
      ).timeout(const Duration(seconds: 35));

      final data = jsonDecode(res.body);
      if (data is Map && data['tracking_id'] != null) {
        finalTrackingId = data['tracking_id'].toString();
      }
    } catch (_) {}

    // Save to local applications registry for instant & reliable order tracking
    if (auth.userId != null) {
      await _api.saveSubmittedApplication({
        'application_no': finalTrackingId,
        'tracking_id': finalTrackingId,
        'service_name': _currentAadhaarTypeName,
        'app_type': 'service',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': auth.userId,
        'amount': _payableAmount.toStringAsFixed(2),
        'payment_status': 'paid',
        'details': formData,
      });
    }

    if (mounted) {
      setState(() {
        _loading    = false;
        _submitted  = true;
        _trackingId = finalTrackingId;
      });
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LoginModal(
        onSuccess: () {
          Navigator.pop(ctx);
          _submitAadhaarForm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop  = screenSize.width > 900;

    return Scaffold(
      backgroundColor: bgCanvas,
      body: _submitted ? _buildSuccessView() : _buildFormBody(isDesktop, screenSize),
    );
  }

  Widget _buildTopNavBar() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: primaryPurple, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.teal, size: 16),
                SizedBox(width: 6),
                Text(
                  'Secure & Trusted',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth / 1.6;
        return Container(
          width: double.infinity,
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/Aadhar card.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F0FF),
                  child: const Center(
                    child: Icon(Icons.badge_outlined, size: 70, color: primaryPurple),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _buildCategoryTabCard(
                index: 0,
                title: 'Soft Copy',
                subtitle: 'Get digital Aadhaar card PDF',
                icon: Icons.description_outlined,
                width: cardWidth,
              ),
              const SizedBox(width: 10),
              _buildCategoryTabCard(
                index: 1,
                title: 'Hard Copy',
                subtitle: 'Get physical Aadhaar card printed',
                icon: Icons.credit_card_outlined,
                width: cardWidth,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required double width,
  }) {
    final isSelected = _selectedCategoryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategoryTab = index;
            _selectedSectionId = index == 0 ? 401 : 402;
            _expandedSectionIndex = 0; // Reset stepper expansion
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryPurple : textSubdued,
                  size: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryPurple : textDarkHeading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  color: textSubdued,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 920) / 2
        : (screenSize.width > 700 ? 24.0 : 16.0);

    // Dynamic sticky bottom button labels
    String buttonTitle = "Next: Address Info";
    String buttonSubtitle = "Save and continue";
    IconData buttonIcon = Icons.home_outlined;

    final List<Map<String, dynamic>> steps = _buildStepsList();
    final totalSteps = steps.length;

    if (_expandedSectionIndex == totalSteps - 2) {
      buttonTitle = "Next: Payment Details";
      buttonIcon = Icons.payment_outlined;
    } else if (_expandedSectionIndex == totalSteps - 1) {
      buttonTitle = "Submit Aadhaar Form";
      buttonSubtitle = "Proceed to secure application submission";
      buttonIcon = Icons.check_circle_outline;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildTopNavBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    _buildCategoryTabs(),

                    // Expandable Accordion Stepper Cards
                    ...List.generate(totalSteps, (i) {
                      final s = steps[i];
                      return _buildAccordionSection(
                        index: s['index'] as int,
                        title: s['title'] as String,
                        subtitle: s['subtitle'] as String,
                        leadingIcon: s['icon'] as IconData,
                        child: s['child'] as Widget,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom Gradient Action Bar
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryPurple, secondaryPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading
                      ? null
                      : () {
                          if (_expandedSectionIndex < totalSteps - 1) {
                            setState(() {
                              _expandedSectionIndex++;
                            });
                          } else {
                            _submitAadhaarForm();
                          }
                        },
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _loading
                              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                              : Icon(buttonIcon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loading ? "Processing..." : buttonTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _loading ? "Please wait a moment" : buttonSubtitle,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: primaryPurple, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildStepsList() {
    final List<Map<String, dynamic>> steps = [];
    int sIdx = 0;

    // Step 1: Personal Info
    steps.add({
      'index': sIdx++,
      'title': '1. Personal Information',
      'subtitle': 'Aadhaar Card number and registration phone details',
      'icon': Icons.person_outline,
      'child': _buildPersonalInfoStep(),
    });

    // Step 2: Address for Communication (Hard Copy only)
    if (_selectedSectionId == 402) {
      steps.add({
        'index': sIdx++,
        'title': '2. Address For Communication',
        'subtitle': 'Fill shipping details for card print delivery',
        'icon': Icons.home_outlined,
        'child': _buildAddressStep(),
      });
    }

    // Step 3: Payment Details
    steps.add({
      'index': sIdx++,
      'title': '$sIdx. Payment Details',
      'subtitle': 'Aadhaar filing cost & processing checkout',
      'icon': Icons.payment_outlined,
      'child': _buildPaymentStep(),
    });

    return steps;
  }

  Widget _buildAccordionSection({
    required int index,
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required Widget child,
  }) {
    final isExpanded = _expandedSectionIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? primaryPurple.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? primaryPurple.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.01),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expandedSectionIndex = isExpanded ? -1 : index;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpanded ? primaryPurple.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                leadingIcon,
                color: isExpanded ? primaryPurple : textSubdued,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textDarkHeading),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: textSubdued),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSubdued,
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        _buildInput('Aadhaar Number *', _aadhaarNoCtrl, isNum: true, placeholder: 'Enter 12-digit Aadhaar Number', prefixIcon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _buildInput('Phone Number *', _phoneNoCtrl, isNum: true, placeholder: 'Enter mobile number', prefixIcon: Icons.phone_iphone_outlined),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
        const SizedBox(height: 10),
        _buildResponsiveRow(
          context,
          _buildAddressTypeCard('Address Per Application', 'Address as per Aadhaar application', 'Address Per Application', Icons.assignment_outlined),
          _buildAddressTypeCard('Business Partner Address', 'Address of your business partner', 'Business Partner Address', Icons.business_center_outlined),
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          context,
          _buildInput('House No./Building *', _commHouseNoCtrl, placeholder: 'Flat or House No.', prefixIcon: Icons.home_outlined),
          _buildInput('Street/Road/Lane *', _commStreetCtrl, placeholder: 'Street area', prefixIcon: Icons.add_road_outlined),
        ),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          context,
          _buildInput('Tehsil/Post *', _commTehsilCtrl, placeholder: 'Tehsil or Post office', prefixIcon: Icons.map_outlined),
          _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 6, placeholder: 'Pincode', prefixIcon: Icons.pin_drop_outlined),
        ),
        const SizedBox(height: 14),

        _buildThreeColumnRow(
          context,
          _buildInput('District *', _commDistrictCtrl, placeholder: 'District', prefixIcon: Icons.location_city_outlined),
          _buildInput('State *', _commStateCtrl, placeholder: 'State', prefixIcon: Icons.map),
          _buildInput('City *', _commCityCtrl, placeholder: 'City', prefixIcon: Icons.location_on_outlined),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAadhaarTypeName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Includes secure filing & processing',
                      style: TextStyle(fontSize: 11, color: textSubdued),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${_payableAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryPurple),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payments are secure and encrypted.',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(26.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryPurple, secondaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDarkHeading),
              ),
              const SizedBox(height: 8),
              Text(
                'Your $_currentAadhaarTypeName request has been placed successfully and is being processed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    const Text('Tracking Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SelectableText(
                      _trackingId ?? '',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: primaryPurple, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button 1: View in Orders / My Requests
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialIndex: 2),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined, size: 20),
                  label: const Text(
                    'View My Orders / Requests',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Button 2: Back to Home
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, size: 18, color: primaryPurple),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: primaryPurple),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryPurple.withValues(alpha: 0.3), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(BuildContext context, Widget child1, Widget child2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 650;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: child1),
                  const SizedBox(width: 14),
                  Expanded(child: child2),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child1,
                  const SizedBox(height: 14),
                  child2,
                ],
              );
      },
    );
  }

  Widget _buildThreeColumnRow(BuildContext context, Widget c1, Widget c2, Widget c3) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 750;
        return isWide
            ? Row(
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 10),
                  Expanded(child: c2),
                  const SizedBox(width: 10),
                  Expanded(child: c3),
                ],
              )
            : Column(
                children: [
                  c1,
                  const SizedBox(height: 12),
                  c2,
                  const SizedBox(height: 12),
                  c3,
                ],
              );
      },
    );
  }

  Widget _buildAddressTypeCard(String title, String subtitle, String value, IconData icon) {
    bool isSel = _commAddressType == value;
    return GestureDetector(
      onTap: () => _setCommAddressMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? primaryPurple.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? primaryPurple : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSel ? primaryPurple.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSel ? primaryPurple : textSubdued, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDarkHeading)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: textSubdued, height: 1.25)),
                ],
              ),
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<String>(
                value: value,
                groupValue: _commAddressType,
                activeColor: primaryPurple,
                onChanged: (v) => _setCommAddressMode(v!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isNum = false,
    int? maxLength,
    String? placeholder,
    IconData? prefixIcon,
  }) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: cleanLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: const Color(0xFFFAFAFA),
            filled: true,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
          ),
          validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

class _LoginModal extends StatefulWidget {
  final VoidCallback onSuccess;
  const _LoginModal({required this.onSuccess});

  @override
  State<_LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<_LoginModal> {
  final _idController   = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 22,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login Required', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textDarkHeading)),
              const SizedBox(height: 4),
              const Text('Please login to submit your Aadhaar application.', style: TextStyle(color: textSubdued, fontSize: 12.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Mobile or Email',
                  labelStyle: TextStyle(color: textSubdued, fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: textSubdued, fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Login & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final res = await _api.login(_idController.text.trim(), _passController.text.trim());
    if (mounted) setState(() => _loading = false);

    if (res['success'] == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.login(_idController.text.trim(), _passController.text.trim());
      widget.onSuccess();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Login failed')),
        );
      }
    }
  }
}
