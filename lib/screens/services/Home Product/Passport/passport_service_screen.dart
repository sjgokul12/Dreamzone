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
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;
  int _expandedSectionIndex = 0;

  // Selected Passport Sub-Service Category: 0 = New Passport, 1 = Correction Passport, 2 = PCC
  int _selectedCategory = 0;
  
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

  // 3. Address For Communication
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

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _maritalStatusList = ['Single', 'Married', 'Divorced', 'Widowed'];
  List<String> _educationList = ['10th Pass and Above', 'Below 10th', 'Graduate & Above'];
  List<String> _jobTypeList = ['Private', 'Government', 'Self Employed', 'Student', 'Other'];

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

    // Map the preselected section to appropriate category and sub-service
    final subId = widget.preselectedSectionId ?? 1;
    _selectedSubService = subId;
    if (subId >= 1 && subId <= 3) {
      _selectedCategory = 0;
    } else if (subId >= 4 && subId <= 6) {
      _selectedCategory = 1;
    } else if (subId == 7) {
      _selectedCategory = 2;
    }

    _loadSavedUserData();
    _fetchDropdownData();
    _razorpayService.init();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
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
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get _payableAmount {
    if (_selectedSubService == 7) return 700.00;   // PCC
    if (_selectedSubService == 6) return 5300.00;  // Lost/Damage
    if (_selectedSubService == 5) return 5300.00;  // Correction Tatkal
    if (_selectedSubService == 4) return 2700.00;  // Correction Normal
    if (_selectedSubService == 3) return 1950.00;  // Minor
    if (_selectedSubService == 2) return 5300.00;  // Tatkal
    return 2700.00; // Normal
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

  Future<void> _submitPassportForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    // Open Razorpay first; backend called only on payment success
    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: _serviceTitle,
      name: 'DZI Infinity',
      contact: _mobileNumberController.text.trim(),
      email: _emailIdController.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitPassportForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitPassportForm({required dynamic auth, required String razorpayPaymentId}) async {
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
      'amount': _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id': razorpayPaymentId,
      'payment_status': 'paid',
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

      final response = await request.send().timeout(const Duration(seconds: 45));
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
                  'Secure & Trusted',
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

  Widget _buildFlightHeroCard() {
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
              'assets/Flight.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F0FF),
                  child: const Center(
                    child: Icon(Icons.flight_takeoff_rounded, size: 70, color: primaryPurple),
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
        final cardWidth = (constraints.maxWidth - 20) / 3;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _buildCategoryTabCard(
                index: 0,
                title: 'New Passport',
                subtitle: 'Apply for a new passport',
                icon: Icons.assignment_turned_in_outlined,
                width: cardWidth,
              ),
              const SizedBox(width: 10),
              _buildCategoryTabCard(
                index: 1,
                title: 'Correction Passport',
                subtitle: 'Correction & Lost passport',
                icon: Icons.edit_note_outlined,
                width: cardWidth,
              ),
              const SizedBox(width: 10),
              _buildCategoryTabCard(
                index: 2,
                title: 'PCC',
                subtitle: 'Police Clearance Certificate',
                icon: Icons.verified_user_outlined,
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
    final isSelected = _selectedCategory == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = index;
            if (index == 0) {
              _selectedSubService = 1; // Normal
            } else if (index == 1) {
              _selectedSubService = 4; // Correction Normal
            } else {
              _selectedSubService = 7; // PCC
            }
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
                  fontSize: 11.5,
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
                  fontSize: 8.5,
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
    String buttonTitle = "Next: Parent Details";
    String buttonSubtitle = "Save and continue";
    IconData buttonIcon = Icons.family_restroom_outlined;

    if (_expandedSectionIndex == 1) {
      buttonTitle = "Next: Address details";
      buttonIcon = Icons.home_outlined;
    } else if (_expandedSectionIndex == 2) {
      buttonTitle = "Next: Emergency Contact";
      buttonIcon = Icons.contact_phone_outlined;
    } else if (_expandedSectionIndex == 3) {
      buttonTitle = "Next: Upload Documents";
      buttonIcon = Icons.cloud_upload_outlined;
    } else if (_expandedSectionIndex == 4) {
      buttonTitle = "Next: Payment Details";
      buttonIcon = Icons.payment_outlined;
    } else if (_expandedSectionIndex == 5) {
      buttonTitle = "Proceed to Submit";
      buttonSubtitle = "Final step to complete";
      buttonIcon = Icons.check_circle_outline;
    } else if (_expandedSectionIndex == -1) {
      buttonTitle = "Submit Passport Form";
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
                    _buildFlightHeroCard(),
                    _buildCategoryTabs(),

                    // Step 1: Personal Information
                    _buildAccordionSection(
                      index: 0,
                      title: "1. Personal Information",
                      subtitle: "Enter applicant and birth details",
                      leadingIcon: Icons.person_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedCategory == 0) ...[
                            _buildDropdownField(
                              'Application Type *',
                              _selectedSubService == 1 ? 'Normal' : (_selectedSubService == 2 ? 'Tatkal' : 'Minor'),
                              ['Normal', 'Tatkal', 'Minor'],
                              (v) {
                                setState(() {
                                  if (v == 'Normal') _selectedSubService = 1;
                                  if (v == 'Tatkal') _selectedSubService = 2;
                                  if (v == 'Minor') _selectedSubService = 3;
                                });
                              },
                              prefixIcon: Icons.assignment_outlined,
                            ),
                            const SizedBox(height: 14),
                          ] else if (_selectedCategory == 1) ...[
                            _buildDropdownField(
                              'Application Type *',
                              _selectedSubService == 4
                                  ? 'Correction/Renewal passport'
                                  : (_selectedSubService == 5
                                      ? 'Correction/Renewal tatkal passport'
                                      : 'Lost/damage passport'),
                              [
                                'Correction/Renewal passport',
                                'Correction/Renewal tatkal passport',
                                'Lost/damage passport'
                              ],
                              (v) {
                                setState(() {
                                  if (v == 'Correction/Renewal passport') _selectedSubService = 4;
                                  if (v == 'Correction/Renewal tatkal passport') _selectedSubService = 5;
                                  if (v == 'Lost/damage passport') _selectedSubService = 6;
                                });
                              },
                              prefixIcon: Icons.assignment_outlined,
                            ),
                            const SizedBox(height: 14),
                          ],

                          _buildResponsiveRow(
                            context,
                            _buildInput('Applicant\'s Name *', _applicantNameController, placeholder: 'Enter Applicant\'s Name', prefixIcon: Icons.person_outline),
                            _buildInput('Initial Full Form', _initialFullFormController, placeholder: 'Enter Initial Full Form', prefixIcon: Icons.abc_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Place of Birth *', _birthPlaceController, placeholder: 'Enter Birth Place', prefixIcon: Icons.location_on_outlined),
                            _buildInput('Birth District *', _birthDistrictController, placeholder: 'Enter Birth District', prefixIcon: Icons.location_city_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildDateField('Date of Birth *', _dobController),
                            _buildDropdownField('Marital Status *', _maritalStatus, _maritalStatusList, (v) => setState(() => _maritalStatus = v!), prefixIcon: Icons.people_outline),
                          ),
                          if (_maritalStatus == 'Married') ...[
                            const SizedBox(height: 14),
                            _buildResponsiveRow(
                              context,
                              _buildInput('Spouse Name *', _spouseNameController, placeholder: 'Spouse Name', prefixIcon: Icons.person_outline),
                              _buildInput('Spouse Initial/Full Form', _spouseInitialController, placeholder: 'Spouse Initial', prefixIcon: Icons.abc_outlined),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('PAN No. *', _panNoController, placeholder: 'PAN NO.', prefixIcon: Icons.credit_card_outlined),
                            _buildInput('Aadhaar Number *', _aadhaarNoController, isNum: true, placeholder: 'AADHAAR NUMBER', prefixIcon: Icons.assignment_ind_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildDropdownField('Educational Qualification *', _education, _educationList, (v) => setState(() => _education = v!), prefixIcon: Icons.school_outlined),
                            _buildDropdownField('Job Type *', _jobType, _jobTypeList, (v) => setState(() => _jobType = v!), prefixIcon: Icons.work_outline),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Mobile Number *', _mobileNumberController, isNum: true, placeholder: 'MOBILE NUMBER', prefixIcon: Icons.phone_android_outlined),
                            _buildInput('Email ID *', _emailIdController, placeholder: 'Email ID', prefixIcon: Icons.mail_outline),
                          ),

                          if (_selectedCategory == 1) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            _buildInput('Existing Passport No *', _existingPassportNoController, placeholder: 'Existing Passport Number', prefixIcon: Icons.badge_outlined),
                            const SizedBox(height: 14),
                            _buildResponsiveRow(
                              context,
                              _buildInput('Existing File No. *', _existingFileNoController, placeholder: 'Existing File Number', prefixIcon: Icons.folder_open_outlined),
                              _buildDateField('Date Of Issue', _dateOfIssueController),
                            ),
                            const SizedBox(height: 14),
                            _buildDateField('Date Of Exp. *', _dateOfExpController),
                          ],
                        ],
                      ),
                    ),

                    // Step 2: Parent Details
                    _buildAccordionSection(
                      index: 1,
                      title: "2. Parent Details",
                      subtitle: "Enter father's and mother's names",
                      leadingIcon: Icons.family_restroom_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Father\'s Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkHeading)),
                          const SizedBox(height: 8),
                          _buildThreeColumnRow(
                            context,
                            _buildInput('First Name', _fatherFirstNameController, placeholder: 'First Name/Surname', prefixIcon: Icons.person_outline),
                            _buildInput('Middle Name', _fatherMiddleNameController, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
                            _buildInput('Last Name', _fatherLastNameController, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
                          ),
                          const SizedBox(height: 20),
                          const Text('Mother\'s Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkHeading)),
                          const SizedBox(height: 8),
                          _buildThreeColumnRow(
                            context,
                            _buildInput('First Name', _motherFirstNameController, placeholder: 'First Name/Surname', prefixIcon: Icons.person_outline),
                            _buildInput('Middle Name', _motherMiddleNameController, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
                            _buildInput('Last Name', _motherLastNameController, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
                          ),
                        ],
                      ),
                    ),

                    // Step 3: Address details
                    _buildAccordionSection(
                      index: 2,
                      title: "3. Address For Communication",
                      subtitle: "Enter your full mailing address",
                      leadingIcon: Icons.home_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResponsiveRow(
                            context,
                            _buildInput('House No./Building *', _houseNoController, placeholder: 'House No./Building', prefixIcon: Icons.home_outlined),
                            _buildInput('Street/Area *', _streetAreaController, placeholder: 'Street/Area Name', prefixIcon: Icons.directions_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Tehsil/Post *', _tehsilPostController, placeholder: 'Tehsil or Post office', prefixIcon: Icons.location_city_outlined),
                            _buildInput('Pincode *', _pincodeController, isNum: true, placeholder: 'Pincode', prefixIcon: Icons.pin_drop_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('District *', _districtController, placeholder: 'District Name', prefixIcon: Icons.map_outlined),
                            _buildInput('State *', _stateController, placeholder: 'State Name', prefixIcon: Icons.public_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildInput('City *', _cityController, placeholder: 'City Name', prefixIcon: Icons.location_on_outlined),
                        ],
                      ),
                    ),

                    // Step 4: Emergency Contact
                    _buildAccordionSection(
                      index: 3,
                      title: "4. Emergency Contact",
                      subtitle: "Provide contact person details",
                      leadingIcon: Icons.contact_phone_outlined,
                      child: Column(
                        children: [
                          _buildResponsiveRow(
                            context,
                            _buildInput('Name & Address *', _emergencyNameAddressController, placeholder: 'Name & Address', prefixIcon: Icons.contact_phone_outlined),
                            _buildInput('Mobile Number *', _emergencyMobileController, isNum: true, placeholder: 'Emergency Mobile', prefixIcon: Icons.phone_android_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildInput('Email ID *', _emergencyEmailController, placeholder: 'Emergency Email', prefixIcon: Icons.mail_outline),
                            _buildInput('Passport Kendra Location *', _kendraLocationController, placeholder: 'Passport Kendra', prefixIcon: Icons.my_location_outlined),
                          ),
                          const SizedBox(height: 14),
                          _buildResponsiveRow(
                            context,
                            _buildDateField('Appointment Date *', _appointmentDateController),
                            _buildInput('Police Station *', _policeStationController, placeholder: 'Police Station', prefixIcon: Icons.local_police_outlined),
                          ),
                        ],
                      ),
                    ),

                    // Step 5: Upload Document
                    _buildAccordionSection(
                      index: 4,
                      title: "5. Upload Documents",
                      subtitle: "Upload required identity and study files",
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
                                final requiredKeys = _selectedSubService == 7 
                                    ? ['aadhaar', 'passport_copy']
                                    : ['aadhaar', 'pan', 'marksheet'];
                                final firstEmpty = requiredKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => 'aadhaar');
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
                            _buildDocUploadCardsForSubService(),
                          ],
                        ),
                      ),
                    ),

                    // Step 6: Payment Details
                    _buildAccordionSection(
                      index: 5,
                      title: "6. Payment Details",
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
                                      Text(
                                        _serviceTitle,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textDarkHeading),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Processing and booking fee',
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
                if (_expandedSectionIndex >= 0 && _expandedSectionIndex < 5) {
                  setState(() {
                    _expandedSectionIndex++;
                  });
                } else if (_expandedSectionIndex == -1) {
                  setState(() {
                    _expandedSectionIndex = 0;
                  });
                } else {
                  _submitPassportForm();
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

  Widget _buildResponsiveRow(BuildContext context, Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 650;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 14),
                  Expanded(child: right),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  left,
                  const SizedBox(height: 14),
                  right,
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
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
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

  Widget _buildDocUploadCardsForSubService() {
    List<Widget> cards = [];

    if (_selectedSubService == 3) {
      // Minor Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'aadhaar'),
        _buildDocUploadCard('PAN Card / ID *', 'pan'),
        _buildDocUploadCard('Parents Passport *', 'parent_passport'),
        _buildDocUploadCard('Birth Certificate / Study Certificate *', 'birth_cert'),
      ];
    } else if (_selectedSubService >= 4 && _selectedSubService <= 5) {
      // Correction / Renewal Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'aadhaar'),
        _buildDocUploadCard('PAN Card *', 'pan'),
        _buildDocUploadCard('Old Passport Front *', 'passport_front'),
        _buildDocUploadCard('Old Passport Back *', 'passport_back'),
        _buildDocUploadCard('10th Marksheet *', 'marksheet'),
      ];
    } else if (_selectedSubService == 6) {
      // Lost / Damage Passport
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'aadhaar'),
        _buildDocUploadCard('PAN Card *', 'pan'),
        _buildDocUploadCard('Old Passport Copy (If Available)', 'old_passport'),
        _buildDocUploadCard('FIR Copy (If Available) *', 'fir'),
        _buildDocUploadCard('10th Marksheet *', 'marksheet'),
      ];
    } else if (_selectedSubService == 7) {
      // PCC
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'aadhaar'),
        _buildDocUploadCard('Passport Copy *', 'passport_copy'),
      ];
    } else {
      // Normal & Tatkal
      cards = [
        _buildDocUploadCard('Aadhaar Card *', 'aadhaar'),
        _buildDocUploadCard('PAN Card *', 'pan'),
        _buildDocUploadCard('10th Marksheet *', 'marksheet'),
      ];
    }

    return Column(
      children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
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
              Text(
                'Your $_serviceTitle request has been received successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
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
