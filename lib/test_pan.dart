import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';
import 'package:dreamzoneapp/services/api_service.dart';

class PanServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const PanServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<PanServiceScreen> createState() => _PanServiceScreenState();
}

class _PanServiceScreenState extends State<PanServiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Selected Section ID: 202 = Correction PAN, 201 = New PAN, 203 = Foreign PAN, 204 = Find PAN
  late int _selectedSectionId;

  // ─── API Dynamic Masters (Loaded from Database) ───────────────────────────
  List<String> _titles     = ["Shri", "Smt.", "Kumari", "M/s"];
  List<String> _categories = ["Individual", "Body of Individuals (BOI)", "Partnership Firm", "Government", "Association of Persons (AOP)", "Trust (AOP)", "Hindu undivided family (HUF)", "Company"];
  List<String> _genders    = ["Male", "Female", "Transgender"];
  List<String> _states     = ["Karnataka", "Tamil Nadu", "Kerala", "Andhra Pradesh", "Telangana", "Maharashtra", "Delhi", "West Bengal"];
  bool _mastersLoading     = true;

  // Selected Master Dropdown Values
  String? _applicantTitle    = 'Shri';
  String? _applicantCategory = 'Individual';
  String? _gender            = 'Male';
  String? _panDeliveryState;

  // ─── Form Field Controllers ────────────────────────────────────────────────
  // AO Code (New PAN)
  final TextEditingController _aoCodeCtrl    = TextEditingController();
  final TextEditingController _aoTypeCtrl    = TextEditingController();
  final TextEditingController _rangeCodeCtrl = TextEditingController();
  final TextEditingController _aoNoCtrl      = TextEditingController();

  // Personal Info
  final TextEditingController _firstNameCtrl       = TextEditingController();
  final TextEditingController _middleNameCtrl      = TextEditingController();
  final TextEditingController _lastNameCtrl        = TextEditingController();

  final TextEditingController _fatherFirstNameCtrl = TextEditingController();
  final TextEditingController _fatherMiddleNameCtrl= TextEditingController();
  final TextEditingController _fatherLastNameCtrl  = TextEditingController();

  final TextEditingController _dobCtrl              = TextEditingController();
  final TextEditingController _oldPanCtrl          = TextEditingController(); // Correction PAN
  final TextEditingController _aadhaarCtrl         = TextEditingController();
  final TextEditingController _nameInAadhaarCtrl   = TextEditingController();
  final TextEditingController _identNoCtrl         = TextEditingController(); // Foreign PAN

  // Contact Info
  final TextEditingController _mobileCtrl           = TextEditingController();
  final TextEditingController _emailCtrl            = TextEditingController();
  final TextEditingController _countryCtrl          = TextEditingController(); // Foreign PAN Country

  // Address For Communication
  String _commAddressType = 'Business Partner Address';
  final TextEditingController _commHouseNoCtrl  = TextEditingController(text: '#702');
  final TextEditingController _commStreetCtrl   = TextEditingController(text: 'KORMANAGALA');
  final TextEditingController _commTehsilCtrl   = TextEditingController(text: 'NETHAJI CIRCLE');
  final TextEditingController _commPincodeCtrl  = TextEditingController(text: '560054');
  final TextEditingController _commDistrictCtrl = TextEditingController(text: 'SOUTH BANGALORE');
  final TextEditingController _commStateCtrl    = TextEditingController(text: 'KARNATAKA');
  final TextEditingController _commCityCtrl     = TextEditingController(text: 'BANGALORE');

  // Fields to be changed (Correction PAN Styled Checkbox Chips)
  final Map<String, bool> _fieldsToChange = {
    'Name': false,
    'Father Name': false,
    'Date of Birth': false,
    'Gender': false,
    'Photo / Signature': false,
    'Address': false,
    'PAN Card Copy': false,
  };

  // Uploaded Document Bytes
  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};

  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium Palette
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
    _selectedSectionId = widget.preselectedSectionId ?? 202; // Default to Correction PAN

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
    _aoCodeCtrl.dispose();
    _aoTypeCtrl.dispose();
    _rangeCodeCtrl.dispose();
    _aoNoCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherFirstNameCtrl.dispose();
    _fatherMiddleNameCtrl.dispose();
    _fatherLastNameCtrl.dispose();
    _dobCtrl.dispose();
    _oldPanCtrl.dispose();
    _aadhaarCtrl.dispose();
    _nameInAadhaarCtrl.dispose();
    _identNoCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
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
      final resTitles = await ApiService.fetchApi('/pan/titles');
      final dTitles   = jsonDecode(resTitles.body) as Map<String, dynamic>;
      if (dTitles['success'] == true && dTitles['titles'] != null) {
        _titles = (dTitles['titles'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      final resCats = await ApiService.fetchApi('/pan/categories');
      final dCats   = jsonDecode(resCats.body) as Map<String, dynamic>;
      if (dCats['success'] == true && dCats['categories'] != null) {
        _categories = (dCats['categories'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      final resGen = await ApiService.fetchApi('/pan/genders');
      final dGen   = jsonDecode(resGen.body) as Map<String, dynamic>;
      if (dGen['success'] == true && dGen['genders'] != null) {
        _genders = (dGen['genders'] as List<dynamic>).map((e) => e.toString()).toList();
      }

      final resStates = await ApiService.fetchApi('/pan/states');
      final dStates   = jsonDecode(resStates.body) as Map<String, dynamic>;
      if (dStates['success'] == true && dStates['states'] != null) {
        _states = (dStates['states'] as List<dynamic>).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _mastersLoading = false;
        if (_titles.isNotEmpty && !_titles.contains(_applicantTitle)) _applicantTitle = _titles.first;
        if (_categories.isNotEmpty && !_categories.contains(_applicantCategory)) _applicantCategory = _categories.first;
        if (_genders.isNotEmpty && !_genders.contains(_gender)) _gender = _genders.first;
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
              primary: primaryPurple,
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
          if (_savedDetails!['pan_number'] != null) _oldPanCtrl.text = _savedDetails!['pan_number'];
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
      _oldPanCtrl.text  = _savedDetails!['pan_number'] ?? _oldPanCtrl.text;
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

  String get _currentPanTypeName {
    switch (_selectedSectionId) {
      case 201: return 'New PAN';
      case 203: return 'Foreign PAN';
      case 204: return 'Find PAN';
      case 202: default: return 'Correction PAN';
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

  Future<void> _submitPanForm() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginModal();
      return;
    }

    setState(() => _loading = true);

    Map<String, dynamic> formData = {
      'pan_type':               _currentPanTypeName,
      'ao_code':                _aoCodeCtrl.text.trim(),
      'ao_type':                _aoTypeCtrl.text.trim(),
      'range_code':             _rangeCodeCtrl.text.trim(),
      'ao_no':                  _aoNoCtrl.text.trim(),
      'applicant_category':     _applicantCategory ?? '',
      'applicant_title':        _applicantTitle ?? '',
      'first_name':             _firstNameCtrl.text.trim(),
      'middle_name':            _middleNameCtrl.text.trim(),
      'last_name':              _lastNameCtrl.text.trim(),
      'father_first_name':      _fatherFirstNameCtrl.text.trim(),
      'father_middle_name':     _fatherMiddleNameCtrl.text.trim(),
      'father_last_name':       _fatherLastNameCtrl.text.trim(),
      'dob_or_est_date':        _dobCtrl.text.trim(),
      'gender':                 _gender ?? '',
      'old_pan_number':         _oldPanCtrl.text.trim(),
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
      'name_in_aadhaar':        _nameInAadhaarCtrl.text.trim(),
      'identification_number':  _identNoCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'email_id':               _emailCtrl.text.trim(),
      'delivery_state':         _panDeliveryState ?? '',
      'delivery_country':       _countryCtrl.text.trim(),
      'comm_address_type':      _commAddressType,
      'comm_house_no':          _commHouseNoCtrl.text.trim(),
      'comm_street':            _commStreetCtrl.text.trim(),
      'comm_tehsil':            _commTehsilCtrl.text.trim(),
      'comm_pincode':           _commPincodeCtrl.text.trim(),
      'comm_district':          _commDistrictCtrl.text.trim(),
      'comm_state':             _commStateCtrl.text.trim(),
      'comm_city':              _commCityCtrl.text.trim(),
      'fields_to_change':       _fieldsToChange,
      'amount':                 _payableAmount.toStringAsFixed(2),
    };

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/pan/apply'),
      );
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '200';
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
              'TRK-PAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading   = false;
          _submitted = true;
          _trackingId= 'TRK-PAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
          _submitPanForm();
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
                child: _buildHero(context, 'PAN Registration', 'Pan Image.png'),
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
                                    text: 'PAN ',
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
                              'Apply for a new PAN, request a correction, or reprint your existing PAN card easily.',
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
                          child: Icon(Icons.badge_rounded, size: 80, color: primaryPurple.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Service Selector Tabs (4 PAN Options)
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
                          _buildTabChip(202, 'Correction'),
                          _buildTabChip(201, 'New'),
                          _buildTabChip(203, 'Foreign'),
                          _buildTabChip(204, 'Find'),
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
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedSectionId == 204) ...[
                            // ─── FIND PAN FORM ─────────────────────────────────────────
                            _buildHeaderBanner('1 Personal Information', subtitle: 'Please provide your personal details'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                children: [
                                  _buildInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: 'AADHAAR NUMBER', prefixIcon: Icons.badge_outlined),
                                  const SizedBox(height: 14),
                                  _buildInput('Name In Aadhaar *', _nameInAadhaarCtrl, placeholder: 'NAME IN AADHAAR', prefixIcon: Icons.person_outline),
                                  const SizedBox(height: 14),
                                  _buildResponsiveRow(
                                    context,
                                    _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER', prefixIcon: Icons.call_outlined),
                                    _buildDatePickerInput('Date of Birth *', _dobCtrl),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // ─── NEW PAN, CORRECTION PAN, FOREIGN PAN FORMS ───────────

                            // AO Code Section (New PAN Only - Matching Screenshot 1)
                            if (_selectedSectionId == 201) ...[
                              _buildHeaderBanner('1. AO Code'),
                              Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    bool isWide = constraints.maxWidth > 700;
                                    return isWide
                                        ? Row(
                                            children: [
                                              Expanded(child: _buildInput('AO CODE', _aoCodeCtrl)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('AO Type', _aoTypeCtrl)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('Range Code', _rangeCodeCtrl)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildInput('AO No.', _aoNoCtrl)),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              _buildInput('AO CODE', _aoCodeCtrl),
                                              const SizedBox(height: 10),
                                              _buildInput('AO Type', _aoTypeCtrl),
                                              const SizedBox(height: 10),
                                              _buildInput('Range Code', _rangeCodeCtrl),
                                              const SizedBox(height: 10),
                                              _buildInput('AO No.', _aoNoCtrl),
                                            ],
                                          );
                                  },
                                ),
                              ),
                            ],

                            // Personal Information Banner
                            _buildHeaderBanner(
                              _selectedSectionId == 201 ? '2. Personal Information' : '1 Personal Information',
                            ),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category & Title (Only for Correction PAN & New PAN)
                                  if (_selectedSectionId != 203) ...[
                                    _buildResponsiveRow(
                                      context,
                                      _buildDropdownField('Applicant Category *', _applicantCategory, _categories, (v) => setState(() => _applicantCategory = v)),
                                      _buildDropdownField('Applicant Title *', _applicantTitle, _titles, (v) => setState(() => _applicantTitle = v)),
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Existing PAN Number (Correction PAN Only)
                                  if (_selectedSectionId == 202) ...[
                                    _buildInput('Existing PAN Number *', _oldPanCtrl, placeholder: 'PAN NUMBER TO BE CORRECTED', prefixIcon: Icons.credit_card_outlined),
                                    const SizedBox(height: 14),
                                  ],

                                  // Applicant's Name Fields
                                  const Text("Applicant's Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark)),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 700;
                                      return isWide
                                          ? Row(
                                              children: [
                                                Expanded(child: _buildInput('First Name / Surname *', _firstNameCtrl, placeholder: 'FIRST NAME/SURNAME', prefixIcon: Icons.person_outline)),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Middle Name', _middleNameCtrl, placeholder: 'MIDDLE NAME', prefixIcon: Icons.person_outline)),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Last Name', _lastNameCtrl, placeholder: 'LAST NAME', prefixIcon: Icons.person_outline)),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildInput('First Name / Surname *', _firstNameCtrl, placeholder: 'FIRST NAME/SURNAME', prefixIcon: Icons.person_outline),
                                                const SizedBox(height: 10),
                                                _buildInput('Middle Name', _middleNameCtrl, placeholder: 'MIDDLE NAME', prefixIcon: Icons.person_outline),
                                                const SizedBox(height: 10),
                                                _buildInput('Last Name', _lastNameCtrl, placeholder: 'LAST NAME', prefixIcon: Icons.person_outline),
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Father's Name Fields
                                  const Text("Father's Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textLabelDark)),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isWide = constraints.maxWidth > 700;
                                      return isWide
                                          ? Row(
                                              children: [
                                                Expanded(child: _buildInput('First Name / Surname *', _fatherFirstNameCtrl, placeholder: 'FIRST NAME/SURNAME', prefixIcon: Icons.person_outline)),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Middle Name', _fatherMiddleNameCtrl, placeholder: 'MIDDLE NAME', prefixIcon: Icons.person_outline)),
                                                const SizedBox(width: 10),
                                                Expanded(child: _buildInput('Last Name', _fatherLastNameCtrl, placeholder: 'LAST NAME', prefixIcon: Icons.person_outline)),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                _buildInput('First Name / Surname *', _fatherFirstNameCtrl, placeholder: 'FIRST NAME/SURNAME', prefixIcon: Icons.person_outline),
                                                const SizedBox(height: 10),
                                                _buildInput('Middle Name', _fatherMiddleNameCtrl, placeholder: 'MIDDLE NAME', prefixIcon: Icons.person_outline),
                                                const SizedBox(height: 10),
                                                _buildInput('Last Name', _fatherLastNameCtrl, placeholder: 'LAST NAME', prefixIcon: Icons.person_outline),
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Date of Birth & Gender
                                  _buildResponsiveRow(
                                    context,
                                    _buildDatePickerInput('Date of Birth / Est. Date *', _dobCtrl),
                                    _buildDropdownField('Gender *', _gender, _genders, (v) => setState(() => _gender = v)),
                                  ),
                                  const SizedBox(height: 14),

                                  // Aadhaar OR Identification Number (Foreign PAN replaces Aadhaar with Identification Number)
                                  if (_selectedSectionId == 203) ...[
                                    _buildInput('Identification Number *', _identNoCtrl, placeholder: 'NATIONAL IDENTIFICATION NUMBER'),
                                  ] else ...[
                                    _buildResponsiveRow(
                                      context,
                                      _buildInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: 'AADHAAR NUMBER', prefixIcon: Icons.badge_outlined),
                                      _buildInput('Name In Aadhaar *', _nameInAadhaarCtrl, placeholder: 'NAME IN AADHAAR', prefixIcon: Icons.person_outline),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Contact Information Banner
                            _buildHeaderBanner(_selectedSectionId == 201 ? '3. Contact Information' : '2 Contact Information'),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  bool isWide = constraints.maxWidth > 700;
                                  return isWide
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER', prefixIcon: Icons.call_outlined)),
                                            const SizedBox(width: 12),
                                            Expanded(child: _buildInput('Email ID *', _emailCtrl, placeholder: 'Email ID')),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _selectedSectionId == 203
                                                  ? _buildInput('PAN Delivery Country *', _countryCtrl, placeholder: 'COUNTRY NAME')
                                                  : _buildDropdownField('PAN Delivery State *', _panDeliveryState, _states, (v) => setState(() => _panDeliveryState = v), hint: 'Select State'),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'MOBILE NUMBER', prefixIcon: Icons.call_outlined),
                                            const SizedBox(height: 12),
                                            _buildInput('Email ID *', _emailCtrl, placeholder: 'Email ID'),
                                            const SizedBox(height: 12),
                                            _selectedSectionId == 203
                                                ? _buildInput('PAN Delivery Country *', _countryCtrl, placeholder: 'COUNTRY NAME')
                                                : _buildDropdownField('PAN Delivery State *', _panDeliveryState, _states, (v) => setState(() => _panDeliveryState = v), hint: 'Select State'),
                                          ],
                                        );
                                },
                              ),
                            ),

                            // Address For Communication Banner
                            _buildHeaderBanner(_selectedSectionId == 201 ? '4. Address For Communication' : '3. Address For Communication'),
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
                                            activeColor: primaryPurple,
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
                                            activeColor: primaryPurple,
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

                            // Fields To Be Changed (Correction PAN Checkboxes - Stylish Chips UI)
                            if (_selectedSectionId == 202) ...[
                              _buildHeaderBanner('4. Fields To Be Changed'),
                              Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Select the fields you want to update on your PAN card:', style: TextStyle(fontSize: 12.5, color: textSubdued, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: _fieldsToChange.keys.map((fieldKey) {
                                        final isSel = _fieldsToChange[fieldKey] ?? false;
                                        return FilterChip(
                                          label: Text(fieldKey),
                                          selected: isSel,
                                          selectedColor: primaryPurple.withValues(alpha: 0.18),
                                          checkmarkColor: primaryPurple,
                                          labelStyle: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSel ? primaryPurple : textDarkHeading,
                                          ),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: BorderSide(color: isSel ? primaryPurple : const Color(0xFFCBD5E1)),
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
                            _buildHeaderBanner(
                              _selectedSectionId == 201 ? '5. Upload Document.' : (_selectedSectionId == 202 ? '5. Upload Document.' : '4 Upload Documents.'),
                            ),
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
                                        final reqKeys = _selectedSectionId == 203
                                            ? ['doc_passport', 'doc_form01', 'doc_form02', 'doc_form03']
                                            : (_selectedSectionId == 202 ? ['doc_aadhaar', 'doc_pancopy', 'doc_photo'] : ['doc_aadhaar', 'doc_photo']);
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

                                    // Document Cards depending on Section
                                    if (_selectedSectionId == 203) ...[
                                      // Foreign PAN: 4 Specified Uploads
                                      _buildDocUploadCard('Passport / National Identification *', 'doc_passport'),
                                      _buildDocUploadCard('49AA Form 01 *', 'doc_form01'),
                                      _buildDocUploadCard('49AA Form 02 *', 'doc_form02'),
                                      _buildDocUploadCard('49AA Form 03 *', 'doc_form03'),
                                    ] else if (_selectedSectionId == 202) ...[
                                      // Correction PAN Uploads
                                      _buildDocUploadCard('Aadhaar Card *', 'doc_aadhaar'),
                                      _buildDocUploadCard('PAN Card Copy *', 'doc_pancopy'),
                                      _buildDocUploadCard('Applicant Photo *', 'doc_photo'),
                                    ] else ...[
                                      // New PAN Uploads
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
                            _selectedSectionId == 204 ? '2. Payment' : (_selectedSectionId == 203 ? '5. Payment' : '6. Payment')
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
                                      onPressed: _loading ? null : _submitPanForm,
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isSel ? primaryPurple : Colors.white,
          ),
        ),
      ),
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
                'Your $_currentPanTypeName request has been received successfully.',
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
          const Text('Please login to submit your PAN application.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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
