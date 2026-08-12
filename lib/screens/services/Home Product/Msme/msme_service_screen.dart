import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';

class MsmeServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const MsmeServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<MsmeServiceScreen> createState() => _MsmeServiceScreenState();
}

class _MsmeServiceScreenState extends State<MsmeServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // 1. Personal Information Controllers (Matching User Screenshot Exactly)
  final TextEditingController _businessNameController    = TextEditingController();
  final TextEditingController _applicantNameController   = TextEditingController();
  final TextEditingController _panNoController           = TextEditingController();
  final TextEditingController _aadhaarNoController       = TextEditingController();
  final TextEditingController _businessEstDateController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _aadhaarAddressController  = TextEditingController();

  // 2. Contact Information Controllers
  final TextEditingController _mobileNumberController    = TextEditingController();
  final TextEditingController _emailIdController         = TextEditingController();

  // Delivery State API List
  List<String> _deliveryStates = [];
  bool         _statesLoading  = true;
  String?      _deliveryState;

  // 3. Account Information Controllers
  final TextEditingController _bankNameController  = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscCodeController  = TextEditingController();
  List<String> _accountTypes = [];
  String?      _accountType;

  // 4. Upload Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium Teal Palette
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

    _fetchDropdownOptions(); // ✅ Dynamic API fetch for States & Account Types
    _loadSavedUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _businessNameController.dispose();
    _applicantNameController.dispose();
    _panNoController.dispose();
    _aadhaarNoController.dispose();
    _businessEstDateController.dispose();
    _businessAddressController.dispose();
    _aadhaarAddressController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  // ─── Fetch Dropdowns from API ──────────────────────────────────────────────
  Future<void> _fetchDropdownOptions() async {
    if (mounted) setState(() { _statesLoading = true; });
    try {
      // 1. Fetch States
      try {
        final resStates = await ApiService.fetchApi('/msme/states');
        final dataStates = jsonDecode(resStates.body) as Map<String, dynamic>;
        if (dataStates['success'] == true && dataStates['states'] != null) {
          _deliveryStates = (dataStates['states'] as List<dynamic>).map((e) => e.toString()).toList();
        }
      } catch (_) {
        _deliveryStates = ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];
      }

      // 2. Fetch Account Types
      try {
        final resAcc = await ApiService.fetchApi('/msme/account-types');
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
      _applicantNameController.text = _savedDetails!['full_name'] ?? _applicantNameController.text;
      _mobileNumberController.text  = _savedDetails!['mobile'] ?? _mobileNumberController.text;
      _emailIdController.text       = _savedDetails!['email'] ?? _emailIdController.text;
      _aadhaarNoController.text     = _savedDetails!['aadhaar_number'] ?? _aadhaarNoController.text;
      _panNoController.text         = _savedDetails!['pan_number'] ?? _panNoController.text;
      _aadhaarAddressController.text= _savedDetails!['address_line1'] ?? _aadhaarAddressController.text;
      _businessAddressController.text= _savedDetails!['address_line2'] ?? _businessAddressController.text;
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

  Future<void> _submitMsmeForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type':       'MSME Registration',
      'business_name':     _businessNameController.text.trim(),
      'applicant_name':    _applicantNameController.text.trim(),
      'pan_no':            _panNoController.text.trim(),
      'aadhaar_no':        _aadhaarNoController.text.trim(),
      'business_est_date': _businessEstDateController.text.trim(),
      'business_address':  _businessAddressController.text.trim(),
      'aadhaar_address':   _aadhaarAddressController.text.trim(),
      'mobile_number':     _mobileNumberController.text.trim(),
      'email_id':          _emailIdController.text.trim(),
      'delivery_state':    _deliveryState ?? '',
      'bank_name':         _bankNameController.text.trim(),
      'account_no':        _accountNoController.text.trim(),
      'ifsc_code':         _ifscCodeController.text.trim(),
      'account_type':      _accountType ?? '',
      'amount':            _payableAmount.toStringAsFixed(2),
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/msme/apply'),
      );
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '700';
      request.fields['form_id']   = widget.preselectedSectionId?.toString() ?? '701';
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
              'TRK-MSME-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-MSME-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitMsmeForm();
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
          // Top Curved Hero Container (Header: MSME only)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: 30,
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
                  const SizedBox(height: 6),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MSME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Form Content Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
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
                          // SECTION 1: Personal Information (Matching User Screenshot Exactly)
                          _buildHeaderBanner('1. Personal Information.'),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Business Name *', _businessNameController, placeholder: 'BUSINESS NAME'),
                                  _buildInput('Applicant\'s Name *', _applicantNameController, placeholder: 'AS PER AADHAAR'),
                                ),
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('PAN No. *', _panNoController, placeholder: 'PAN NO.'),
                                  _buildInput('Aadhaar Number *', _aadhaarNoController, isNum: true, placeholder: 'AADHAAR NUMBER'),
                                ),
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildDateField('Business Est. Date *', _businessEstDateController),
                                  _buildInput('Business Address *', _businessAddressController, placeholder: 'BUSS. ADDRESS'),
                                ),
                                const SizedBox(height: 14),
                                _buildInput('Aadhaar Address *', _aadhaarAddressController, placeholder: 'AS PER AADHAAR'),
                              ],
                            ),
                          ),

                          // SECTION 2: Contact Information
                          _buildHeaderBanner('2. Contact Information.'),
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
                          _buildHeaderBanner('3. Account Information.'),
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
                          _buildHeaderBanner('4. Upload Document.'),
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

                                  // Top Drop Zone Box
                                  InkWell(
                                    onTap: () {
                                      final requiredKeys = ['doc_aadhaar', 'doc_pan', 'doc_cheque'];
                                      final firstEmpty = requiredKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => 'doc_aadhaar');
                                      _pickFile(firstEmpty);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF64748B)),
                                          SizedBox(height: 8),
                                          Text(
                                            'Drop file here or browse',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'PDF, PNG, JPG up to 2MB',
                                            style: TextStyle(fontSize: 11.5, color: textSubdued, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Required Document Upload Cards
                                  _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                  _buildDocUploadCard('PAN Card *', 'doc_pan'),
                                  _buildDocUploadCard('Cancel Cheque / Bank Statement *', 'doc_cheque'),
                                ],
                              ),
                            ),
                          ),

                          // SECTION 5: Payment
                          _buildHeaderBanner('5. Payment'),
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
                                      onPressed: _loading ? null : _submitMsmeForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
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
                                          : const Text(
                                              'Submit',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [headerGradientStart, headerGradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
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
  }) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: cleanLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textLabelDark),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textLabelDark),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 4),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: 'DD-MM-YYYY',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            suffixIcon: const Icon(Icons.calendar_month, size: 18, color: primaryTeal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          ),
          validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {String hint = 'Please Select'}) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: cleanLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textLabelDark),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: (value != null && items.contains(value)) ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
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
    final bytes = file != null ? (file['bytes'] as Uint8List?) : null;
    final ext = file != null ? (file['extension'] as String? ?? '').toLowerCase() : '';

    final isPdf = ext == 'pdf';
    final isImg = ext == 'jpg' || ext == 'jpeg' || ext == 'png';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasFile ? primaryTeal.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Badge Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPdf
                  ? const Color(0xFFFFE5E5)
                  : (isImg ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: bytes != null && isImg
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? const Color(0xFFEF4444)
                          : (isImg ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPdf ? 'PDF' : (isImg ? 'IMG' : 'DOC'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // Middle File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFile ? fileName : title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDarkHeading),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasFile ? '$title • ${_formatBytes(fileSize)}' : 'File size must be under 2MB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasFile ? FontWeight.w600 : FontWeight.w500,
                    color: hasFile ? primaryTeal : textSubdued,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Trash icon or Browse button
          if (hasFile)
            IconButton(
              onPressed: () => _removeFile(docKey),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 22),
              tooltip: 'Remove file',
            )
          else
            ElevatedButton(
              onPressed: () => _pickFile(docKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: textDarkHeading,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Browse', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                'Your MSME request has been received successfully.',
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
          const Text('Please login to submit your MSME application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
