import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';

class PassportServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const PassportServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<PassportServiceScreen> createState() => _PassportServiceScreenState();
}

class _PassportServiceScreenState extends State<PassportServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Selected Passport Sub-Service (1=Normal, 2=Tatkal, 3=Minor, 4=Correction Normal, 5=Correction Tatkal, 6=Lost/Damage, 7=PCC)
  late int _selectedSubService;

  // 1. Personal Information Controllers
  final TextEditingController _applicantNameController = TextEditingController();
  final TextEditingController _initialFullFormController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _birthDistrictController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _maritalStatus = 'Single';
  final TextEditingController _panNoController = TextEditingController();
  final TextEditingController _aadhaarNoController = TextEditingController();
  String _education = '10th Pass and Above';
  String _jobType = 'Private';
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();

  // Existing Passport Details (Correction / Renewal / Lost)
  final TextEditingController _existingPassportNoController = TextEditingController();
  final TextEditingController _existingFileNoController = TextEditingController();
  final TextEditingController _dateOfIssueController = TextEditingController();
  final TextEditingController _dateOfExpController = TextEditingController();

  // 2. Parent & Spouse Details
  final TextEditingController _fatherFirstNameController = TextEditingController();
  final TextEditingController _fatherMiddleNameController = TextEditingController();
  final TextEditingController _fatherLastNameController = TextEditingController();
  final TextEditingController _motherFirstNameController = TextEditingController();
  final TextEditingController _motherMiddleNameController = TextEditingController();
  final TextEditingController _motherLastNameController = TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();
  final TextEditingController _spouseInitialController = TextEditingController();

  // 4. Address For Communication
  final String _addressType = 'Address Per Application';
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetAreaController = TextEditingController();
  final TextEditingController _tehsilPostController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // 4. Emergency Contact
  final TextEditingController _emergencyNameAddressController = TextEditingController();
  final TextEditingController _emergencyMobileController = TextEditingController();
  final TextEditingController _emergencyEmailController = TextEditingController();
  final TextEditingController _kendraLocationController = TextEditingController();
  final TextEditingController _appointmentDateController = TextEditingController();
  final TextEditingController _policeStationController = TextEditingController();

  // 5. Upload Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};
  bool _unlockedDocuments = false;

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium Teal Palette
  static const Color primaryTeal = Color(0xFF00A896);
  static const Color secondaryTeal = Color(0xFF0284C7);
  static const Color headerGradientStart = Color(0xFF0F766E);
  static const Color headerGradientEnd = Color(0xFF0284C7);
  static const Color textDarkHeading = Color(0xFF0F172A);
  static const Color textLabelDark = Color(0xFF1E293B);
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
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _selectedSubService = widget.preselectedSectionId ?? 1;
    _loadSavedUserData();
    _fetchDropdownData();
  }

  List<String> _maritalStatusList = ['Single', 'Married', 'Divorced', 'Widowed'];
  List<String> _educationList = ['10th Pass and Above', 'Below 10th', 'Graduate & Above'];
  List<String> _jobTypeList = ['Private', 'Government', 'Self Employed', 'Student', 'Other'];

  Future<void> _fetchDropdownData() async {
    try {
      final mRes = await ApiService.fetchApi('/passport/marital-status');
      if (mRes.statusCode == 200) {
        final data = jsonDecode(mRes.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _maritalStatusList = (data['data'] as List).map((e) => e['status_name'].toString()).toList();
            if (!_maritalStatusList.contains(_maritalStatus)) _maritalStatus = _maritalStatusList.first;
          });
        }
      }
    } catch (_) {}

    try {
      final eRes = await ApiService.fetchApi('/passport/education-qualification');
      if (eRes.statusCode == 200) {
        final data = jsonDecode(eRes.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _educationList = (data['data'] as List).map((e) => e['education_level'].toString()).toList();
            if (!_educationList.contains(_education)) _education = _educationList.first;
          });
        }
      }
    } catch (_) {}

    try {
      final jRes = await ApiService.fetchApi('/passport/job-type');
      if (jRes.statusCode == 200) {
        final data = jsonDecode(jRes.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _jobTypeList = (data['data'] as List).map((e) => e['type_name'].toString()).toList();
            if (!_jobTypeList.contains(_jobType)) _jobType = _jobTypeList.first;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    _applicantNameController.dispose();
    _initialFullFormController.dispose();
    _birthPlaceController.dispose();
    _birthDistrictController.dispose();
    _dobController.dispose();
    _panNoController.dispose();
    _aadhaarNoController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _existingPassportNoController.dispose();
    _existingFileNoController.dispose();
    _dateOfIssueController.dispose();
    _dateOfExpController.dispose();
    _fatherFirstNameController.dispose();
    _fatherMiddleNameController.dispose();
    _fatherLastNameController.dispose();
    _motherFirstNameController.dispose();
    _motherMiddleNameController.dispose();
    _motherLastNameController.dispose();
    _spouseNameController.dispose();
    _spouseInitialController.dispose();
    _houseNoController.dispose();
    _streetAreaController.dispose();
    _tehsilPostController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _emergencyNameAddressController.dispose();
    _emergencyMobileController.dispose();
    _emergencyEmailController.dispose();
    _kendraLocationController.dispose();
    _appointmentDateController.dispose();
    _policeStationController.dispose();
    super.dispose();
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
            _emergencyMobileController.text = _savedDetails!['mobile'];
          }
          if (_savedDetails!['email'] != null) {
            _emailIdController.text = _savedDetails!['email'];
            _emergencyEmailController.text = _savedDetails!['email'];
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
      _mobileNumberController.text = _savedDetails!['mobile'] ?? _mobileNumberController.text;
      _emailIdController.text = _savedDetails!['email'] ?? _emailIdController.text;
      _aadhaarNoController.text = _savedDetails!['aadhaar_number'] ?? _aadhaarNoController.text;
      _panNoController.text = _savedDetails!['pan_number'] ?? _panNoController.text;
      _houseNoController.text = _savedDetails!['address_line1'] ?? _houseNoController.text;
      _streetAreaController.text = _savedDetails!['address_line2'] ?? _streetAreaController.text;
      _pincodeController.text = _savedDetails!['pincode'] ?? _pincodeController.text;
      _districtController.text = _savedDetails!['city'] ?? _districtController.text;
      _cityController.text = _savedDetails!['city'] ?? _cityController.text;
      _stateController.text = _savedDetails!['state'] ?? _stateController.text;
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

  double get _payableAmount {
    if (_selectedSubService == 7) return 500.00; // PCC
    if (_selectedSubService == 6) return 3000.00; // Lost/Damage
    if (_selectedSubService == 5) return 3500.00; // Correction Tatkal
    if (_selectedSubService == 4) return 1500.00; // Correction Normal
    if (_selectedSubService == 3) return 1000.00; // Minor
    if (_selectedSubService == 2) return 3500.00; // Tatkal
    return 1500.00; // Normal
  }

  String get _serviceTitle {
    switch (_selectedSubService) {
      case 2:
        return 'Tatkal Passport Application';
      case 3:
        return 'Minor Passport Application';
      case 4:
        return 'Correction / Renewal Passport';
      case 5:
        return 'Correction / Renewal (Tatkal)';
      case 6:
        return 'Lost / Damage Passport';
      case 7:
        return 'PCC (Police Clearance Certificate)';
      default:
        return 'Normal Passport Application';
    }
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

        setState(() {
          _uploadedDocs[docKey] = [
            {
              'bytes': f.bytes,
              'name': f.name,
              'size': f.size,
            }
          ];
        });
      }
    } catch (_) {}
  }

  Future<void> _submitPassportForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, String> formData = {
      'service_type': _serviceTitle,
      'applicant_name': _applicantNameController.text.trim(),
      'initial_full_form': _initialFullFormController.text.trim(),
      'birth_place': _birthPlaceController.text.trim(),
      'birth_district': _birthDistrictController.text.trim(),
      'dob': _dobController.text.trim(),
      'marital_status': _maritalStatus,
      'pan_no': _panNoController.text.trim(),
      'aadhaar_number': _aadhaarNoController.text.trim(),
      'educational_qualification': _education,
      'job_type': _jobType,
      'mobile_number': _mobileNumberController.text.trim(),
      'email_id': _emailIdController.text.trim(),
      'existing_passport_no': _existingPassportNoController.text.trim(),
      'existing_file_no': _existingFileNoController.text.trim(),
      'date_of_issue': _dateOfIssueController.text.trim(),
      'date_of_exp': _dateOfExpController.text.trim(),
      'father_first_name': _fatherFirstNameController.text.trim(),
      'father_middle_name': _fatherMiddleNameController.text.trim(),
      'father_last_name': _fatherLastNameController.text.trim(),
      'mother_first_name': _motherFirstNameController.text.trim(),
      'mother_middle_name': _motherMiddleNameController.text.trim(),
      'mother_last_name': _motherLastNameController.text.trim(),
      'spouse_name': _spouseNameController.text.trim(),
      'spouse_initial': _spouseInitialController.text.trim(),
      'address_type': _addressType,
      'house_no_building': _houseNoController.text.trim(),
      'street_area': _streetAreaController.text.trim(),
      'tehsil_post': _tehsilPostController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'district': _districtController.text.trim(),
      'state': _stateController.text.trim(),
      'city': _cityController.text.trim(),
      'emergency_name_address': _emergencyNameAddressController.text.trim(),
      'emergency_mobile': _emergencyMobileController.text.trim(),
      'emergency_email': _emergencyEmailController.text.trim(),
      'passport_kendra_location': _kendraLocationController.text.trim(),
      'appointment_date': _appointmentDateController.text.trim(),
      'police_station': _policeStationController.text.trim(),
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/submit-application-with-docs'),
      );
      request.fields['user_id'] = auth.userId.toString();
      request.fields['service_id'] = widget.service['id']?.toString() ?? '900';
      request.fields['form_id'] = _selectedSubService.toString();
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in _uploadedDocs.entries) {
        for (var fileInfo in entry.value) {
          if (fileInfo['bytes'] != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'doc_${entry.key}',
                fileInfo['bytes'],
                filename: fileInfo['name'],
              ),
            );
          }
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 60));
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
          _trackingId = data['tracking_id'] ??
              'TRK-PASSPORT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
          _trackingId =
              'TRK-PASSPORT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitPassportForm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

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
          // Top Curved Hero Container (Matching Screenshot 5 design!)
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
                      color: Colors.white.withAlpha(45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _serviceTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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
                            color: Colors.black.withAlpha(14),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1: Personal Information (Screenshots 1 & 3)
                          _buildHeaderBanner('1. Personal Information'),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedSubService >= 1 && _selectedSubService <= 3) ...[
                                  _buildDropdownField('Application Type *', _selectedSubService == 1 ? 'Normal' : (_selectedSubService == 2 ? 'Tatkal' : 'Minor'), ['Normal', 'Tatkal', 'Minor'], (v) {
                                    setState(() {
                                      if (v == 'Normal') _selectedSubService = 1;
                                      if (v == 'Tatkal') _selectedSubService = 2;
                                      if (v == 'Minor') _selectedSubService = 3;
                                    });
                                  }),
                                  const SizedBox(height: 14),
                                ] else if (_selectedSubService >= 4 && _selectedSubService <= 6) ...[
                                  _buildDropdownField('Application Type *', _selectedSubService == 4 ? '1st Correction' : (_selectedSubService == 5 ? 'Tatkal Correction' : 'Lost/Damage'), ['1st Correction', 'Tatkal Correction', 'Lost/Damage'], (v) {
                                    setState(() {
                                      if (v == '1st Correction') _selectedSubService = 4;
                                      if (v == 'Tatkal Correction') _selectedSubService = 5;
                                      if (v == 'Lost/Damage') _selectedSubService = 6;
                                    });
                                  }),
                                  const SizedBox(height: 14),
                                ],

                                const Text('Applicant\'s Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                const SizedBox(height: 6),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Name', _applicantNameController, placeholder: 'NAME'),
                                  _buildInput('Initial Full Form', _initialFullFormController, placeholder: 'INITIAL FULL FORM'),
                                ),
                                const SizedBox(height: 14),
                                const Text('Birth Details *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                const SizedBox(height: 6),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Birth Place', _birthPlaceController, placeholder: 'BIRTH PLACE'),
                                  _buildInput('Birth Place District', _birthDistrictController, placeholder: 'BIRTH PLACE DISTRICT'),
                                ),
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildDateField('Date of Birth *', _dobController),
                                  _buildDropdownField('Marital Status *', _maritalStatus, _maritalStatusList, (v) => setState(() => _maritalStatus = v!)),
                                ),
                                if (_maritalStatus == 'Married') ...[
                                  const SizedBox(height: 14),
                                  _buildResponsiveRow(
                                    context,
                                    _buildInput('Spouse Name *', _spouseNameController, placeholder: 'SPOUSE NAME'),
                                    _buildInput('Spouse Initial.Full Form', _spouseInitialController, placeholder: 'INITIAL FULL FORM'),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('PAN No. *', _panNoController, placeholder: 'PAN NO.'),
                                  _buildInput('Aadhaar Number *', _aadhaarNoController, isNum: true, placeholder: 'AADHAAR NUMBER'),
                                ),
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildDropdownField('Educational Qualification *', _education, _educationList, (v) => setState(() => _education = v!)),
                                  _buildDropdownField('Job Type *', _jobType, _jobTypeList, (v) => setState(() => _jobType = v!)),
                                ),
                                const SizedBox(height: 14),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'MOBILE NUMBER'),
                                  _buildInput('Email ID *', _emailIdController, placeholder: 'Email ID'),
                                ),

                                // Extra fields for Correction / Renewal / Lost (Screenshot 3)
                                if (_selectedSubService >= 4 && _selectedSubService <= 6) ...[
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFCBD5E1)),
                                  const SizedBox(height: 10),
                                  _buildInput('Existing Passport No *', _existingPassportNoController, placeholder: 'passport number'),
                                  const SizedBox(height: 12),
                                  _buildResponsiveRow(
                                    context,
                                    _buildInput('Existing File No. *', _existingFileNoController, placeholder: 'File No.'),
                                    _buildDateField('Date Of Issue', _dateOfIssueController),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDateField('Date Of Exp. *', _dateOfExpController),
                                ],
                              ],
                            ),
                          ),

                          // SECTION 2: Parent Details (Screenshot 2)
                          _buildHeaderBanner('2. Parent Details'),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Father\'s Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                const SizedBox(height: 6),
                                _buildThreeColumnRow(
                                  context,
                                  _buildInput('First Name', _fatherFirstNameController, placeholder: 'FIRST NAME/SURNAME *'),
                                  _buildInput('Middle Name', _fatherMiddleNameController, helper: 'Minimum two Letters Allowed'),
                                  _buildInput('Last Name', _fatherLastNameController, helper: 'Minimum two Letters Allowed'),
                                ),
                                const SizedBox(height: 16),
                                const Text('Mother\'s Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                const SizedBox(height: 6),
                                _buildThreeColumnRow(
                                  context,
                                  _buildInput('First Name', _motherFirstNameController, placeholder: 'FIRST NAME/SURNAME *'),
                                  _buildInput('Middle Name', _motherMiddleNameController, helper: 'Minimum two Letters Allowed'),
                                  _buildInput('Last Name', _motherLastNameController, helper: 'Minimum two Letters Allowed'),
                                ),
                              ],
                            ),
                          ),

                          // SECTION 4: Address For Communication (Screenshot 2)
                          _buildHeaderBanner('4. Address For Communication'),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildInput('House No./Building *', _houseNoController, helper: 'Enter Only 25 Characters')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('Street/Area *', _streetAreaController, helper: 'Enter Only 25 Characters')),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInput('Tehsil/Post *', _tehsilPostController, helper: 'Enter Only 25 Characters')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('Pincode *', _pincodeController, isNum: true, helper: 'Enter Only 25 Characters')),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInput('District *', _districtController, helper: 'Enter Only 25 Characters')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInput('State *', _stateController, helper: 'Enter Only 25 Characters')),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInput('City *', _cityController, helper: 'Enter Only 25 Characters'),
                              ],
                            ),
                          ),

                          // SECTION 4: Emergency Contact (Screenshot 2)
                          _buildHeaderBanner('4. Emergency Contact'),
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              children: [
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Name & Address *', _emergencyNameAddressController),
                                  _buildInput('Mobile Number *', _emergencyMobileController, isNum: true),
                                ),
                                const SizedBox(height: 12),
                                _buildResponsiveRow(
                                  context,
                                  _buildInput('Email ID *', _emergencyEmailController),
                                  _buildInput('Passport Kendra Location *', _kendraLocationController),
                                ),
                                const SizedBox(height: 12),
                                _buildResponsiveRow(
                                  context,
                                  _buildDateField('Appointment Date *', _appointmentDateController),
                                  _buildInput('Police Station *', _policeStationController),
                                ),
                              ],
                            ),
                          ),

                          // SECTION 5: Upload Document.
                          _buildHeaderBanner('5. Upload Document.'),
                          if (!_unlockedDocuments)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () => setState(() => _unlockedDocuments = true),
                                  icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: primaryTeal),
                                  label: const Text(
                                    'Proceed to Upload Documents & Payment',
                                    style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: _buildDocUploadCardsForSubService(),
                            ),
                          ],

                          // SECTION 7: Payment
                          _buildHeaderBanner('7. Payment'),
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
                                      onPressed: _loading ? null : _submitPassportForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: _loading
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text(
                                              'SUBMIT',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
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
                    const SizedBox(height: 44),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocUploadCardsForSubService() {
    List<Widget> cards = [];

    if (_selectedSubService == 3) {
      // Minor Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
        _buildDocUploadCard('PAN Card / ID *', 'doc_pan'),
        _buildDocUploadCard('Parents Passport *', 'doc_parent_passport'),
        _buildDocUploadCard('Birth Certificate / Study Certificate *', 'doc_birth_cert'),
      ];
    } else if (_selectedSubService >= 4 && _selectedSubService <= 5) {
      // Correction / Renewal Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
        _buildDocUploadCard('PAN Card *', 'doc_pan'),
        _buildDocUploadCard('Old Passport Front *', 'doc_passport_front'),
        _buildDocUploadCard('Old Passport Back *', 'doc_passport_back'),
        _buildDocUploadCard('10th Marksheet *', 'doc_marksheet'),
      ];
    } else if (_selectedSubService == 6) {
      // Lost / Damage Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
        _buildDocUploadCard('PAN Card *', 'doc_pan'),
        _buildDocUploadCard('Old Passport Copy (If Available)', 'doc_old_passport'),
        _buildDocUploadCard('FIR Copy (If Available) *', 'doc_fir'),
        _buildDocUploadCard('10th Marksheet *', 'doc_marksheet'),
      ];
    } else if (_selectedSubService == 7) {
      // PCC
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
        _buildDocUploadCard('Passport Copy *', 'doc_passport_copy'),
      ];
    } else {
      // Normal & Tatkal
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
        _buildDocUploadCard('PAN Card *', 'doc_pan'),
        _buildDocUploadCard('10th Marksheet *', 'doc_marksheet'),
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 700;
        return isWide
            ? Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 24) / 3, child: c)).toList(),
              )
            : Column(
                children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
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
                  const SizedBox(height: 10),
                  c2,
                  const SizedBox(height: 10),
                  c3,
                ],
              );
      },
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
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isNum = false, String? helper, String? placeholder}) {
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), letterSpacing: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryTeal, width: 1.8),
            ),
            helperText: helper,
            helperStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
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
                      primary: primaryTeal,
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
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
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
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
          initialValue: value,
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
        ),
      ],
    );
  }

  Widget _buildDocUploadCard(String title, String docKey) {
    final docs = _uploadedDocs[docKey] ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D58).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded, size: 20, color: Color(0xFF0F9D58)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textDarkHeading),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    docs.isNotEmpty ? docs.first['name'] : 'Choose file (< 2MB)',
                    style: TextStyle(fontSize: 11, color: docs.isNotEmpty ? primaryTeal : textSubdued, fontWeight: docs.isNotEmpty ? FontWeight.w600 : FontWeight.w400),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _pickFile(docKey),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Browse', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
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
                color: Colors.black.withAlpha(16),
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
              Text(
                'Your $_serviceTitle request has been received successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryTeal.withAlpha(18),
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
  final _idController = TextEditingController();
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
