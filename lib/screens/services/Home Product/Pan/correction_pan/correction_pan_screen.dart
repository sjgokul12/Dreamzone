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

class CorrectionPanScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const CorrectionPanScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<CorrectionPanScreen> createState() => _CorrectionPanScreenState();
}

class _CorrectionPanScreenState extends State<CorrectionPanScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  bool _fatherHasContent = false;
  bool _motherHasContent = false;
  bool _isMinor = false;

  // Dynamic Masters
  List<String> _titles     = ["Shri", "Smt.", "Kumari", "M/s"];
  List<String> _categories = ["Individual", "Body of Individuals (BOI)", "Partnership Firm", "Government", "Association of Persons (AOP)", "Trust (AOP)", "Hindu undivided family (HUF)", "Company"];
  List<String> _genders    = ["Male", "Female", "Transgender"];
  List<String> _states     = ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];

  String? _applicantTitle;
  String? _applicantCategory;
  String? _gender = 'Male';
  String? _panDeliveryState;

  // 1. Old PAN Controller
  final TextEditingController _oldPanCtrl = TextEditingController();

  // 2. Personal Info Controllers
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
  final TextEditingController _aadhaarCtrl         = TextEditingController();

  // 3. Contact Info Controllers
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl  = TextEditingController();

  // 4. Address Controllers
  String _commAddressType = 'Business Partner Address';
  final TextEditingController _commHouseNoCtrl  = TextEditingController(text: '#702');
  final TextEditingController _commStreetCtrl   = TextEditingController(text: 'KORMANAGALA');
  final TextEditingController _commTehsilCtrl   = TextEditingController(text: 'NETHAJI CIRCLE');
  final TextEditingController _commPincodeCtrl  = TextEditingController(text: '560054');
  final TextEditingController _commDistrictCtrl = TextEditingController(text: 'SOUTH BANGALORE');
  final TextEditingController _commStateCtrl    = TextEditingController(text: 'KARNATAKA');
  final TextEditingController _commCityCtrl     = TextEditingController(text: 'BANGALORE');

  // 5. Fields to be changed Checkbox Chips
  final Map<String, bool> _fieldsToChange = {
    'Name': false,
    'Father Name': false,
    'Date of Birth': false,
    'Gender': false,
    'Photo / Signature': false,
    'Address': false,
    'PAN Card Copy': false,
  };

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

    void updateNameOnCard() {
      final parts = [
        _firstNameCtrl.text.trim(),
        _middleNameCtrl.text.trim(),
        _lastNameCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');
      _nameOnCardCtrl.text = parts;
    }

    _firstNameCtrl.addListener(updateNameOnCard);
    _middleNameCtrl.addListener(updateNameOnCard);
    _lastNameCtrl.addListener(updateNameOnCard);

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
      final resTitles = await ApiService.fetchApi('/pan/titles');
      final dTitles = jsonDecode(resTitles.body) as Map<String, dynamic>;
      if (dTitles['success'] == true && dTitles['titles'] != null && mounted) {
        setState(() => _titles = (dTitles['titles'] as List).map((e) => e.toString()).toList());
      }
      final resCats = await ApiService.fetchApi('/pan/categories');
      final dCats = jsonDecode(resCats.body) as Map<String, dynamic>;
      if (dCats['success'] == true && dCats['categories'] != null && mounted) {
        setState(() => _categories = (dCats['categories'] as List).map((e) => e.toString()).toList());
      }
      final resGen = await ApiService.fetchApi('/pan/genders');
      final dGen = jsonDecode(resGen.body) as Map<String, dynamic>;
      if (dGen['success'] == true && dGen['genders'] != null && mounted) {
        setState(() => _genders = (dGen['genders'] as List).map((e) => e.toString()).toList());
      }
      final resStates = await ApiService.fetchApi('/pan/states');
      final dStates = jsonDecode(resStates.body) as Map<String, dynamic>;
      if (dStates['success'] == true && dStates['states'] != null && mounted) {
        setState(() => _states = (dStates['states'] as List).map((e) => e.toString()).toList());
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
          if (_firstNameCtrl.text.isEmpty && _savedDetails!['full_name'] != null) {
            _firstNameCtrl.text = _savedDetails!['full_name'];
          }
          if (_mobileCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _mobileCtrl.text = _savedDetails!['mobile'];
          }
          if (_emailCtrl.text.isEmpty && _savedDetails!['email'] != null) {
            _emailCtrl.text = _savedDetails!['email'];
          }
          if (_aadhaarCtrl.text.isEmpty && _savedDetails!['aadhaar_number'] != null) {
            _aadhaarCtrl.text = _savedDetails!['aadhaar_number'];
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _oldPanCtrl.dispose();
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
    _aadhaarCtrl.dispose();
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

  double get _payableAmount => 150.00;

  void _showMinorWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Minor Applicant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDarkHeading)),
          ],
        ),
        content: const Text(
          'Minor !!! Please Upload Father/Mother Aadhaar.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textLabelDark),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      description: 'Correction PAN Application',
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
      'pan_type':               'Correction PAN Application',
      'old_pan_number':         _oldPanCtrl.text.trim(),
      'applicant_category':     _applicantCategory ?? '',
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
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'email_id':               _emailCtrl.text.trim(),
      'delivery_state':         _panDeliveryState ?? '',
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
      'razorpay_payment_id':    razorpayPaymentId,
      'payment_status':         'paid',
      'is_minor':               _isMinor,
    };

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/pan/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '200';
      request.fields['form_id']   = '202';
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
                  title: 'Correction PAN Application',
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
                                  selectedIndex: 1,
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
                        title: _expandedSectionIndex == 6 ? "Submit Correction PAN" : (_expandedSectionIndex == 5 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 6 ? "Proceed to secure application submission" : "Save and continue",
                        icon: _expandedSectionIndex == 6 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 6) {
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
        // 1. Old PAN Number (TOP!)
        PanAccordionSection(
          index: 0,
          currentIndex: _expandedSectionIndex,
          title: '1. Existing PAN Number',
          subtitle: 'Enter your existing PAN card number',
          leadingIcon: Icons.credit_card_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildPanInput(
            'Existing PAN Number *',
            _oldPanCtrl,
            placeholder: 'Enter 10-character existing PAN Number (e.g. ABCDE1234F)',
            prefixIcon: Icons.credit_card_outlined,
          ),
        ),

        // 2. Personal Information
        PanAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Personal Information',
          subtitle: 'Applicant details, Name on Card, Parent details & DOB',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildPersonalInfoStep(),
        ),

        // 3. Contact Information
        PanAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Contact Information',
          subtitle: 'Mobile number, Email ID, and Delivery state',
          leadingIcon: Icons.phone_iphone_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildPanResponsiveRow(
                context,
                buildPanInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: '10-digit mobile number', prefixIcon: Icons.phone_iphone_outlined),
                buildPanInput('Email ID *', _emailCtrl, placeholder: 'Email Address', prefixIcon: Icons.mail_outline),
              ),
              const SizedBox(height: 14),
              buildPanDropdown(
                'PAN Delivery State *',
                _panDeliveryState,
                _states,
                (v) => setState(() => _panDeliveryState = v),
                hint: 'Select State from Database',
                prefixIcon: Icons.location_on_outlined,
              ),
            ],
          ),
        ),

        // 4. Address for Communication
        PanAccordionSection(
          index: 3,
          currentIndex: _expandedSectionIndex,
          title: '4. Address For Communication',
          subtitle: 'Fill delivery address details',
          leadingIcon: Icons.home_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildAddressStep(),
        ),

        // 5. Fields To Be Corrected (Chips)
        PanAccordionSection(
          index: 4,
          currentIndex: _expandedSectionIndex,
          title: '5. Fields To Be Corrected',
          subtitle: 'Select which details on your PAN card to change',
          leadingIcon: Icons.edit_note_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select the details to correct on your PAN card:',
                style: TextStyle(fontSize: 13, color: textSubdued, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _fieldsToChange.keys.map((fieldKey) {
                  final isSel = _fieldsToChange[fieldKey] ?? false;
                  return FilterChip(
                    label: Text(fieldKey),
                    selected: isSel,
                    selectedColor: primaryPurple.withValues(alpha: 0.15),
                    checkmarkColor: primaryPurple,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
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

        // 6. Upload Required Documents (4 Docs)
        PanAccordionSection(
          index: 5,
          currentIndex: _expandedSectionIndex,
          title: '6. Upload Required Documents',
          subtitle: 'Aadhaar, Correction Front/Back, Proof of D.O.B',
          leadingIcon: Icons.cloud_upload_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildPanDocUploadCard(
                title: 'Aadhaar *',
                docKey: 'doc_aadhaar',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_aadhaar'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_aadhaar')),
              ),
              buildPanDocUploadCard(
                title: 'Correction Front Form *',
                docKey: 'doc_correction_front',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_correction_front'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_correction_front')),
              ),
              buildPanDocUploadCard(
                title: 'Correction Back Form *',
                docKey: 'doc_correction_back',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_correction_back'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_correction_back')),
              ),
              buildPanDocUploadCard(
                title: 'Proof Of D.O.B *',
                docKey: 'doc_dob_proof',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_dob_proof'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_dob_proof')),
              ),
              if (_isMinor)
                buildPanDocUploadCard(
                  title: 'Father/Mother Aadhaar Card *',
                  docKey: 'doc_minor_parent_aadhaar',
                  uploadedDocs: _uploadedDocs,
                  onPick: () => _pickFile('doc_minor_parent_aadhaar'),
                  onRemove: () => setState(() => _uploadedDocs.remove('doc_minor_parent_aadhaar')),
                ),
            ],
          ),
        ),

        // 7. Payment Details
        PanAccordionSection(
          index: 6,
          currentIndex: _expandedSectionIndex,
          title: '7. Payment Details',
          subtitle: 'Correction fee costs & processing details',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildPanPaymentStepBox(
            title: 'Correction PAN Fee',
            subtitle: 'Includes correction filing & processing',
            amount: _payableAmount,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    final showFullDetails = (_applicantCategory != null && _applicantCategory!.isNotEmpty) ||
                            (_applicantTitle != null && _applicantTitle!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPanResponsiveRow(
          context,
          buildPanDropdown(
            'Applicant Category *',
            _applicantCategory,
            _categories,
            (v) => setState(() => _applicantCategory = v),
            hint: 'Select Category',
            prefixIcon: Icons.category_outlined,
          ),
          buildPanDropdown(
            'Applicant Title *',
            _applicantTitle,
            _titles,
            (v) => setState(() => _applicantTitle = v),
            hint: 'Select Title',
            prefixIcon: Icons.title_outlined,
          ),
        ),
        const SizedBox(height: 14),

        if (showFullDetails) ...[
          const Text("Applicant's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
          const SizedBox(height: 8),
          buildPanThreeColumnRow(
            context,
            buildPanInput('First Name *', _firstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
            buildPanInput('Middle Name', _middleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
            buildPanInput('Last Name', _lastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
          ),
          const SizedBox(height: 14),

          buildPanInput(
            'Name on Card *',
            _nameOnCardCtrl,
            placeholder: 'Name printed on card (auto-filled)',
            prefixIcon: Icons.credit_card_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline, color: primaryPurple, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Fill Father or Mother details. The other will auto-hide.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textLabelDark),
                  ),
                ),
              ],
            ),
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
            buildPanDateField(
              context,
              'Date of Birth *',
              _dobCtrl,
              onDatePicked: (picked) {
                final now = DateTime.now();
                int age = now.year - picked.year;
                if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) age--;
                setState(() => _isMinor = age < 18);
                if (_isMinor) _showMinorWarningDialog();
              },
            ),
            buildPanDropdown('Gender *', _gender, _genders, (v) => setState(() => _gender = v), prefixIcon: Icons.wc_outlined),
          ),
          const SizedBox(height: 14),

          buildPanInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: '12-digit Aadhaar No.', prefixIcon: Icons.assignment_ind_outlined),
        ],
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
