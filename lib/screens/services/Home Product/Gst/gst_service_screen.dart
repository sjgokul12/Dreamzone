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

class GstServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const GstServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<GstServiceScreen> createState() => _GstServiceScreenState();
}

class _GstServiceScreenState extends State<GstServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // 1 Personal Information Controllers
  List<String> _applicantCategories = [];
  String?      _applicantCategory;
  final TextEditingController _applicantNameController   = TextEditingController();
  final TextEditingController _applicantFatherController = TextEditingController();
  final TextEditingController _applicantAddressController= TextEditingController();
  final TextEditingController _aadhaarNoController       = TextEditingController();
  final TextEditingController _panNoController           = TextEditingController();
  final TextEditingController _dobEstablishmentController= TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _serviceProductController   = TextEditingController();

  // 2 Contact Information Controllers
  final TextEditingController _mobileNumberController    = TextEditingController();
  final TextEditingController _emailIdController         = TextEditingController();

  // Delivery State API List
  List<String> _deliveryStates = [];
  bool         _statesLoading  = true;
  String?      _statesError;
  String?      _deliveryState;

  // 3 Account Information Controllers
  final TextEditingController _bankNameController  = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscCodeController  = TextEditingController();
  List<String> _accountTypes = [];
  String?      _accountType;

  // 4 Upload Documents Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _expandedSectionIndex = 0; // Tracks currently active step index

  String get _base => ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _fetchDropdownOptions();
    _loadSavedUserData();
    _razorpayService.init();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _applicantNameController.dispose();
    _applicantFatherController.dispose();
    _applicantAddressController.dispose();
    _aadhaarNoController.dispose();
    _panNoController.dispose();
    _dobEstablishmentController.dispose();
    _businessAddressController.dispose();
    _serviceProductController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  // ─── Fetch Dropdowns from API (States, Categories, Account Types) ──────────
  Future<void> _fetchDropdownOptions() async {
    if (mounted) setState(() { _statesLoading = true; _statesError = null; });
    try {
      // 1. Fetch States
      try {
        final resStates = await ApiService.fetchApi('/gst/states');
        final dataStates = jsonDecode(resStates.body) as Map<String, dynamic>;
        if (dataStates['success'] == true && dataStates['states'] != null) {
          _deliveryStates = (dataStates['states'] as List<dynamic>).map((e) => e.toString()).toList();
        }
      } catch (_) {
        _deliveryStates = ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];
      }

      // 2. Fetch Applicant Categories
      try {
        final resCats = await ApiService.fetchApi('/gst/applicant-categories');
        final dataCats = jsonDecode(resCats.body) as Map<String, dynamic>;
        if (dataCats['success'] == true && dataCats['categories'] != null) {
          _applicantCategories = (dataCats['categories'] as List<dynamic>).map((e) => e.toString()).toList();
        }
      } catch (_) {
        _applicantCategories = ['Proprietor', 'Partnership'];
      }

      // 3. Fetch Account Types
      try {
        final resAcc = await ApiService.fetchApi('/gst/account-types');
        final dataAcc = jsonDecode(resAcc.body) as Map<String, dynamic>;
        if (dataAcc['success'] == true && dataAcc['account_types'] != null) {
          _accountTypes = (dataAcc['account_types'] as List<dynamic>).map((e) => e.toString()).toList();
        }
      } catch (_) {
        _accountTypes = ['Savings A/c', 'Current A/c'];
      }

      if (mounted) {
        setState(() {
          _statesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statesError = 'Error loading options';
          _statesLoading = false;
        });
      }
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
          if (_applicantNameController.text.isEmpty && _savedDetails!['full_name'] != null) {
            _applicantNameController.text = _savedDetails!['full_name'];
          }
          if (_applicantFatherController.text.isEmpty && _savedDetails!['father_name'] != null) {
            _applicantFatherController.text = _savedDetails!['father_name'];
          }
          if (_mobileNumberController.text.isEmpty && _savedDetails!['mobile'] != null) {
            _mobileNumberController.text = _savedDetails!['mobile'];
          }
          if (_emailIdController.text.isEmpty && _savedDetails!['email'] != null) {
            _emailIdController.text = _savedDetails!['email'];
          }
          if (_aadhaarNoController.text.isEmpty && _savedDetails!['aadhaar_number'] != null) {
            _aadhaarNoController.text = _savedDetails!['aadhaar_number'];
          }
          if (_panNoController.text.isEmpty && _savedDetails!['pan_number'] != null) {
            _panNoController.text = _savedDetails!['pan_number'];
          }
        });
      }
    } catch (_) {}
  }

  double get _payableAmount => 699.00;

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

  Future<void> _submitGstForm() async {
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

    // Open Razorpay first; backend called only on payment success
    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: 'GST Registration',
      name: 'DZI Infinity',
      contact: _mobileNumberController.text.trim(),
      email: _emailIdController.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitGstForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitGstForm({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type':           'GST Registration',
      'applicant_category':     _applicantCategory ?? '',
      'applicant_name':         _applicantNameController.text.trim(),
      'applicant_father':       _applicantFatherController.text.trim(),
      'applicant_address':      _applicantAddressController.text.trim(),
      'aadhaar_no':             _aadhaarNoController.text.trim(),
      'pan_no':                 _panNoController.text.trim(),
      'date_of_establishment':  _dobEstablishmentController.text.trim(),
      'business_address':       _businessAddressController.text.trim(),
      'service_product':        _serviceProductController.text.trim(),
      'mobile_number':          _mobileNumberController.text.trim(),
      'email_id':               _emailIdController.text.trim(),
      'delivery_state':         _deliveryState ?? '',
      'bank_name':              _bankNameController.text.trim(),
      'account_no':             _accountNoController.text.trim(),
      'ifsc_code':              _ifscCodeController.text.trim(),
      'account_type':           _accountType ?? '',
      'amount':                 _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':    razorpayPaymentId,
      'payment_status':         'paid',
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/gst/apply'),
      );
      request.fields['user_id']    = auth.userId.toString();
      request.fields['service_id'] = widget.service['id']?.toString() ?? '300';
      request.fields['form_id']    = widget.preselectedSectionId?.toString() ?? '301';
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
              'TRK-GST-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId = 'TRK-GST-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitGstForm();
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
              'assets/GST top.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F0FF),
                  child: const Center(
                    child: Icon(Icons.business_center_outlined, size: 70, color: primaryPurple),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 940) / 2
        : (screenSize.width > 700 ? 24.0 : 16.0);

    // Dynamic sticky bottom button labels
    String buttonTitle = "Next: Contact Info";
    String buttonSubtitle = "Save and continue";
    IconData buttonIcon = Icons.call_outlined;

    const totalSteps = 5;

    if (_expandedSectionIndex == 0) {
      buttonTitle = "Next: Contact Info";
      buttonIcon = Icons.call_outlined;
    } else if (_expandedSectionIndex == 1) {
      buttonTitle = "Next: Bank Account";
      buttonIcon = Icons.account_balance_outlined;
    } else if (_expandedSectionIndex == 2) {
      buttonTitle = "Next: Upload Documents";
      buttonIcon = Icons.cloud_upload_outlined;
    } else if (_expandedSectionIndex == 3) {
      buttonTitle = "Next: Payment Details";
      buttonIcon = Icons.payment_outlined;
    } else if (_expandedSectionIndex == 4) {
      buttonTitle = "Submit GST Form";
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

                    // Expandable Accordion Stepper Cards
                    _buildAccordionSection(
                      index: 0,
                      title: '1. Personal Information',
                      subtitle: 'Owner details, DOB, Aadhaar & PAN details',
                      leadingIcon: Icons.person_outline,
                      child: _buildPersonalInfoStep(),
                    ),
                    _buildAccordionSection(
                      index: 1,
                      title: '2. Contact Information',
                      subtitle: 'Mobile, email and state delivery details',
                      leadingIcon: Icons.contact_mail_outlined,
                      child: _buildContactInfoStep(),
                    ),
                    _buildAccordionSection(
                      index: 2,
                      title: '3. Account Information',
                      subtitle: 'Bank accounts and IFSC code details',
                      leadingIcon: Icons.account_balance_outlined,
                      child: _buildAccountInfoStep(),
                    ),
                    _buildAccordionSection(
                      index: 3,
                      title: '4. Upload Required Documents',
                      subtitle: 'Identity proofs and rental agreement proofs',
                      leadingIcon: Icons.cloud_upload_outlined,
                      child: _buildDocumentsStep(),
                    ),
                    _buildAccordionSection(
                      index: 4,
                      title: '5. Payment Details',
                      subtitle: 'Application processing fee and check out details',
                      leadingIcon: Icons.payment_outlined,
                      child: _buildPaymentStep(),
                    ),
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
                  onTap: () {
                    if (_expandedSectionIndex < totalSteps - 1) {
                      setState(() {
                        _expandedSectionIndex++;
                      });
                    } else {
                      _submitGstForm();
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
                          child: Icon(buttonIcon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                buttonTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                buttonSubtitle,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField('Applicant Category *', _applicantCategory, _applicantCategories, (v) => setState(() => _applicantCategory = v), prefixIcon: Icons.category_outlined, hint: 'Select Category'),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          context,
          _buildInput('Applicant Full Name *', _applicantNameController, placeholder: 'Enter full name', prefixIcon: Icons.person_outline),
          _buildInput('Father Full Name *', _applicantFatherController, placeholder: 'Enter father full name', prefixIcon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        _buildInput('Residential Address *', _applicantAddressController, placeholder: 'Enter your residential address', prefixIcon: Icons.home_outlined),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          context,
          _buildInput('Aadhaar Number *', _aadhaarNoController, isNum: true, placeholder: '12-digit Aadhaar No.', prefixIcon: Icons.badge_outlined),
          _buildInput('PAN Number *', _panNoController, placeholder: '10-digit PAN No.', prefixIcon: Icons.credit_card_outlined),
        ),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          context,
          _buildDateField('Date of Birth / Establishment *', _dobEstablishmentController),
          _buildInput('Business Address *', _businessAddressController, placeholder: 'Enter your business address', prefixIcon: Icons.business_center_outlined),
        ),
        const SizedBox(height: 14),

        _buildInput('Service / Product Description *', _serviceProductController, placeholder: 'E.g., Retail Sales, Consulting Services', prefixIcon: Icons.work_outline),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveRow(
          context,
          _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: '10-digit mobile number', prefixIcon: Icons.phone_iphone_outlined),
          _buildInput('Email ID *', _emailIdController, placeholder: 'E.g., info@yourdomain.com', prefixIcon: Icons.mail_outline),
        ),
        const SizedBox(height: 14),

        _statesLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: primaryPurple)))
            : _buildDropdownField('Delivery State *', _deliveryState, _deliveryStates, (v) => setState(() => _deliveryState = v), prefixIcon: Icons.map_outlined, hint: 'Select State'),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveRow(
          context,
          _buildInput('Bank Name *', _bankNameController, placeholder: 'E.g., State Bank of India', prefixIcon: Icons.account_balance_outlined),
          _buildInput('Bank Account Number *', _accountNoController, isNum: true, placeholder: 'Enter Account Number', prefixIcon: Icons.numbers_outlined),
        ),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          context,
          _buildInput('IFSC Code *', _ifscCodeController, placeholder: 'Enter 11-digit IFSC code', prefixIcon: Icons.code_rounded),
          _buildDropdownField('Account Type *', _accountType, _accountTypes, (v) => setState(() => _accountType = v), prefixIcon: Icons.playlist_add_check_outlined, hint: 'Select Account Type'),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Container(
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
              final reqKeys = ['doc_cheque', 'doc_aadhaar', 'doc_pan', 'doc_photo', 'doc_rental', 'doc_electricity'];
              final firstEmpty = reqKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => reqKeys.first);
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

          _buildDocUploadCard('Cancel Cheque /Bank Statement *', 'doc_cheque'),
          _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
          _buildDocUploadCard('PAN Card *', 'doc_pan'),
          _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
          _buildDocUploadCard('Rental Agreement(English Version) *', 'doc_rental'),
          _buildDocUploadCard('Electricity Bill (Updated) *', 'doc_electricity'),
        ],
      ),
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
                        const [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              docKey.contains('photo') ? Icons.person : 
              docKey.contains('aadhaar') ? Icons.credit_card :
              Icons.assignment_outlined, 
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GST Registration',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading),
                    ),
                    SizedBox(height: 2),
                    Text(
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
                decoration: const BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textDarkHeading),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your GST Registration request has been received successfully.',
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
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

  Widget _buildDateField(String label, TextEditingController controller) {
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
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: primaryPurple,
                      onPrimary: Colors.white,
                      onSurface: textDarkHeading,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                controller.text = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              });
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20, color: primaryPurple),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                fillColor: const Color(0xFFFAFAFA),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
              ),
              validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? hint,
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
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))) : null,
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
              const Text('Please login to submit your GST application.', style: TextStyle(color: textSubdued, fontSize: 12.5)),
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
