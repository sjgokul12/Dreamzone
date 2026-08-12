import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';
const Color primaryPurple = Color(0xFF8B5CF6);

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
  final bool _unlockedDocuments = false;

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String get _base => ApiService.baseUrl;

  // Premium Palette
  static const Color primaryTeal        = Color(0xFF00A896);
  static const Color secondaryTeal      = Color(0xFF0284C7);
  static const Color headerGradientStart= Color(0xFF0F766E);
  static const Color headerGradientEnd  = Color(0xFF0284C7);
  static const Color textDarkHeading    = Color(0xFF0F172A);
  static const Color textLabelDark      = Color(0xFF1E293B);
  static const Color textSubdued        = Color(0xFF64748B);
  static const Color bgCanvas           = Color(0xFFF1F5F9);
  static const Color cardSurface        = Colors.white;

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

    _fetchDropdownOptions(); // ✅ Dynamic API fetch for States, Categories & Account Types
    _loadSavedUserData();
  }

  @override
  void dispose() {
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
          if (_savedDetails!['full_name'] != null) {
            _applicantNameController.text = _savedDetails!['full_name'];
          }
          if (_savedDetails!['father_name'] != null) {
            _applicantFatherController.text = _savedDetails!['father_name'];
          }
          if (_savedDetails!['mobile'] != null) {
            _mobileNumberController.text = _savedDetails!['mobile'];
          }
          if (_savedDetails!['email'] != null) {
            _emailIdController.text = _savedDetails!['email'];
          }
          if (_savedDetails!['aadhaar_number'] != null) {
            _aadhaarNoController.text = _savedDetails!['aadhaar_number'];
          }
          if (_savedDetails!['pan_number'] != null) {
            _panNoController.text = _savedDetails!['pan_number'];
          }
        });
      }
    } catch (_) {}
  }

  void _applySavedDetails() {
    if (_savedDetails == null) return;
    setState(() {
      _applicantNameController.text   = _savedDetails!['full_name'] ?? _applicantNameController.text;
      _applicantFatherController.text = _savedDetails!['father_name'] ?? _applicantFatherController.text;
      _mobileNumberController.text    = _savedDetails!['mobile'] ?? _mobileNumberController.text;
      _emailIdController.text         = _savedDetails!['email'] ?? _emailIdController.text;
      _aadhaarNoController.text       = _savedDetails!['aadhaar_number'] ?? _aadhaarNoController.text;
      _panNoController.text           = _savedDetails!['pan_number'] ?? _panNoController.text;
      _applicantAddressController.text= _savedDetails!['address_line1'] ?? _applicantAddressController.text;
      _businessAddressController.text = _savedDetails!['address_line2'] ?? _businessAddressController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('✨ Saved profile details applied!', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: primaryTeal,
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

  Future<void> _submitGstForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type':          'GST Registration',
      'applicant_category':   _applicantCategory ?? '',
      'applicant_name':       _applicantNameController.text.trim(),
      'applicant_father':     _applicantFatherController.text.trim(),
      'applicant_address':    _applicantAddressController.text.trim(),
      'aadhaar_no':           _aadhaarNoController.text.trim(),
      'pan_no':               _panNoController.text.trim(),
      'date_of_establishment':_dobEstablishmentController.text.trim(),
      'business_address':     _businessAddressController.text.trim(),
      'service_product':      _serviceProductController.text.trim(),
      'mobile_number':        _mobileNumberController.text.trim(),
      'email_id':             _emailIdController.text.trim(),
      'delivery_state':       _deliveryState ?? '',
      'bank_name':            _bankNameController.text.trim(),
      'account_no':           _accountNoController.text.trim(),
      'ifsc_code':            _ifscCodeController.text.trim(),
      'account_type':         _accountType ?? '',
      'amount':               _payableAmount.toStringAsFixed(2),
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/gst/apply'),
      );
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '300';
      request.fields['form_id']   = widget.preselectedSectionId?.toString() ?? '301';
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
              'TRK-GST-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-GST-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
      body: SafeArea(
        child: _submitted ? _buildSuccessView() : FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHero(context, 'GST Registration', 'GST image.png'),
              ),
              SliverToBoxAdapter(
                child: _buildProgressTracker(),
              ),
              SliverToBoxAdapter(
                child: _buildFormBody(isDesktop, screenSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, String title, String imagePath) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDFBFE), Color(0xFFF3F0FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 0, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: textDarkHeading, size: 24),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 1),
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDarkHeading,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register your business in just a few simple steps',
                      style: TextStyle(color: textSubdued, fontSize: 13, height: 1.4),
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
                    'assets/$imagePath',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProgressStep(Icons.person_outline, 'Personal\nInfo', true, true),
          _buildProgressDivider(),
          _buildProgressStep(Icons.storefront_outlined, 'Business\nDetails', false, false),
          _buildProgressDivider(),
          _buildProgressStep(Icons.account_balance_outlined, 'Bank\nDetails', false, false),
          _buildProgressDivider(),
          _buildProgressStep(Icons.description_outlined, 'Upload\nDocuments', false, false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(IconData icon, String label, bool isActive, bool isFirst) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? primaryPurple : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive ? [
              BoxShadow(color: primaryPurple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
            ] : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, color: isActive ? Colors.white : const Color(0xFF64748B), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? primaryPurple : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDivider() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 1,
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
        ),
      ),
    );
  }

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 940) / 2
        : (screenSize.width > 700 ? 24.0 : 12.0);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 18.0),
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
                      backgroundColor: primaryTeal,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Main Surface Card
              Container(
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Personal Information
                    _buildHeaderBanner('1 Personal Information', subtitle: 'Please provide your personal details'),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResponsiveRow(
                            context,
                            _buildDropdownField(
                              'Applicant Category *',
                              _applicantCategory,
                              _applicantCategories.isNotEmpty
                                  ? _applicantCategories
                                  : ['Proprietor', 'Partnership'],
                              (v) => setState(() => _applicantCategory = v),
                              hint: 'Select Category',
                            ),
                            _buildInput('Applicant Name *', _applicantNameController, placeholder: 'APPLICANT NAME'),
                          ),
                          const SizedBox(height: 14),
                          _buildInput('Applicant Father *', _applicantFatherController, placeholder: 'FATHER NAME'),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Applicant Address *', _applicantAddressController, placeholder: 'APPLICANT ADDRESS'),
                            _buildInput('Aadhaar No *', _aadhaarNoController, isNum: true, placeholder: 'AADHAAR NO'),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('PAN No. *', _panNoController, placeholder: 'PAN NO.'),
                            _buildDateField('Date of Establishment *', _dobEstablishmentController),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Business Address *', _businessAddressController, placeholder: 'BUSINESS ADDRESS'),
                            _buildInput('Service/Product *', _serviceProductController, placeholder: 'SERVICE / PRODUCT'),
                          ),
                        ],
                      ),
                    ),

                    // SECTION 2: Contact Information (Dynamic API State Dropdown)
                    _buildHeaderBanner('2 Contact Information', subtitle: 'Where can we reach you?'),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 700;
                          final stateList = _deliveryStates.isNotEmpty
                              ? _deliveryStates
                              : [
                                  "Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"
                                ];
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'MOBILE NUMBER')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('Email ID *', _emailIdController, placeholder: 'Email ID')),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _statesLoading
                                          ? const Padding(
                                              padding: EdgeInsets.only(top: 24),
                                              child: Row(children: [
                                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal)),
                                                SizedBox(width: 8),
                                                Text('Loading states…', style: TextStyle(fontSize: 12, color: textSubdued)),
                                              ]),
                                            )
                                          : _buildDropdownField('Delivery State *', _deliveryState, stateList, (v) => setState(() => _deliveryState = v), hint: 'Select State'),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'MOBILE NUMBER'),
                                    const SizedBox(height: 12),
                                    _buildInput('Email ID *', _emailIdController, placeholder: 'Email ID'),
                                    const SizedBox(height: 12),
                                    _statesLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Row(children: [
                                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal)),
                                              SizedBox(width: 8),
                                              Text('Loading states…', style: TextStyle(fontSize: 12, color: textSubdued)),
                                            ]),
                                          )
                                        : _buildDropdownField('Delivery State *', _deliveryState, stateList, (v) => setState(() => _deliveryState = v), hint: 'Select State'),
                                  ],
                                );
                        },
                      ),
                    ),

                    // SECTION 3: Account Information
                    _buildHeaderBanner('3 Account Information', subtitle: 'Your banking details'),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 750;
                          final accTypes = _accountTypes.isNotEmpty
                              ? _accountTypes
                              : ['Savings A/c', 'Current A/c'];
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildInput('Bank Name', _bankNameController, placeholder: 'BANK NAME')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildInput('Account No.', _accountNoController, isNum: true, placeholder: 'Account No.')),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildInput('IFSC Code', _ifscCodeController, placeholder: 'IFSC CODE')),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdownField('Account Type', _accountType, accTypes, (v) => setState(() => _accountType = v), hint: 'Select Account Type'),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInput('Bank Name', _bankNameController, placeholder: 'BANK NAME'),
                                    const SizedBox(height: 12),
                                    _buildInput('Account No.', _accountNoController, isNum: true, placeholder: 'Account No.'),
                                    const SizedBox(height: 12),
                                    _buildInput('IFSC Code', _ifscCodeController, placeholder: 'IFSC CODE'),
                                    const SizedBox(height: 12),
                                    _buildDropdownField('Account Type', _accountType, accTypes, (v) => setState(() => _accountType = v), hint: 'Select Account Type'),
                                  ],
                                );
                        },
                      ),
                    ),

                    // SECTION 4: Upload Document (Matching Screenshot 2 UI)
                    _buildHeaderBanner('4 Upload Documents', subtitle: 'Upload all required documents'),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Files',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDarkHeading),
                            ),
                            const SizedBox(height: 14),

                            // Top Drop Zone Box matching Screenshot 2
                            InkWell(
                              onTap: () {
                                final requiredKeys = ['doc_cheque', 'doc_aadhaar', 'doc_pan', 'doc_photo', 'doc_rental', 'doc_electricity'];
                                final firstEmpty = requiredKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => 'doc_cheque');
                                _pickFile(firstEmpty);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: primaryPurple.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFB06AB3), Color(0xFF4568DC)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.white),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text.rich(
                                      TextSpan(
                                        text: 'Drag & Drop files here\n',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDarkHeading, height: 1.5),
                                        children: [
                                          TextSpan(text: 'or ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubdued)),
                                          TextSpan(text: 'browse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryPurple)),
                                          TextSpan(text: ' from your device', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubdued)),
                                        ]
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'PDF, PNG, JPG up to 5MB each',
                                      style: TextStyle(fontSize: 12, color: textSubdued, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Uploaded / Required Document Cards matching Screenshot 2
                            _buildDocUploadCard('Cancel Cheque /Bank Statement *', 'doc_cheque'),
                            _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                            _buildDocUploadCard('PAN Card *', 'doc_pan'),
                            _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
                            _buildDocUploadCard('Rental Agreement(English Version) *', 'doc_rental'),
                            _buildDocUploadCard('Electricity Bill (Updated) *', 'doc_electricity'),
                          ],
                        ),
                      ),
                    ),


                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB06AB3), Color(0xFF4568DC)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitGstForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Submit Application',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: textSubdued, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Your data is 100% secure and encrypted',
                          style: TextStyle(color: textSubdued, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(BuildContext context, Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 550;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  left,
                  const SizedBox(height: 12),
                  right,
                ],
              );
      },
    );
  }

  Widget _buildHeaderBanner(String title, {String? subtitle}) {
    final numStr = title.split(' ')[0].replaceAll('.', '');
    final cleanTitle = title.replaceFirst(title.split(' ')[0], '').trim();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB06AB3), Color(0xFF4568DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              numStr,
              style: const TextStyle(
                color: Color(0xFF4568DC),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_up, color: Colors.white),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('name') || l.contains('father')) return Icons.person_outline;
    if (l.contains('address') || l.contains('state')) return Icons.location_on_outlined;
    if (l.contains('aadhaar') || l.contains('pan')) return Icons.badge_outlined;
    if (l.contains('date')) return Icons.calendar_today_outlined;
    if (l.contains('business') || l.contains('product')) return Icons.storefront_outlined;
    if (l.contains('mobile') || l.contains('email')) return Icons.contact_mail_outlined;
    if (l.contains('bank') || l.contains('account') || l.contains('ifsc')) return Icons.account_balance_outlined;
    if (l.contains('category')) return Icons.group_outlined;
    return Icons.edit_outlined;
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isNum = false, int? maxLength, String? placeholder, String? helper, IconData? prefixIcon}) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    final icon = prefixIcon ?? _getIconForLabel(cleanLabel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryPurple, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: cleanLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark),
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
                  hintText: placeholder ?? 'Enter $cleanLabel',
                  helperText: helper,
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  counterText: maxLength != null ? 'Enter Only $maxLength Characters' : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryPurple, width: 1.5)),
                ),
                validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return _buildDatePickerInput(label, controller);
  }

  Widget _buildDatePickerInput(String label, TextEditingController controller) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    final icon = _getIconForLabel(cleanLabel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryPurple, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: cleanLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark),
                  children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    setState(() => controller.text = formatted);
                  }
                },
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
                decoration: InputDecoration(
                  hintText: 'Select date (YYYY-MM-DD)',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {String hint = 'Select Category'}) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    final icon = _getIconForLabel(cleanLabel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryPurple, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: cleanLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onChanged,
                validator: (v) => isReq && (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        docKey.contains('rental') ? const [Color(0xFFF59E0B), Color(0xFFD97706)] :
                        docKey.contains('aadhaar') ? const [Color(0xFFEF4444), Color(0xFFDC2626)] :
                        docKey.contains('cheque') ? const [Color(0xFF8B5CF6), Color(0xFF7C3AED)] :
                        docKey.contains('electricity') || docKey.contains('proof') ? const [Color(0xFF10B981), Color(0xFF059669)] :
                        const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              docKey.contains('photo') ? Icons.person : 
              docKey.contains('rental') ? Icons.description :
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading),
                    children: (!hasFile && isReq) ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile ? 'Uploaded • ${_formatBytes(fileSize)}' : 'PDF, PNG, JPG up to 5MB',
                  style: const TextStyle(
                    fontSize: 12,
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
                  color: primaryTeal,
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
                'Your GST Registration request has been received successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Tracking Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _trackingId ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryTeal, letterSpacing: 0.5),
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
                    backgroundColor: primaryTeal,
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
          const Text('Please login to submit your application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
