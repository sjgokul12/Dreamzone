import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';
import 'package:dreamzoneapp/core/payment/razorpay_service.dart';

class FastagPurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const FastagPurchaseScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<FastagPurchaseScreen> createState() => _FastagPurchaseScreenState();
}

class _FastagPurchaseScreenState extends State<FastagPurchaseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // 1. Personal Information Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();

  // 2. Contact Information Controllers
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailIdController      = TextEditingController();

  // Delivery State API List
  List<String> _deliveryStates = [];
  bool         _statesLoading  = true;
  String?      _deliveryState;

  // 3. Vehicle Details Controllers
  final TextEditingController _vehicleClassController         = TextEditingController();
  final TextEditingController _vehicleNumberController        = TextEditingController();
  final TextEditingController _chassisNumberController        = TextEditingController();
  final TextEditingController _engineNumberController         = TextEditingController();
  final TextEditingController _registrationLocationController = TextEditingController();

  // 4. Address For Communication Controllers
  String _commAddressType = 'Business Partner Address'; // Default auto-fill mode
  final TextEditingController _commHouseNoCtrl  = TextEditingController(text: '#702');
  final TextEditingController _commStreetCtrl   = TextEditingController(text: 'KORMANAGALA');
  final TextEditingController _commTehsilCtrl   = TextEditingController(text: 'NETHAJI CIRCLE');
  final TextEditingController _commPincodeCtrl  = TextEditingController(text: '560054');
  final TextEditingController _commDistrictCtrl = TextEditingController(text: 'SOUTH BANGALORE');
  final TextEditingController _commStateCtrl    = TextEditingController(text: 'KARNATAKA');
  final TextEditingController _commCityCtrl     = TextEditingController(text: 'BANGALORE');

  // 5. Upload Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium Violet / Indigo Palette
  static const Color primaryPurple      = Color(0xFF5F33E1);
  static const Color secondaryPurple    = Color(0xFF7C3AED);
  static const Color textDarkHeading    = Color(0xFF0F172A);
  static const Color textLabelDark      = Color(0xFF1E293B);
  static const Color textSubdued        = Color(0xFF64748B);
  static const Color bgCanvas           = Color(0xFFF8FAFC);
  static const Color cardSurface        = Colors.white;

  // Accordion active step tracker
  int _expandedSectionIndex = 0;

  // Vehicle Class Dropdown Options
  final List<String> _vehicleClasses = ['Car / Jeep / Van', 'Light Commercial Vehicle', 'Bus / Truck', 'Mini Bus'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _fetchDeliveryStates();
    _loadSavedUserData();
    _razorpayService.init();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _vehicleClassController.dispose();
    _vehicleNumberController.dispose();
    _chassisNumberController.dispose();
    _engineNumberController.dispose();
    _registrationLocationController.dispose();
    _commHouseNoCtrl.dispose();
    _commStreetCtrl.dispose();
    _commTehsilCtrl.dispose();
    _commPincodeCtrl.dispose();
    _commDistrictCtrl.dispose();
    _commStateCtrl.dispose();
    _commCityCtrl.dispose();
    super.dispose();
  }

  // ─── Fetch Delivery States from API ────────────────────────────────────────
  Future<void> _fetchDeliveryStates() async {
    if (mounted) setState(() { _statesLoading = true; });
    try {
      final resStates = await ApiService.fetchApi('/fastag-purchase/states');
      final dataStates = jsonDecode(resStates.body) as Map<String, dynamic>;
      if (dataStates['success'] == true && dataStates['states'] != null) {
        _deliveryStates = (dataStates['states'] as List<dynamic>).map((e) => e.toString()).toList();
      }
    } catch (_) {
      _deliveryStates = ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];
    }

    if (mounted) {
      setState(() {
        _statesLoading = false;
      });
    }
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
          if (_savedDetails!['full_name'] != null) {
            final parts = (_savedDetails!['full_name'] as String).split(' ');
            _firstNameController.text = parts.first;
            if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
          }
          if (_savedDetails!['mobile'] != null) {
            _mobileNumberController.text = _savedDetails!['mobile'];
          }
          if (_savedDetails!['email'] != null) {
            _emailIdController.text = _savedDetails!['email'];
          }
        });
      }
    } catch (_) {}
  }

  void _applySavedDetails() {
    if (_savedDetails == null) return;
    setState(() {
      if (_savedDetails!['full_name'] != null) {
        final parts = (_savedDetails!['full_name'] as String).split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
      }
      _mobileNumberController.text = _savedDetails!['mobile'] ?? _mobileNumberController.text;
      _emailIdController.text      = _savedDetails!['email'] ?? _emailIdController.text;
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

  double get _payableAmount => 450.00;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile(String docKey) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final f = result.files.first;
        if (f.size > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ File size must be under 2MB', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        final ext = (f.extension ?? f.name.split('.').last).toLowerCase();

        setState(() {
          _uploadedDocs[docKey] = [
            {
              'bytes': f.bytes,
              'name': f.name,
              'size': f.size,
              'extension': ext,
            }
          ];
        });
      }
    } catch (_) {}
  }

  void _removeFile(String docKey) {
    setState(() {
      _uploadedDocs.remove(docKey);
    });
  }

  Future<void> _submitFastagForm() async {
    if (!_formKey.currentState!.validate()) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        setState(() => _expandedSectionIndex = 0);
        return;
      }
      if (_mobileNumberController.text.trim().isEmpty || _emailIdController.text.trim().isEmpty || _deliveryState == null) {
        setState(() => _expandedSectionIndex = 1);
        return;
      }
      if (_vehicleClassController.text.trim().isEmpty || _vehicleNumberController.text.trim().isEmpty || _chassisNumberController.text.trim().isEmpty || _engineNumberController.text.trim().isEmpty || _registrationLocationController.text.trim().isEmpty) {
        setState(() => _expandedSectionIndex = 2);
        return;
      }
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    // Open Razorpay first; backend called only on payment success
    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: 'FASTag Purchase',
      name: 'DZI Infinity',
      contact: _mobileNumberController.text.trim(),
      email: _emailIdController.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitFastagForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitFastagForm({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type':          'Fastag Purchase',
      'first_name':            _firstNameController.text.trim(),
      'last_name':             _lastNameController.text.trim(),
      'mobile_number':         _mobileNumberController.text.trim(),
      'email_id':              _emailIdController.text.trim(),
      'delivery_state':        _deliveryState ?? '',
      'vehicle_class':         _vehicleClassController.text.trim(),
      'vehicle_number':        _vehicleNumberController.text.trim(),
      'chassis_number':        _chassisNumberController.text.trim(),
      'engine_number':         _engineNumberController.text.trim(),
      'registration_location': _registrationLocationController.text.trim(),
      'comm_address_type':     _commAddressType,
      'comm_house_no':          _commHouseNoCtrl.text.trim(),
      'comm_street':           _commStreetCtrl.text.trim(),
      'comm_tehsil':           _commTehsilCtrl.text.trim(),
      'comm_pincode':          _commPincodeCtrl.text.trim(),
      'comm_district':         _commDistrictCtrl.text.trim(),
      'comm_state':            _commStateCtrl.text.trim(),
      'comm_city':             _commCityCtrl.text.trim(),
      'amount':                _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':   razorpayPaymentId,
      'payment_status':        'paid',
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/fastag-purchase/apply'),
      );
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '500';
      request.fields['form_id']   = widget.preselectedSectionId?.toString() ?? '501';
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in formData.entries) {
        request.fields[entry.key] = entry.value;
      }

      for (var entry in _uploadedDocs.entries) {
        for (var fileInfo in entry.value) {
          if (fileInfo['bytes'] != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                entry.key,
                fileInfo['bytes'],
                filename: fileInfo['name'],
              ),
            );
          }
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 35));
      final resBody  = await response.stream.bytesToString();
      final data     = jsonDecode(resBody);

      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= data['tracking_id'] ??
              'TRK-FTG-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-FTG-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitFastagForm();
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                  'Secure & Safe • 100% Protected',
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

  Widget _buildFastagHeroCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth / 1.6;
        return Container(
          width: double.infinity,
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: 12),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/Fasttag pur.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F0FF),
                        child: const Center(
                          child: Icon(Icons.directions_car_rounded, size: 70, color: primaryPurple),
                        ),
                      );
                    },
                  ),
                ),
                // Clickable overlay mapping specifically for the Auto-Fill button pre-rendered in the image
                Positioned(
                  left: constraints.maxWidth * 0.045,
                  bottom: cardHeight * 0.125,
                  width: constraints.maxWidth * 0.44,
                  height: cardHeight * 0.18,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _applySavedDetails,
                      borderRadius: BorderRadius.circular(20),
                      splashColor: primaryPurple.withValues(alpha: 0.15),
                      highlightColor: primaryPurple.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccordionSection({
    required int index,
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required Widget child,
  }) {
    final isOpen = _expandedSectionIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isOpen ? primaryPurple.withValues(alpha: 0.15) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSectionIndex = isOpen ? -1 : index;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isOpen ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        leadingIcon,
                        color: isOpen ? primaryPurple : textSubdued,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDarkHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: textSubdued,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isOpen ? primaryPurple : textSubdued,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
              child: child,
            ),
            crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 920) / 2
        : (screenSize.width > 700 ? 24.0 : 16.0);

    String buttonTitle = "Next: Contact Information";
    String buttonSubtitle = "Save and continue";
    IconData buttonIcon = Icons.contacts_outlined;

    if (_expandedSectionIndex == 1) {
      buttonTitle = "Next: Vehicle Details";
      buttonIcon = Icons.directions_car_outlined;
    } else if (_expandedSectionIndex == 2) {
      buttonTitle = "Next: Communication Address";
      buttonIcon = Icons.home_outlined;
    } else if (_expandedSectionIndex == 3) {
      buttonTitle = "Next: Upload Documents";
      buttonIcon = Icons.cloud_upload_outlined;
    } else if (_expandedSectionIndex == 4) {
      buttonTitle = "Next: Payment Info";
      buttonIcon = Icons.payment_outlined;
    } else if (_expandedSectionIndex == 5) {
      buttonTitle = "Proceed to Submit";
      buttonSubtitle = "Final step to complete";
      buttonIcon = Icons.check_circle_outline;
    } else if (_expandedSectionIndex == -1) {
      buttonTitle = "Submit Fastag Form";
      buttonSubtitle = "Fill & Review all details";
      buttonIcon = Icons.description_outlined;
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
                    _buildFastagHeroCard(),
                    const SizedBox(height: 12),
                    
                    if (_savedDetails != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _applySavedDetails,
                          icon: const Icon(Icons.bolt, color: primaryPurple, size: 16),
                          label: const Text(
                            'Auto-Fill Saved Profile',
                            style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F3FF),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildAccordionSection(
                      index: 0,
                      title: "1. Personal Information",
                      subtitle: "Enter your personal details",
                      leadingIcon: Icons.person_outline,
                      child: _buildResponsiveRow(
                        context,
                        _buildInput('First Name *', _firstNameController, placeholder: 'Enter First Name', prefixIcon: Icons.face_outlined),
                        _buildInput('Last Name *', _lastNameController, placeholder: 'Enter Last Name', prefixIcon: Icons.face_outlined),
                      ),
                    ),

                    _buildAccordionSection(
                      index: 1,
                      title: "2. Contact Information",
                      subtitle: "Provide details for shipping & updates",
                      leadingIcon: Icons.contact_mail_outlined,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 700;
                          final stateList = _deliveryStates.isNotEmpty ? _deliveryStates : ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'Mobile Number', prefixIcon: Icons.phone_android_outlined)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('Email ID *', _emailIdController, placeholder: 'Enter Email ID', prefixIcon: Icons.mail_outline)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _statesLoading
                                          ? const Padding(
                                              padding: EdgeInsets.only(top: 28),
                                              child: Row(children: [
                                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple)),
                                                SizedBox(width: 8),
                                                Text('Loading states…', style: TextStyle(fontSize: 12, color: textSubdued)),
                                              ]),
                                            )
                                          : _buildDropdownField('Delivery State *', _deliveryState, stateList, (v) => setState(() => _deliveryState = v), hint: 'Select State', prefixIcon: Icons.map_outlined),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'Mobile Number', prefixIcon: Icons.phone_android_outlined),
                                    const SizedBox(height: 12),
                                    _buildInput('Email ID *', _emailIdController, placeholder: 'Enter Email ID', prefixIcon: Icons.mail_outline),
                                    const SizedBox(height: 12),
                                    _statesLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Row(children: [
                                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple)),
                                              SizedBox(width: 8),
                                              Text('Loading states…', style: TextStyle(fontSize: 12, color: textSubdued)),
                                            ]),
                                          )
                                        : _buildDropdownField('Delivery State *', _deliveryState, stateList, (v) => setState(() => _deliveryState = v), hint: 'Select State', prefixIcon: Icons.map_outlined),
                                  ],
                                );
                        },
                      ),
                    ),

                    _buildAccordionSection(
                      index: 2,
                      title: "3. Vehicle Details",
                      subtitle: "Enter registered vehicle details",
                      leadingIcon: Icons.directions_car_outlined,
                      child: Column(
                        children: [
                          _buildResponsiveRow(
                            context,
                            _buildDropdownField('Vehicle Type *', _vehicleClassController.text.isEmpty ? null : _vehicleClassController.text, _vehicleClasses, (v) => setState(() => _vehicleClassController.text = v ?? ''), hint: 'Select Type', prefixIcon: Icons.local_play_outlined),
                            _buildInput('Vehicle Number *', _vehicleNumberController, placeholder: 'e.g. DL1CA1234', prefixIcon: Icons.numbers_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Chassis Number *', _chassisNumberController, placeholder: 'Chassis Number', prefixIcon: Icons.settings_applications_outlined),
                            _buildInput('Engine Number *', _engineNumberController, placeholder: 'Engine Number', prefixIcon: Icons.engineering_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildInput('Registration Location *', _registrationLocationController, placeholder: 'RTO Office Location', prefixIcon: Icons.location_on_outlined),
                        ],
                      ),
                    ),

                    _buildAccordionSection(
                      index: 3,
                      title: "4. Address For Communication",
                      subtitle: "Select & fill delivery address details",
                      leadingIcon: Icons.home_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Delivery Address Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkHeading)),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Business Partner Address',
                                          groupValue: _commAddressType,
                                          activeColor: primaryPurple,
                                          onChanged: (v) => _setCommAddressMode(v!),
                                        ),
                                        const Text('Business Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDarkHeading)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Address Per Application',
                                          groupValue: _commAddressType,
                                          activeColor: primaryPurple,
                                          onChanged: (v) => _setCommAddressMode(v!),
                                        ),
                                        const Text('App Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDarkHeading)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 750;
                              return isWide
                                  ? Row(children: [
                                      Expanded(child: _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: 'e.g. #702', prefixIcon: Icons.home_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildInput('Street/Area *', _commStreetCtrl, maxLength: 25, placeholder: 'Street/Area Name', prefixIcon: Icons.directions_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'Tehsil or Post office', prefixIcon: Icons.location_city_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 25, placeholder: 'Pincode', prefixIcon: Icons.pin_drop_outlined, helper: 'Max 25 characters')),
                                    ])
                                  : Column(children: [
                                      _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: 'e.g. #702', prefixIcon: Icons.home_outlined, helper: 'Max 25 characters'),
                                      const SizedBox(height: 10),
                                      _buildInput('Street/Area *', _commStreetCtrl, maxLength: 25, placeholder: 'Street/Area Name', prefixIcon: Icons.directions_outlined, helper: 'Max 25 characters'),
                                      const SizedBox(height: 10),
                                      _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'Tehsil or Post office', prefixIcon: Icons.location_city_outlined, helper: 'Max 25 characters'),
                                      const SizedBox(height: 10),
                                      _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 25, placeholder: 'Pincode', prefixIcon: Icons.pin_drop_outlined, helper: 'Max 25 characters'),
                                    ]);
                            },
                          ),

                          const SizedBox(height: 14),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 750;
                              return isWide
                                  ? Row(children: [
                                      Expanded(child: _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'District Name', prefixIcon: Icons.map_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'State Name', prefixIcon: Icons.public_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'City Name', prefixIcon: Icons.location_on_outlined, helper: 'Max 25 characters')),
                                      const SizedBox(width: 10),
                                      const Expanded(child: SizedBox()),
                                    ])
                                  : Column(children: [
                                      _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'District Name', prefixIcon: Icons.map_outlined, helper: 'Max 25 characters'),
                                      const SizedBox(height: 10),
                                      _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'State Name', prefixIcon: Icons.public_outlined, helper: 'Max 25 characters'),
                                      const SizedBox(height: 10),
                                      _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'City Name', prefixIcon: Icons.location_on_outlined, helper: 'Max 25 characters'),
                                    ]);
                            },
                          ),
                        ],
                      ),
                    ),

                    _buildAccordionSection(
                      index: 4,
                      title: "5. Upload Document",
                      subtitle: "Upload vehicle RC and identity proofs",
                      leadingIcon: Icons.cloud_upload_outlined,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                final requiredKeys = ['doc_rc', 'doc_aadhaar', 'doc_pan'];
                                final firstEmpty = requiredKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => 'doc_rc');
                                _pickFile(firstEmpty);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryPurple.withValues(alpha: 0.2), style: BorderStyle.solid),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, size: 36, color: primaryPurple),
                                    SizedBox(height: 8),
                                    Text(
                                      'Browse files to upload',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'PDF, PNG, JPG up to 2MB',
                                      style: TextStyle(fontSize: 11, color: textSubdued),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildDocUploadCard('Vehicle RC Book / Document *', 'doc_rc'),
                            _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                            _buildDocUploadCard('PAN Card *', 'doc_pan'),
                          ],
                        ),
                      ),
                    ),

                    _buildAccordionSection(
                      index: 5,
                      title: "6. Payment Information",
                      subtitle: "Review cost & secure checkout",
                      leadingIcon: Icons.payment_outlined,
                      child: Column(
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
                                      const Text(
                                        'Fastag Tag & Processing Fee',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Tag Deposit and Issuance Included',
                                        style: TextStyle(fontSize: 11, color: textSubdued),
                                      ),
                                    ],
                                  ),
                                ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            top: false,
            child: _buildBottomActionButton(
              title: buttonTitle,
              subtitle: buttonSubtitle,
              leftIcon: buttonIcon,
              onTap: () {
                if (_expandedSectionIndex >= 0 && _expandedSectionIndex < 5) {
                  setState(() {
                    _expandedSectionIndex++;
                  });
                } else if (_expandedSectionIndex == -1) {
                  setState(() {
                    _expandedSectionIndex = 0;
                  });
                } else {
                  _submitFastagForm();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String title,
    required String subtitle,
    required IconData leftIcon,
    required VoidCallback onTap,
  }) {
    return Container(
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
          onTap: onTap,
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
                  child: Icon(leftIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: primaryPurple,
                    size: 18,
                  ),
                ),
              ],
            ),
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

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isNum = false,
    int? maxLength,
    String? placeholder,
    IconData? prefixIcon,
    String? helper,
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
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
            counterText: helper,
            counterStyle: const TextStyle(fontSize: 10, color: primaryPurple, fontWeight: FontWeight.w600),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: const Color(0xFFFAFAFA),
            filled: true,
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

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {String hint = 'Please Select', IconData? prefixIcon}) {
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
        DropdownButtonFormField<String>(
          initialValue: (value != null && items.contains(value)) ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          isExpanded: true,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: const Color(0xFFFAFAFA),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: textDarkHeading), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
          validator: (v) => isReq && (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDocUploadCard(String title, String docKey) {
    final docs = _uploadedDocs[docKey] ?? [];
    final hasFile = docs.isNotEmpty;
    final file = hasFile ? docs.first : null;
    final fileName = file != null ? (file['name'] ?? '') : '';
    final fileSize = file != null ? (file['size'] as int? ?? 0) : 0;
    
    final isReq = title.contains('*');
    final cleanTitle = title.replaceAll('*', '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasFile ? primaryPurple.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: docKey.contains('photo') ? const [Color(0xFF6366F1), Color(0xFF3B82F6)] : 
                        docKey.contains('rc') ? const [Color(0xFFF5F90B), Color(0xFFD97706)] :
                        docKey.contains('aadhaar') ? const [Color(0xFFEF4444), Color(0xFFDC2626)] :
                        docKey.contains('pan') ? const [Color(0xFF8B5CF6), Color(0xFF7C3AED)] :
                        const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              docKey.contains('photo') ? Icons.person : 
              docKey.contains('rc') ? Icons.directions_car :
              Icons.credit_card, 
              color: Colors.white, size: 24
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: hasFile ? fileName : cleanTitle,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textDarkHeading),
                    children: (!hasFile && isReq) ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile ? 'Uploaded • ${_formatBytes(fileSize)}' : 'PDF, PNG, JPG up to 2MB',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSubdued,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (hasFile)
            IconButton(
              onPressed: () => _removeFile(docKey),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 24),
              tooltip: 'Remove file',
            )
          else
            ElevatedButton.icon(
              onPressed: () => _pickFile(docKey),
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple.withValues(alpha: 0.1),
                foregroundColor: primaryPurple,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
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
              const Text(
                'Your Fastag Purchase request has been received successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
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
          const Text('Please login to submit your Fastag application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
                backgroundColor: const Color(0xFF00A896),
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
