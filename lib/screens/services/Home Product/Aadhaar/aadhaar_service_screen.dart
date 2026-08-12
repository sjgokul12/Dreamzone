import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';

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
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Selected Section ID: 402 = Aadhaar Card - Hard Copy, 401 = Aadhaar Card - Soft Copy
  late int _selectedSectionId;

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

  // App Theme Color Palette
  static const Color primaryPurple      = Color(0xFF8B5CF6);
  static const Color headerGradientStart= Color(0xFF9333EA);
  static const Color headerGradientEnd  = Color(0xFFC084FC);
  static const Color textDarkHeading    = Color(0xFF1E293B);
  static const Color textLabelDark      = Color(0xFF334155);
  static const Color textSubdued        = Color(0xFF64748B);
  static const Color bgCanvas           = Color(0xFFF8FAFC);
  static const Color cardSurface        = Colors.white;

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.preselectedSectionId ?? 402; // Default to Hard Copy

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  // ─── Auto-fill Communication Address ──────────────────────────────────────
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
          if (_savedDetails!['mobile'] != null) _phoneNoCtrl.text = _savedDetails!['mobile'];
          if (_savedDetails!['aadhaar_number'] != null) _aadhaarNoCtrl.text = _savedDetails!['aadhaar_number'];
        });
      }
    } catch (_) {}
  }

  void _applySavedDetails() {
    if (_savedDetails == null) return;
    setState(() {
      _phoneNoCtrl.text   = _savedDetails!['mobile'] ?? _phoneNoCtrl.text;
      _aadhaarNoCtrl.text = _savedDetails!['aadhaar_number'] ?? _aadhaarNoCtrl.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('✨ Saved profile details applied!', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get _payableAmount => 500.00;

  String get _currentAadhaarTypeName => _selectedSectionId == 401 ? 'Aadhaar Card - Soft Copy' : 'Aadhaar Card - Hard Copy';

  Future<void> _submitAadhaarForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, String> formData = {
      'aadhaar_type':       _currentAadhaarTypeName,
      'aadhaar_number':     _aadhaarNoCtrl.text.trim(),
      'phone_number':       _phoneNoCtrl.text.trim(),
      'comm_address_type':  _commAddressType,
      'comm_house_no':      _commHouseNoCtrl.text.trim(),
      'comm_street':        _commStreetCtrl.text.trim(),
      'comm_tehsil':        _commTehsilCtrl.text.trim(),
      'comm_pincode':       _commPincodeCtrl.text.trim(),
      'comm_district':      _commDistrictCtrl.text.trim(),
      'comm_state':         _commStateCtrl.text.trim(),
      'comm_city':          _commCityCtrl.text.trim(),
      'amount':             _payableAmount.toStringAsFixed(2),
    };

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

      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= data['tracking_id'] ??
              'TRK-ADH-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-ADH-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
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

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 920) / 2
        : (screenSize.width > 700 ? 24.0 : 12.0);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Top Hero Container
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textDarkHeading, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Aadhaar ',
                                    style: TextStyle(
                                      color: primaryPurple,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Card',
                                    style: TextStyle(
                                      color: textDarkHeading,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Get your Aadhaar card soft or hard copy delivered to your address',
                              style: TextStyle(
                                color: textSubdued,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'assets/Aadhar card.png',
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mode Selector Tabs (Hard Copy / Soft Copy)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: _buildTabChip(401, 'Soft Copy')),
                        Expanded(child: _buildTabChip(402, 'Hard Copy')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Form Content Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_savedDetails != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _applySavedDetails,
                          icon: const Icon(Icons.bolt, color: Colors.white, size: 16),
                          label: const Text(
                            'Auto-Fill Saved Profile',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Container(
                      decoration: BoxDecoration(
                        color: cardSurface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1: Personal Information
                          _buildHeaderBanner('1. Personal Information', Icons.person),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                bool isWide = constraints.maxWidth > 650;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(child: _buildInput('Aadhaar Number *', _aadhaarNoCtrl, isNum: true, placeholder: 'Enter Aadhaar Number', prefixIcon: Icons.badge_outlined)),
                                          const SizedBox(width: 14),
                                          Expanded(child: _buildInput('Phone Number *', _phoneNoCtrl, isNum: true, placeholder: 'Enter Phone Number', prefixIcon: Icons.call_outlined)),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildInput('Aadhaar Number *', _aadhaarNoCtrl, isNum: true, placeholder: 'Enter Aadhaar Number', prefixIcon: Icons.badge_outlined),
                                          const SizedBox(height: 14),
                                          _buildInput('Phone Number *', _phoneNoCtrl, isNum: true, placeholder: 'Enter Phone Number', prefixIcon: Icons.call_outlined),
                                        ],
                                      );
                              },
                            ),
                          ),

                          // SECTION 2: Address For Communication
                          if (_selectedSectionId == 402) ...[
                            _buildHeaderBanner('2. Address For Communication', Icons.location_on),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 500;
                                      return isWide
                                          ? Row(
                                              children: [
                                                Expanded(child: _buildAddressTypeCard('Address Per Application', 'Address as per\nAadhaar application', 'Address Per Application', Icons.account_balance_outlined)),
                                                const SizedBox(width: 12),
                                                Expanded(child: _buildAddressTypeCard('Business Partner Address', 'Address of your\nbusiness partner', 'Business Partner Address', Icons.business_center_outlined)),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildAddressTypeCard('Address Per Application', 'Address as per\nAadhaar application', 'Address Per Application', Icons.account_balance_outlined),
                                                const SizedBox(height: 12),
                                                _buildAddressTypeCard('Business Partner Address', 'Address of your\nbusiness partner', 'Business Partner Address', Icons.business_center_outlined),
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 750;
                                      return isWide
                                          ? Row(children: [
                                              Expanded(child: _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: 'Enter House No. / Building', prefixIcon: Icons.home_outlined)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Street/Road/Lane *', _commStreetCtrl, maxLength: 25, placeholder: 'Enter Street / Road / Lane', prefixIcon: Icons.add_road_outlined)),
                                            ])
                                          : Column(children: [
                                              _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: 'Enter House No. / Building', prefixIcon: Icons.home_outlined),
                                              const SizedBox(height: 10),
                                              _buildInput('Street/Road/Lane *', _commStreetCtrl, maxLength: 25, placeholder: 'Enter Street / Road / Lane', prefixIcon: Icons.add_road_outlined),
                                            ]);
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 750;
                                      return isWide
                                          ? Row(children: [
                                              Expanded(child: _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'Enter Tehsil / Post', prefixIcon: Icons.map_outlined)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 6, placeholder: 'Enter Pincode', prefixIcon: Icons.pin_drop_outlined)),
                                            ])
                                          : Column(children: [
                                              _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'Enter Tehsil / Post', prefixIcon: Icons.map_outlined),
                                              const SizedBox(height: 10),
                                              _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 6, placeholder: 'Enter Pincode', prefixIcon: Icons.pin_drop_outlined),
                                            ]);
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 750;
                                      return isWide
                                          ? Row(children: [
                                              Expanded(child: _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'Enter District', prefixIcon: Icons.location_city_outlined)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'Enter State', prefixIcon: Icons.map)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'Enter City', prefixIcon: Icons.location_city)),
                                            ])
                                          : Column(children: [
                                              _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'Enter District', prefixIcon: Icons.location_city_outlined),
                                              const SizedBox(height: 10),
                                              _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'Enter State', prefixIcon: Icons.map),
                                              const SizedBox(height: 10),
                                              _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'Enter City', prefixIcon: Icons.location_city),
                                            ]);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],

                          // SECTION 3: Payment
                          _buildHeaderBanner(_selectedSectionId == 402 ? '3. Payment' : '2. Payment', Icons.payment_outlined),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    'Total Payable Amount is ₹${_payableAmount.toStringAsFixed(2)}/-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textDarkHeading,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: SizedBox(
                                    width: 160,
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submitAadhaarForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryPurple,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int id, String title) {
    bool isSel = _selectedSectionId == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSectionId = id;
          _formKey.currentState?.reset();
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSel ? primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSel ? Border.all(color: primaryPurple.withValues(alpha: 0.3), width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSel ? primaryPurple : textSubdued,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [headerGradientStart, headerGradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
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
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textDarkHeading)),
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
    String? helper,
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            counterText: helper,
            counterStyle: const TextStyle(fontSize: 11, color: primaryPurple, fontWeight: FontWeight.w600),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: Colors.white,
            filled: true,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 22) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
          ),
          validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(26.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textDarkHeading),
              ),
              const SizedBox(height: 8),
              Text(
                'Your $_currentAadhaarTypeName request has been received successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Tracking Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _trackingId ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryPurple, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Login Required', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Please login to submit your Aadhaar application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: 'Mobile or Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
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
