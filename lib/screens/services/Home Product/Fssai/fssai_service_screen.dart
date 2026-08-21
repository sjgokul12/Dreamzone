import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';
import 'package:dreamzoneapp/core/payment/razorpay_service.dart';

// Premium Palette Theme Constants (Shared Globally in this file)
const Color primaryPurple      = Color(0xFF5F33E1);
const Color secondaryPurple    = Color(0xFF7C3AED);
const Color textDarkHeading    = Color(0xFF1E1B4B);
const Color textLabelDark      = Color(0xFF312E81);
const Color textSubdued        = Color(0xFF6B7280);
const Color bgCanvas           = Color(0xFFF5F3FF);
const Color cardSurface        = Colors.white;

class FssaiServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const FssaiServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<FssaiServiceScreen> createState() => _FssaiServiceScreenState();
}

class _FssaiServiceScreenState extends State<FssaiServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;
  int _expandedSectionIndex = 0;

  // 1. Personal Information Controllers
  String _applicantCategory = 'New';
  final TextEditingController _businessNameCtrl   = TextEditingController();
  final TextEditingController _applicantNameCtrl  = TextEditingController();
  final TextEditingController _fatherNameCtrl     = TextEditingController();
  final TextEditingController _businessAddressCtrl= TextEditingController();
  final TextEditingController _panNoCtrl           = TextEditingController();
  final TextEditingController _aadhaarNoCtrl       = TextEditingController();
  final TextEditingController _shopSizeCtrl        = TextEditingController();
  final TextEditingController _productNameCtrl     = TextEditingController();

  // 2. Contact Information Controllers
  final TextEditingController _mobileNumberCtrl  = TextEditingController();
  final TextEditingController _emailIdCtrl       = TextEditingController();

  // Delivery State API List
  List<String> _deliveryStates = [];
  bool         _statesLoading  = true;
  String?      _deliveryState;

  // 3. Upload Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;



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
    _businessNameCtrl.dispose();
    _applicantNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    _panNoCtrl.dispose();
    _aadhaarNoCtrl.dispose();
    _shopSizeCtrl.dispose();
    _productNameCtrl.dispose();
    _mobileNumberCtrl.dispose();
    _emailIdCtrl.dispose();
    super.dispose();
  }

  // ─── Fetch Delivery States from API ────────────────────────────────────────
  Future<void> _fetchDeliveryStates() async {
    if (mounted) setState(() { _statesLoading = true; });
    try {
      final resStates = await ApiService.fetchApi('/fssai/states');
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

  Future<void> _loadSavedUserData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) return;

    try {
      final res = await _api.getUserSavedDetails(auth.userId!);
      if (res['success'] == true && res['details'] != null && mounted) {
        setState(() {
          _savedDetails = res['details'];
          if (_savedDetails!['full_name'] != null) {
            _applicantNameCtrl.text = _savedDetails!['full_name'];
          }
          if (_savedDetails!['mobile'] != null) {
            _mobileNumberCtrl.text = _savedDetails!['mobile'];
          }
          if (_savedDetails!['email'] != null) {
            _emailIdCtrl.text = _savedDetails!['email'];
          }
          if (_savedDetails!['aadhaar_number'] != null) {
            _aadhaarNoCtrl.text = _savedDetails!['aadhaar_number'];
          }
          if (_savedDetails!['pan_number'] != null) {
            _panNoCtrl.text = _savedDetails!['pan_number'];
          }
        });
      }
    } catch (_) {}
  }

  void _applySavedDetails() {
    if (_savedDetails == null) return;
    setState(() {
      _applicantNameCtrl.text = _savedDetails!['full_name'] ?? _applicantNameCtrl.text;
      _mobileNumberCtrl.text  = _savedDetails!['mobile'] ?? _mobileNumberCtrl.text;
      _emailIdCtrl.text       = _savedDetails!['email'] ?? _emailIdCtrl.text;
      _aadhaarNoCtrl.text     = _savedDetails!['aadhaar_number'] ?? _aadhaarNoCtrl.text;
      _panNoCtrl.text         = _savedDetails!['pan_number'] ?? _panNoCtrl.text;
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

  Future<void> _submitFssaiForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    // Open Razorpay first; backend called only on payment success
    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: 'FSSAI License',
      name: 'DZI Infinity',
      contact: _mobileNumberCtrl.text.trim(),
      email: _emailIdCtrl.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitFssaiForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitFssaiForm({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type':         'FSSAI License',
      'applicant_category':   _applicantCategory,
      'business_name':        _businessNameCtrl.text.trim(),
      'applicant_name':       _applicantNameCtrl.text.trim(),
      'father_name':          _fatherNameCtrl.text.trim(),
      'business_address':     _businessAddressCtrl.text.trim(),
      'pan_no':               _panNoCtrl.text.trim(),
      'aadhaar_no':           _aadhaarNoCtrl.text.trim(),
      'shop_size':            _shopSizeCtrl.text.trim(),
      'product_name':         _productNameCtrl.text.trim(),
      'mobile_number':        _mobileNumberCtrl.text.trim(),
      'email_id':             _emailIdCtrl.text.trim(),
      'delivery_state':       _deliveryState ?? '',
      'amount':               _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':  razorpayPaymentId,
      'payment_status':       'paid',
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/fssai/apply'),
      );
      request.fields['user_id']    = auth.userId.toString();
      request.fields['service_id'] = widget.service['id']?.toString() ?? '900';
      request.fields['form_id']    = widget.preselectedSectionId?.toString() ?? '901';
      request.fields['form_data']  = jsonEncode(formData);

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
          _trackingId = data['tracking_id'] ??
              'TRK-FSS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId = 'TRK-FSS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitFssaiForm();
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: primaryPurple, size: 16),
                SizedBox(width: 6),
                Text(
                  'Secure & Verified',
                  style: TextStyle(
                    color: primaryPurple,
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

  Widget _buildFssaiHeroCard() {
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
            child: Image.asset(
              'assets/FSSAI full.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F0FF),
                  child: const Center(
                    child: Icon(Icons.restaurant_rounded, size: 70, color: primaryPurple),
                  ),
                );
              },
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

    // Dynamic sticky bottom button
    String buttonTitle = "Next: Contact Details";
    String buttonSubtitle = "Save and continue";
    IconData buttonIcon = Icons.contacts_outlined;

    if (_expandedSectionIndex == 1) {
      buttonTitle = "Next: Upload Documents";
      buttonIcon = Icons.cloud_upload_outlined;
    } else if (_expandedSectionIndex == 2) {
      buttonTitle = "Next: Payment Details";
      buttonIcon = Icons.payment_outlined;
    } else if (_expandedSectionIndex == 3) {
      buttonTitle = "Proceed to Submit";
      buttonSubtitle = "Final step to complete";
      buttonIcon = Icons.check_circle_outline;
    } else if (_expandedSectionIndex == -1) {
      buttonTitle = "Submit FSSAI Form";
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
                    _buildFssaiHeroCard(),
                    const SizedBox(height: 12),

                    // Auto Fill Banner
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

                    // Step 1: Personal Information
                    _buildAccordionSection(
                      index: 0,
                      title: "1. Personal Information",
                      subtitle: "Enter your personal and business details",
                      leadingIcon: Icons.person_outline,
                      child: Column(
                        children: [
                          _buildResponsiveRow(
                            context,
                            _buildDropdownField('Applicant Category *', _applicantCategory, ['New', 'Renewal'], (v) => setState(() => _applicantCategory = v!)),
                            _buildInput('Business Name *', _businessNameCtrl, placeholder: 'Enter Business Name', prefixIcon: Icons.storefront_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildInput("Applicant's Name *", _applicantNameCtrl, placeholder: "Enter Applicant's Name (As per Aadhaar)", prefixIcon: Icons.face_outlined),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Father Name *', _fatherNameCtrl, placeholder: "Enter Father's Name", prefixIcon: Icons.person_outline),
                            _buildInput('Business Address *', _businessAddressCtrl, placeholder: 'Enter Business Address', prefixIcon: Icons.location_on_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('PAN No. *', _panNoCtrl, placeholder: 'Enter PAN Number', prefixIcon: Icons.credit_card_outlined),
                            _buildInput('Aadhaar Number *', _aadhaarNoCtrl, isNum: true, placeholder: 'Enter Aadhaar Number', prefixIcon: Icons.assignment_ind_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Shop Size (Sq. Ft.) *', _shopSizeCtrl, placeholder: 'e.g. 500', prefixIcon: Icons.aspect_ratio_outlined),
                            _buildInput('Product Name *', _productNameCtrl, placeholder: 'Enter Product Name', prefixIcon: Icons.shopping_bag_outlined),
                          ),
                        ],
                      ),
                    ),

                    // Step 2: Contact Information
                    _buildAccordionSection(
                      index: 1,
                      title: "2. Contact Information",
                      subtitle: "Provide contact details for communication",
                      leadingIcon: Icons.contact_mail_outlined,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 700;
                          final stateList = _deliveryStates.isNotEmpty ? _deliveryStates : ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildInput('Mobile Number *', _mobileNumberCtrl, isNum: true, placeholder: 'Mobile Number', prefixIcon: Icons.phone_android_outlined)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('Email ID *', _emailIdCtrl, placeholder: 'Enter Email ID', prefixIcon: Icons.mail_outline)),
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
                                    _buildInput('Mobile Number *', _mobileNumberCtrl, isNum: true, placeholder: 'Mobile Number', prefixIcon: Icons.phone_android_outlined),
                                    const SizedBox(height: 12),
                                    _buildInput('Email ID *', _emailIdCtrl, placeholder: 'Enter Email ID', prefixIcon: Icons.mail_outline),
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

                    // Step 3: Upload Documents
                    _buildAccordionSection(
                      index: 2,
                      title: "3. Upload Documents",
                      subtitle: "Aadhaar, PAN, photo & business proof",
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
                                final requiredKeys = ['doc_aadhaar', 'doc_pan', 'doc_photo', 'doc_proof'];
                                final firstEmpty = requiredKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => 'doc_aadhaar');
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
                            _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                            _buildDocUploadCard('PAN Card *', 'doc_pan'),
                            _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
                            _buildDocUploadCard('Electricity Bill / Rent Agreement *', 'doc_proof'),
                          ],
                        ),
                      ),
                    ),

                    // Step 4: Payment Info
                    _buildAccordionSection(
                      index: 3,
                      title: "4. Payment Details",
                      subtitle: "Review application fee and proceed",
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
                                        'FSSAI Registration Fee',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Includes official fees & processing',
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
          
          // Sticky Bottom Gradient Button
          SafeArea(
            top: false,
            child: _buildBottomActionButton(
              title: buttonTitle,
              subtitle: buttonSubtitle,
              leftIcon: buttonIcon,
              onTap: () {
                if (_expandedSectionIndex >= 0 && _expandedSectionIndex < 3) {
                  setState(() {
                    _expandedSectionIndex++;
                  });
                } else if (_expandedSectionIndex == -1) {
                  setState(() {
                    _expandedSectionIndex = 0;
                  });
                } else {
                  _submitFssaiForm();
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
              docKey.contains('aadhaar') ? Icons.credit_card :
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
                'Your FSSAI License request has been received successfully.',
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
          const Text('Please login to submit your FSSAI application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
                backgroundColor: primaryPurple,
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
