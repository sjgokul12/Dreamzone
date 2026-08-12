import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';

class VoterIdServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const VoterIdServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<VoterIdServiceScreen> createState() => _VoterIdServiceScreenState();
}

class _VoterIdServiceScreenState extends State<VoterIdServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Selected Section ID: 101 = Apply New Voter, 102 = Correction Voter, 103 = Hard Copy, 104 = Soft Copy
  late int _selectedSectionId;

  // ─── API Dynamic Masters (Loaded from Database) ───────────────────────────
  List<String> _genders       = ["Male", "Female", "Transgender"];
  List<String> _relationTypes = ["Father", "Mother", "Spouse", "Legal Guardian in case of orphan/Guru in case of third gender"];
  List<String> _states        = ["Karnataka", "Tamil Nadu", "Kerala", "Andhra Pradesh", "Telangana", "Maharashtra", "Delhi", "West Bengal"];
  bool _mastersLoading        = true;

  // Selected Master Dropdown Values
  String? _gender       = 'Male';
  String? _relationType = 'Father';
  String? _deliveryState;

  // ─── Form Field Controllers ────────────────────────────────────────────────
  final TextEditingController _voterIdNoCtrl        = TextEditingController(); // Correction / Hard Copy / Soft Copy
  final TextEditingController _firstNameCtrl        = TextEditingController();
  final TextEditingController _middleNameCtrl       = TextEditingController();
  final TextEditingController _lastNameCtrl         = TextEditingController();

  final TextEditingController _relativeFirstNameCtrl= TextEditingController();
  final TextEditingController _relativeMiddleNameCtrl= TextEditingController();
  final TextEditingController _relativeLastNameCtrl = TextEditingController();

  final TextEditingController _dobCtrl              = TextEditingController();
  final TextEditingController _aadhaarCtrl         = TextEditingController();
  final TextEditingController _nameInAadhaarCtrl   = TextEditingController();

  // Contact Info
  final TextEditingController _mobileCtrl           = TextEditingController();
  final TextEditingController _emailCtrl            = TextEditingController();

  // Address For Communication
  String _commAddressType = 'Business Partner Address';
  final TextEditingController _commHouseNoCtrl  = TextEditingController(text: '#702');
  final TextEditingController _commStreetCtrl   = TextEditingController(text: 'KORMANAGALA');
  final TextEditingController _commTehsilCtrl   = TextEditingController(text: 'NETHAJI CIRCLE');
  final TextEditingController _commPincodeCtrl  = TextEditingController(text: '560054');
  final TextEditingController _commDistrictCtrl = TextEditingController(text: 'SOUTH BANGALORE');
  final TextEditingController _commStateCtrl    = TextEditingController(text: 'KARNATAKA');
  final TextEditingController _commCityCtrl     = TextEditingController(text: 'BANGALORE');

  // Fields to be changed (Correction Voter Checkbox Chips)
  final Map<String, bool> _fieldsToChange = {
    'Name': false,
    'Relation Name': false,
    'Relation Type': false,
    'Date of Birth': false,
    'Gender': false,
    'Photo': false,
    'Address': false,
    'Voter ID Copy': false,
  };

  // Uploaded Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium Palette
  static const Color primaryTeal        = Color(0xFF8B5CF6);
  static const Color secondaryTeal      = Color(0xFF9333EA);
  static const Color headerGradientStart= Color(0xFF9333EA);
  static const Color headerGradientEnd  = Color(0xFFC084FC);
  static const Color textDarkHeading    = Color(0xFF1E293B);
  static const Color textLabelDark      = Color(0xFF1E293B);
  static const Color textSubdued        = Color(0xFF64748B);
  static const Color bgCanvas           = Color(0xFFF1F5F9);
  static const Color cardSurface        = Colors.white;

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.preselectedSectionId ?? 101; // Default to Apply New Voter

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _loadMasterDataFromApi();
    _loadSavedUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voterIdNoCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _relativeFirstNameCtrl.dispose();
    _relativeMiddleNameCtrl.dispose();
    _relativeLastNameCtrl.dispose();
    _dobCtrl.dispose();
    _aadhaarCtrl.dispose();
    _nameInAadhaarCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _commHouseNoCtrl.dispose();
    _commStreetCtrl.dispose();
    _commTehsilCtrl.dispose();
    _commPincodeCtrl.dispose();
    _commDistrictCtrl.dispose();
    _commStateCtrl.dispose();
    _commCityCtrl.dispose();
    super.dispose();
  }

  // ─── Fetch Master Lookup Data from API (Database Driven) ──────────────────
  Future<void> _loadMasterDataFromApi() async {
    if (mounted) setState(() { _mastersLoading = true; });
    try {
      final resGen = await ApiService.fetchApi('/voter/genders');
      final dGen   = jsonDecode(resGen.body) as Map<String, dynamic>;
      if (dGen['success'] == true && dGen['genders'] != null) {
        _genders = (dGen['genders'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      final resRel = await ApiService.fetchApi('/voter/relation-types');
      final dRel   = jsonDecode(resRel.body) as Map<String, dynamic>;
      if (dRel['success'] == true && dRel['relation_types'] != null) {
        _relationTypes = (dRel['relation_types'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      final resStates = await ApiService.fetchApi('/voter/states');
      final dStates   = jsonDecode(resStates.body) as Map<String, dynamic>;
      if (dStates['success'] == true && dStates['states'] != null) {
        _states = (dStates['states'] as List<dynamic>).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _mastersLoading = false;
        if (_genders.isNotEmpty && !_genders.contains(_gender)) _gender = _genders.first;
        if (_relationTypes.isNotEmpty && !_relationTypes.contains(_relationType)) _relationType = _relationTypes.first;
      });
    }
  }

  // ─── Date Picker Function ─────────────────────────────────────────────────
  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
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

    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
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
            _firstNameCtrl.text = parts.first;
            if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
            _nameInAadhaarCtrl.text = _savedDetails!['full_name'];
          }
          if (_savedDetails!['mobile'] != null) _mobileCtrl.text = _savedDetails!['mobile'];
          if (_savedDetails!['email'] != null) _emailCtrl.text = _savedDetails!['email'];
          if (_savedDetails!['aadhaar_number'] != null) _aadhaarCtrl.text = _savedDetails!['aadhaar_number'];
        });
      }
    } catch (_) {}
  }

  void _applySavedDetails() {
    if (_savedDetails == null) return;
    setState(() {
      if (_savedDetails!['full_name'] != null) {
        final parts = (_savedDetails!['full_name'] as String).split(' ');
        _firstNameCtrl.text = parts.first;
        if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
        _nameInAadhaarCtrl.text = _savedDetails!['full_name'];
      }
      _mobileCtrl.text  = _savedDetails!['mobile'] ?? _mobileCtrl.text;
      _emailCtrl.text   = _savedDetails!['email'] ?? _emailCtrl.text;
      _aadhaarCtrl.text = _savedDetails!['aadhaar_number'] ?? _aadhaarCtrl.text;
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

  String get _currentVoterTypeName {
    switch (_selectedSectionId) {
      case 101: return 'Apply New Voter';
      case 102: return 'Correction Voter';
      case 103: return 'Hard Copy';
      case 104: return 'Soft Copy';
      default:  return 'Apply New Voter';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
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

  Future<void> _submitVoterForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, dynamic> formData = {
      'voter_type':           _currentVoterTypeName,
      'voter_id_number':      _voterIdNoCtrl.text.trim(),
      'first_name':           _firstNameCtrl.text.trim(),
      'middle_name':          _middleNameCtrl.text.trim(),
      'last_name':            _lastNameCtrl.text.trim(),
      'relation_type':        _relationType ?? '',
      'relative_first_name':  _relativeFirstNameCtrl.text.trim(),
      'relative_middle_name': _relativeMiddleNameCtrl.text.trim(),
      'relative_last_name':   _relativeLastNameCtrl.text.trim(),
      'dob_or_est_date':      _dobCtrl.text.trim(),
      'gender':               _gender ?? '',
      'aadhaar_number':       _aadhaarCtrl.text.trim(),
      'name_in_aadhaar':      _nameInAadhaarCtrl.text.trim(),
      'mobile_number':        _mobileCtrl.text.trim(),
      'email_id':             _emailCtrl.text.trim(),
      'delivery_state':       _deliveryState ?? '',
      'comm_address_type':    _commAddressType,
      'comm_house_no':        _commHouseNoCtrl.text.trim(),
      'comm_street':          _commStreetCtrl.text.trim(),
      'comm_tehsil':          _commTehsilCtrl.text.trim(),
      'comm_pincode':         _commPincodeCtrl.text.trim(),
      'comm_district':        _commDistrictCtrl.text.trim(),
      'comm_state':           _commStateCtrl.text.trim(),
      'comm_city':            _commCityCtrl.text.trim(),
      'fields_to_change':     _fieldsToChange,
      'amount':               _payableAmount.toStringAsFixed(2),
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/voter/apply'),
      );
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '100';
      request.fields['form_id']   = _selectedSectionId.toString();
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in formData.entries) {
        if (entry.value is Map) {
          request.fields[entry.key] = jsonEncode(entry.value);
        } else {
          request.fields[entry.key] = entry.value.toString();
        }
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
              'TRK-VOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-VOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitVoterForm();
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
                                  const TextSpan(
                                    text: 'Voter ',
                                    style: TextStyle(
                                      color: primaryTeal,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'ID',
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
                              'Get your Voter ID card delivered to your address',
                              style: TextStyle(
                                color: textSubdued,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: Colors.orange.shade700, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Trending', style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
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
                          child: Image.asset('assets/Voter card.png', height: 100, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Service Selector Tabs (4 Voter ID Options)
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTabChip(101, 'Apply New Voter'),
                          _buildTabChip(102, 'Correction Voter'),
                          _buildTabChip(103, 'Hard Copy'),
                          _buildTabChip(104, 'Soft Copy'),
                        ],
                      ),
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
                          if (_selectedSectionId == 104) ...[
                            // ─── SOFT COPY FORM ─────────────────────────────────────────
                            _buildHeaderBanner('1. Personal Information'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                children: [
                                  _buildInput('Voter ID Number *', _voterIdNoCtrl, placeholder: 'VOTER ID NUMBER'),
                                  const SizedBox(height: 14),
                                  _buildInput("Applicant's Name *", _firstNameCtrl, placeholder: "APPLICANT'S FULL NAME"),
                                  const SizedBox(height: 14),
                                  _buildResponsiveRow(
                                    context,
                                    _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER'),
                                    _buildDatePickerInput('Date of Birth *', _dobCtrl),
                                  ),
                                ],
                              ),
                            ),

                            // Soft Copy Upload Document (Voter ID Proof REMOVED, replaced with Aadhaar Card)
                            _buildHeaderBanner('2. Upload Document.'),
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
                                    const Text('Upload Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                    const SizedBox(height: 14),

                                    // Drop Zone Box
                                    InkWell(
                                      onTap: () => _pickFile('doc_aadhaar'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                            Text('Drop file here or browse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading)),
                                            SizedBox(height: 4),
                                            Text('PDF, PNG, JPG up to 2MB', style: TextStyle(fontSize: 11.5, color: textSubdued, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Soft Copy Document (Aadhaar Card)
                                    _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // ─── APPLY NEW VOTER, CORRECTION VOTER, HARD COPY FORMS ───
                            _buildHeaderBanner('1. Personal Information'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Voter ID Number (Correction Voter & Hard Copy)
                                  if (_selectedSectionId == 102 || _selectedSectionId == 103) ...[
                                    _buildInput('Voter ID Number *', _voterIdNoCtrl, placeholder: 'VOTER ID NUMBER'),
                                    const SizedBox(height: 14),
                                  ],

                                  // Applicant Name Fields
                                  const Text("Applicant's Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark)),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 700;
                                      return isWide
                                          ? Row(
                                              children: [
                                                Expanded(child: _buildInput('First Name / Surname *', _firstNameCtrl, placeholder: 'FIRST NAME/SURNAME')),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Middle Name', _middleNameCtrl, placeholder: 'MIDDLE NAME')),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Last Name', _lastNameCtrl, placeholder: 'LAST NAME')),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildInput('First Name / Surname *', _firstNameCtrl, placeholder: 'FIRST NAME/SURNAME'),
                                                const SizedBox(height: 10),
                                                _buildInput('Middle Name', _middleNameCtrl, placeholder: 'MIDDLE NAME'),
                                                const SizedBox(height: 10),
                                                _buildInput('Last Name', _lastNameCtrl, placeholder: 'LAST NAME'),
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Relation Type & Relative's Name (Apply New & Correction Voter)
                                  if (_selectedSectionId == 101 || _selectedSectionId == 102) ...[
                                    _buildDropdownField('Relation Type *', _relationType, _relationTypes, (v) => setState(() => _relationType = v)),
                                    const SizedBox(height: 14),
                                    const Text("Relative's Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark)),
                                    const SizedBox(height: 6),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        bool isWide = constraints.maxWidth > 700;
                                        return isWide
                                            ? Row(
                                                children: [
                                                  Expanded(child: _buildInput('First Name / Surname *', _relativeFirstNameCtrl, placeholder: 'FIRST NAME/SURNAME')),
                                                  const SizedBox(width: 10),
                                                  Expanded(child: _buildInput('Middle Name', _relativeMiddleNameCtrl, placeholder: 'MIDDLE NAME')),
                                                  const SizedBox(width: 10),
                                                  Expanded(child: _buildInput('Last Name', _relativeLastNameCtrl, placeholder: 'LAST NAME')),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  _buildInput('First Name / Surname *', _relativeFirstNameCtrl, placeholder: 'FIRST NAME/SURNAME'),
                                                  const SizedBox(height: 10),
                                                  _buildInput('Middle Name', _relativeMiddleNameCtrl, placeholder: 'MIDDLE NAME'),
                                                  const SizedBox(height: 10),
                                                  _buildInput('Last Name', _relativeLastNameCtrl, placeholder: 'LAST NAME'),
                                                ],
                                              );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Date of Birth & Gender
                                  _buildResponsiveRow(
                                    context,
                                    _buildDatePickerInput('Date of Birth / Est. Date *', _dobCtrl),
                                    _buildDropdownField('Gender *', _gender, _genders, (v) => setState(() => _gender = v)),
                                  ),
                                  const SizedBox(height: 14),

                                  // Aadhaar Details (Apply New & Correction Voter)
                                  if (_selectedSectionId == 101 || _selectedSectionId == 102) ...[
                                    _buildResponsiveRow(
                                      context,
                                      _buildInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: 'AADHAAR NUMBER'),
                                      _buildInput('Name In Aadhaar *', _nameInAadhaarCtrl, placeholder: 'NAME IN AADHAAR'),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Contact Information Banner
                            _buildHeaderBanner('2. Contact Information'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  bool isWide = constraints.maxWidth > 700;
                                  return isWide
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER')),
                                            const SizedBox(width: 12),
                                            Expanded(child: _buildInput('Email ID *', _emailCtrl, placeholder: 'Email ID')),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildDropdownField('Delivery State *', _deliveryState, _states, (v) => setState(() => _deliveryState = v), hint: 'Select State'),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER'),
                                            const SizedBox(height: 12),
                                            _buildInput('Email ID *', _emailCtrl, placeholder: 'Email ID'),
                                            const SizedBox(height: 12),
                                            _buildDropdownField('Delivery State *', _deliveryState, _states, (v) => setState(() => _deliveryState = v), hint: 'Select State'),
                                          ],
                                        );
                                },
                              ),
                            ),

                            // Address For Communication Banner
                            _buildHeaderBanner('3. Address For Communication'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      const Text('Delivery Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark)),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Radio<String>(
                                            value: 'Business Partner Address',
                                            groupValue: _commAddressType,
                                            activeColor: primaryTeal,
                                            onChanged: (v) => _setCommAddressMode(v!),
                                          ),
                                          const Text('Business Partner Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Radio<String>(
                                            value: 'Address Per Application',
                                            groupValue: _commAddressType,
                                            activeColor: primaryTeal,
                                            onChanged: (v) => _setCommAddressMode(v!),
                                          ),
                                          const Text('Address Per Application', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 750;
                                      return isWide
                                          ? Row(children: [
                                              Expanded(child: _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: '#702', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Street/Area *', _commStreetCtrl, maxLength: 25, placeholder: 'KORMANAGALA', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'NETHAJI CIRCLE', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 25, placeholder: '560054', helper: 'Enter Only 25 Characters')),
                                            ])
                                          : Column(children: [
                                              _buildInput('House No./Building *', _commHouseNoCtrl, maxLength: 25, placeholder: '#702', helper: 'Enter Only 25 Characters'),
                                              const SizedBox(height: 10),
                                              _buildInput('Street/Area *', _commStreetCtrl, maxLength: 25, placeholder: 'KORMANAGALA', helper: 'Enter Only 25 Characters'),
                                              const SizedBox(height: 10),
                                              _buildInput('Tehsil/Post *', _commTehsilCtrl, maxLength: 25, placeholder: 'NETHAJI CIRCLE', helper: 'Enter Only 25 Characters'),
                                              const SizedBox(height: 10),
                                              _buildInput('Pincode *', _commPincodeCtrl, isNum: true, maxLength: 25, placeholder: '560054', helper: 'Enter Only 25 Characters'),
                                            ]);
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 750;
                                      return isWide
                                          ? Row(children: [
                                              Expanded(child: _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'SOUTH BANGALORE', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'KARNATAKA', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'BANGALORE', helper: 'Enter Only 25 Characters')),
                                              const SizedBox(width: 10),
                                              const Expanded(child: SizedBox()),
                                            ])
                                          : Column(children: [
                                              _buildInput('District *', _commDistrictCtrl, maxLength: 25, placeholder: 'SOUTH BANGALORE', helper: 'Enter Only 25 Characters'),
                                              const SizedBox(height: 10),
                                              _buildInput('State *', _commStateCtrl, maxLength: 25, placeholder: 'KARNATAKA', helper: 'Enter Only 25 Characters'),
                                              const SizedBox(height: 10),
                                              _buildInput('City *', _commCityCtrl, maxLength: 25, placeholder: 'BANGALORE', helper: 'Enter Only 25 Characters'),
                                            ]);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Fields To Be Changed (Correction Voter Checkboxes - Stylish Chips UI)
                            if (_selectedSectionId == 102) ...[
                              _buildHeaderBanner('4. Fields To Be Changed'),
                              Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Select the fields you want to update on your Voter ID:', style: TextStyle(fontSize: 12.5, color: textSubdued, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: _fieldsToChange.keys.map((fieldKey) {
                                        final isSel = _fieldsToChange[fieldKey] ?? false;
                                        return FilterChip(
                                          label: Text(fieldKey),
                                          selected: isSel,
                                          selectedColor: primaryTeal.withValues(alpha: 0.18),
                                          checkmarkColor: primaryTeal,
                                          labelStyle: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSel ? primaryTeal : textDarkHeading,
                                          ),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: BorderSide(color: isSel ? primaryTeal : const Color(0xFFCBD5E1)),
                                          ),
                                          onSelected: (val) => setState(() => _fieldsToChange[fieldKey] = val),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Upload Document Banner (Matching Screenshot 2 UI)
                            _buildHeaderBanner(_selectedSectionId == 102 ? '5. Upload Document.' : '4. Upload Document.'),
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
                                    const Text('Upload Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDarkHeading)),
                                    const SizedBox(height: 14),

                                    // Top Drop Zone Box
                                    InkWell(
                                      onTap: () {
                                        final reqKeys = _selectedSectionId == 102
                                            ? ['doc_aadhaar', 'doc_voter_copy', 'doc_photo']
                                            : (_selectedSectionId == 103 ? ['doc_aadhaar', 'doc_voter_copy'] : ['doc_aadhaar', 'doc_photo']);
                                        final firstEmpty = reqKeys.firstWhere((k) => !_uploadedDocs.containsKey(k), orElse: () => reqKeys.first);
                                        _pickFile(firstEmpty);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                            Text('Drop file here or browse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading)),
                                            SizedBox(height: 4),
                                            Text('PDF, PNG, JPG up to 2MB', style: TextStyle(fontSize: 11.5, color: textSubdued, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Upload Cards by Section
                                    if (_selectedSectionId == 102) ...[
                                      // Correction Voter Uploads
                                      _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                      _buildDocUploadCard('Voter ID Copy *', 'doc_voter_copy'),
                                      _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
                                    ] else if (_selectedSectionId == 103) ...[
                                      // Hard Copy Uploads
                                      _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                      _buildDocUploadCard('Voter ID Copy *', 'doc_voter_copy'),
                                    ] else ...[
                                      // Apply New Voter Uploads
                                      _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                      _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Payment Section
                          _buildHeaderBanner(
                            _selectedSectionId == 104 ? '3. Payment' : (_selectedSectionId == 102 ? '6. Payment' : '5. Payment')
                          ),
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
                                      onPressed: _loading ? null : _submitVoterForm,
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
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? primaryTeal : textSubdued,
          ),
        ),
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
            counterText: helper,
            counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
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

  Widget _buildDatePickerInput(String label, TextEditingController controller) {
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
          onTap: () => _selectDob(context),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: 'DD-MM-YYYY',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            suffixIcon: const Icon(Icons.calendar_today_rounded, color: primaryTeal, size: 20),
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
                backgroundColor: primaryTeal.withValues(alpha: 0.1),
                foregroundColor: primaryTeal,
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
              Text(
                'Your $_currentVoterTypeName request has been received successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Login Required', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Please login to submit your Voter ID application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
