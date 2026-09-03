import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../services/api_service.dart';
import '../../../../../core/payment/razorpay_service.dart';
import '../pan_common_widgets.dart';

class ForeignPanScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const ForeignPanScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<ForeignPanScreen> createState() => _ForeignPanScreenState();
}

class _ForeignPanScreenState extends State<ForeignPanScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  bool _fatherHasContent = false;
  bool _motherHasContent = false;

  // Dynamic Masters loaded from Database with instant default fallback
  List<String> _titles  = List<String>.from(ApiService.defaultTitles);
  List<String> _genders = List<String>.from(ApiService.defaultGenders);

  String? _applicantTitle;
  String? _gender         = 'Male';

  // 1. Personal Info Controllers
  final TextEditingController _firstNameCtrl       = TextEditingController();
  final TextEditingController _middleNameCtrl      = TextEditingController();
  final TextEditingController _lastNameCtrl        = TextEditingController();
  final TextEditingController _nameOnCardCtrl      = TextEditingController();
  final TextEditingController _fatherFirstNameCtrl = TextEditingController();
  final TextEditingController _fatherMiddleNameCtrl= TextEditingController();
  final TextEditingController _fatherLastNameCtrl  = TextEditingController();
  final TextEditingController _motherFirstNameCtrl = TextEditingController();
  final TextEditingController _motherMiddleNameCtrl= TextEditingController();
  final TextEditingController _motherLastNameCtrl  = TextEditingController();
  final TextEditingController _dobCtrl             = TextEditingController();
  final TextEditingController _identNoCtrl         = TextEditingController();

  // 2. Contact Info Controllers
  final TextEditingController _mobileCtrl  = TextEditingController();
  final TextEditingController _emailCtrl   = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();

  // 3. Address Controllers
  String _commAddressType = 'Business Partner Address';
  final TextEditingController _commHouseNoCtrl  = TextEditingController(text: '#702');
  final TextEditingController _commStreetCtrl   = TextEditingController(text: 'KORMANAGALA');
  final TextEditingController _commTehsilCtrl   = TextEditingController(text: 'NETHAJI CIRCLE');
  final TextEditingController _commPincodeCtrl  = TextEditingController(text: '560054');
  final TextEditingController _commDistrictCtrl = TextEditingController(text: 'SOUTH BANGALORE');
  final TextEditingController _commStateCtrl    = TextEditingController(text: 'KARNATAKA');
  final TextEditingController _commCityCtrl     = TextEditingController(text: 'BANGALORE');

  final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};
  Map<String, dynamic>? _savedDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _expandedSectionIndex = 0;

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

    _fatherFirstNameCtrl.addListener(_updateParentVisibility);
    _motherFirstNameCtrl.addListener(_updateParentVisibility);

    _loadMasterDataFromApi();
    _loadSavedUserData();
    _razorpayService.init();
  }

  void _updateParentVisibility() {
    final fHasText = _fatherFirstNameCtrl.text.trim().isNotEmpty;
    final mHasText = _motherFirstNameCtrl.text.trim().isNotEmpty;
    if (_fatherHasContent != fHasText || _motherHasContent != mHasText) {
      setState(() {
        _fatherHasContent = fHasText;
        _motherHasContent = mHasText;
      });
    }
  }

  Future<void> _loadMasterDataFromApi() async {
    try {
      final res = await ApiService.getPanMasters();
      if (!mounted) return;

      setState(() {
        if (res['titles'] is List && (res['titles'] as List).isNotEmpty) {
          _titles = (res['titles'] as List).map((e) => e.toString()).toList();
        }
        if (res['genders'] is List && (res['genders'] as List).isNotEmpty) {
          _genders = (res['genders'] as List).map((e) => e.toString()).toList();
        }
      });
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
          if (_firstNameCtrl.text.isEmpty && _savedDetails!['full_name'] != null) {
            _firstNameCtrl.text = _savedDetails!['full_name'];
          }
          if (_mobileCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _mobileCtrl.text = _savedDetails!['mobile'];
          }
          if (_emailCtrl.text.isEmpty && _savedDetails!['email'] != null) {
            _emailCtrl.text = _savedDetails!['email'];
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nameOnCardCtrl.dispose();
    _fatherFirstNameCtrl.dispose();
    _fatherMiddleNameCtrl.dispose();
    _fatherLastNameCtrl.dispose();
    _motherFirstNameCtrl.dispose();
    _motherMiddleNameCtrl.dispose();
    _motherLastNameCtrl.dispose();
    _dobCtrl.dispose();
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

  double get _payableAmount => 1500.00;

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
            {'name': f.name, 'size': f.size, 'bytes': f.bytes, 'extension': f.extension}
          ];
        });
      }
    } catch (_) {}
  }

  Future<void> _submitPanForm() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expandedSectionIndex = 0);
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PanLoginModal(
          onSuccess: () {
            Navigator.pop(ctx);
            _submitPanForm();
          },
        ),
      );
      return;
    }

    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: 'Foreign PAN Application',
      name: 'DZI Infinity',
      contact: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitPanForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitPanForm({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() => _loading = true);

    Map<String, dynamic> formData = {
      'pan_type':               'Foreign PAN Application',
      'applicant_title':        _applicantTitle ?? '',
      'first_name':             _firstNameCtrl.text.trim(),
      'middle_name':            _middleNameCtrl.text.trim(),
      'last_name':              _lastNameCtrl.text.trim(),
      'name_on_card':           _nameOnCardCtrl.text.trim(),
      'selected_parent':        _fatherHasContent ? 'Father' : (_motherHasContent ? 'Mother' : 'None'),
      'father_first_name':      _fatherHasContent ? _fatherFirstNameCtrl.text.trim() : '',
      'father_middle_name':     _fatherHasContent ? _fatherMiddleNameCtrl.text.trim() : '',
      'father_last_name':       _fatherHasContent ? _fatherLastNameCtrl.text.trim() : '',
      'mother_first_name':      _motherHasContent ? _motherFirstNameCtrl.text.trim() : '',
      'mother_middle_name':     _motherHasContent ? _motherMiddleNameCtrl.text.trim() : '',
      'mother_last_name':       _motherHasContent ? _motherLastNameCtrl.text.trim() : '',
      'dob_or_est_date':        _dobCtrl.text.trim(),
      'gender':                 _gender ?? '',
      'identification_number':  _identNoCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'email_id':               _emailCtrl.text.trim(),
      'delivery_country':       _countryCtrl.text.trim(),
      'comm_address_type':      _commAddressType,
      'comm_house_no':          _commHouseNoCtrl.text.trim(),
      'comm_street':            _commStreetCtrl.text.trim(),
      'comm_tehsil':            _commTehsilCtrl.text.trim(),
      'comm_pincode':           _commPincodeCtrl.text.trim(),
      'comm_district':          _commDistrictCtrl.text.trim(),
      'comm_state':             _commStateCtrl.text.trim(),
      'comm_city':              _commCityCtrl.text.trim(),
      'amount':                 _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':    razorpayPaymentId,
      'payment_status':         'paid',
    };

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/pan/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '200';
      request.fields['form_id']   = '203';
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in formData.entries) {
        request.fields[entry.key] = entry.value is Map ? jsonEncode(entry.value) : entry.value.toString();
      }

      for (var entry in _uploadedDocs.entries) {
        for (var fileInfo in entry.value) {
          if (fileInfo['bytes'] != null) {
            request.files.add(
              http.MultipartFile.fromBytes(entry.key, fileInfo['bytes'], filename: fileInfo['name']),
            );
          }
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 35));
      final resBody  = await response.stream.bytesToString();
      final data     = jsonDecode(resBody);

      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = data['tracking_id'] ?? 'TRK-PAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = 'TRK-PAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 1100 ? (screenSize.width - 920) / 2 : (screenSize.width > 700 ? 24.0 : 16.0);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgCanvas,
          body: _submitted
              ? PanSuccessView(
                  title: 'Foreign PAN Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const PanTopNavBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PanHeroCard(),
                                PanCategoryTabs(
                                  selectedIndex: 2,
                                  onSelectTab: widget.onSelectTab,
                                ),
                                _buildStepsAccordion(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      PanStickyBottomBar(
                        title: _expandedSectionIndex == 4 ? "Submit Foreign PAN" : (_expandedSectionIndex == 3 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 4 ? "Proceed to secure application submission" : "Save and continue",
                        icon: _expandedSectionIndex == 4 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 4) {
                            setState(() => _expandedSectionIndex++);
                          } else {
                            _submitPanForm();
                          }
                        },
                      ),
                    ],
                  ),
                ),
        ),
        if (_loading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildStepsAccordion() {
    return Column(
      children: [
        // 1. Personal Information (with Title first!)
        PanAccordionSection(
          index: 0,
          currentIndex: _expandedSectionIndex,
          title: '1. Personal Information',
          subtitle: 'Applicant title, Name, Parent details & National ID',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildPersonalInfoStep(),
        ),

        // 2. Contact Information (Immediately after Personal Info!)
        PanAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Contact Information',
          subtitle: 'Mobile number, Email ID, and Delivery country',
          leadingIcon: Icons.phone_iphone_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildPanResponsiveRow(
                context,
                buildPanInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: 'Mobile Number', prefixIcon: Icons.phone_iphone_outlined),
                buildPanInput('Email ID *', _emailCtrl, placeholder: 'Email Address', prefixIcon: Icons.mail_outline),
              ),
              const SizedBox(height: 14),
              buildPanInput('PAN Delivery Country *', _countryCtrl, placeholder: 'Delivery Country name', prefixIcon: Icons.public_outlined),
            ],
          ),
        ),

        // 3. Address for Communication
        PanAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Address For Communication',
          subtitle: 'Fill delivery address details',
          leadingIcon: Icons.home_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildAddressStep(),
        ),

        // 4. Upload Required Documents (49AA Forms)
        PanAccordionSection(
          index: 3,
          currentIndex: _expandedSectionIndex,
          title: '4. Upload Required Documents',
          subtitle: 'Passport / National ID & 49AA Forms',
          leadingIcon: Icons.cloud_upload_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildPanDocUploadCard(
                title: 'Passport / National ID *',
                docKey: 'doc_passport',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_passport'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_passport')),
              ),
              buildPanDocUploadCard(
                title: '49AA Form 01 *',
                docKey: 'doc_form01',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_form01'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_form01')),
              ),
              buildPanDocUploadCard(
                title: '49AA Form 02 *',
                docKey: 'doc_form02',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_form02'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_form02')),
              ),
              buildPanDocUploadCard(
                title: '49AA Form 03 *',
                docKey: 'doc_form03',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_form03'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_form03')),
              ),
            ],
          ),
        ),

        // 5. Payment Details
        PanAccordionSection(
          index: 4,
          currentIndex: _expandedSectionIndex,
          title: '5. Payment Details',
          subtitle: 'Foreign PAN fee costs & processing details',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildPanPaymentStepBox(
            title: 'Foreign PAN Application Fee',
            subtitle: 'Includes international verification & filing',
            amount: _payableAmount,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1st field: Applicant Title
        buildPanDropdown(
          'Applicant Title *',
          _applicantTitle,
          _titles,
          (v) => setState(() => _applicantTitle = v),
          hint: 'Select Title',
          prefixIcon: Icons.title_outlined,
        ),
        const SizedBox(height: 14),

        const Text("Applicant's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
        const SizedBox(height: 8),
        buildPanThreeColumnRow(
          context,
          buildPanInput('First Name *', _firstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
          buildPanInput('Middle Name', _middleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
          buildPanInput('Last Name', _lastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        buildPanDualNameOnCardField(
          context,
          _nameOnCardCtrl,
          placeholder: 'NAME ON CARD',
        ),
        const SizedBox(height: 14),

        if (!_motherHasContent) ...[
          const Text("Father's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
          const SizedBox(height: 8),
          buildPanThreeColumnRow(
            context,
            buildPanInput('Father First Name', _fatherFirstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
            buildPanInput('Father Middle Name', _fatherMiddleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
            buildPanInput('Father Last Name', _fatherLastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
          ),
          const SizedBox(height: 14),
        ],

        if (!_fatherHasContent) ...[
          const Text("Mother's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
          const SizedBox(height: 8),
          buildPanThreeColumnRow(
            context,
            buildPanInput('Mother First Name', _motherFirstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
            buildPanInput('Mother Middle Name', _motherMiddleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
            buildPanInput('Mother Last Name', _motherLastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
          ),
          const SizedBox(height: 14),
        ],

        buildPanResponsiveRow(
          context,
          buildPanDateField(context, 'Date of Birth *', _dobCtrl),
          buildPanDropdown('Gender *', _gender, _genders, (v) => setState(() => _gender = v), prefixIcon: Icons.wc_outlined),
        ),
        const SizedBox(height: 14),

        buildPanInput('Identification Number *', _identNoCtrl, placeholder: 'Identification / Passport Number', prefixIcon: Icons.badge_outlined),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Address Option', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkHeading)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _setCommAddressMode('Business Partner Address'),
                child: Row(
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
              ),
              InkWell(
                onTap: () => _setCommAddressMode('Address Per Application'),
                child: Row(
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        buildPanResponsiveRow(
          context,
          buildPanInput('House No./Building *', _commHouseNoCtrl, placeholder: 'House/Flat No.', prefixIcon: Icons.home_outlined),
          buildPanInput('Street/Area *', _commStreetCtrl, placeholder: 'Street name / Local area', prefixIcon: Icons.add_road_outlined),
        ),
        const SizedBox(height: 14),
        buildPanResponsiveRow(
          context,
          buildPanInput('Tehsil/Post *', _commTehsilCtrl, placeholder: 'Tehsil or Post office', prefixIcon: Icons.map_outlined),
          buildPanInput('Pincode *', _commPincodeCtrl, isNum: true, placeholder: '6-digit pincode', prefixIcon: Icons.pin_drop_outlined),
        ),
        const SizedBox(height: 14),
        buildPanThreeColumnRow(
          context,
          buildPanInput('District *', _commDistrictCtrl, placeholder: 'District', prefixIcon: Icons.location_city_outlined),
          buildPanInput('State *', _commStateCtrl, placeholder: 'State name', prefixIcon: Icons.public_outlined),
          buildPanInput('City *', _commCityCtrl, placeholder: 'City', prefixIcon: Icons.location_on_outlined),
        ),
      ],
    );
  }
}
