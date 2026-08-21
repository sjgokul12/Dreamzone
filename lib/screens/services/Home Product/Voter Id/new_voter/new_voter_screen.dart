import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../services/api_service.dart';
import '../../../../../core/payment/razorpay_service.dart';
import '../voter_common_widgets.dart';

class NewVoterScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const NewVoterScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<NewVoterScreen> createState() => _NewVoterScreenState();
}

class _NewVoterScreenState extends State<NewVoterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  bool _fatherHasContent = false;
  bool _motherHasContent = false;

  // Dynamic Masters
  List<String> _genders = ["Male", "Female", "Transgender"];
  List<String> _states  = ["Andaman and Nicobar Islands","Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chandigarh","Chhattisgarh","Dadra and Nagar Haveli","Daman and Diu","Delhi","Goa","Gujarat","Haryana","Himachal Pradesh","Jammu and Kashmir","Jharkhand","Karnataka","Kerala","Lakshadweep","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Pondicherry","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal"];

  String? _gender = 'Male';
  String? _deliveryState;

  // 1. Personal Info Controllers
  final TextEditingController _firstNameCtrl       = TextEditingController();
  final TextEditingController _middleNameCtrl      = TextEditingController();
  final TextEditingController _lastNameCtrl        = TextEditingController();
  final TextEditingController _nameInAadhaarCtrl   = TextEditingController();
  final TextEditingController _fatherFirstNameCtrl = TextEditingController();
  final TextEditingController _fatherMiddleNameCtrl= TextEditingController();
  final TextEditingController _fatherLastNameCtrl  = TextEditingController();
  final TextEditingController _motherFirstNameCtrl = TextEditingController();
  final TextEditingController _motherMiddleNameCtrl= TextEditingController();
  final TextEditingController _motherLastNameCtrl  = TextEditingController();
  final TextEditingController _voterIdRefCtrl      = TextEditingController();
  final TextEditingController _dobCtrl             = TextEditingController();
  final TextEditingController _aadhaarCtrl         = TextEditingController();

  // 2. Contact Info Controllers
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl  = TextEditingController();

  // 3. Address Controllers
  final TextEditingController _commHouseNoCtrl  = TextEditingController();
  final TextEditingController _commStreetCtrl   = TextEditingController();
  final TextEditingController _commTehsilCtrl   = TextEditingController();
  final TextEditingController _commPincodeCtrl  = TextEditingController();
  final TextEditingController _commDistrictCtrl = TextEditingController();
  final TextEditingController _commStateCtrl    = TextEditingController();
  final TextEditingController _commCityCtrl     = TextEditingController();

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

    // Auto-fill Name in Aadhaar from First, Middle, Last Name
    void updateNameInAadhaar() {
      final parts = [
        _firstNameCtrl.text.trim(),
        _middleNameCtrl.text.trim(),
        _lastNameCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');
      _nameInAadhaarCtrl.text = parts;
    }

    _firstNameCtrl.addListener(updateNameInAadhaar);
    _middleNameCtrl.addListener(updateNameInAadhaar);
    _lastNameCtrl.addListener(updateNameInAadhaar);

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
      final resGen = await ApiService.fetchApi('/voter/genders');
      final dGen = jsonDecode(resGen.body) as Map<String, dynamic>;
      if (dGen['success'] == true && dGen['genders'] != null && mounted) {
        setState(() => _genders = (dGen['genders'] as List).map((e) => e.toString()).toList());
      }
      final resStates = await ApiService.fetchApi('/voter/states');
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
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nameInAadhaarCtrl.dispose();
    _fatherFirstNameCtrl.dispose();
    _fatherMiddleNameCtrl.dispose();
    _fatherLastNameCtrl.dispose();
    _motherFirstNameCtrl.dispose();
    _motherMiddleNameCtrl.dispose();
    _motherLastNameCtrl.dispose();
    _voterIdRefCtrl.dispose();
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

  double get _payableAmount => 150.00;

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

  Future<void> _submitVoterForm() async {
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
        builder: (ctx) => VoterLoginModal(
          onSuccess: () {
            Navigator.pop(ctx);
            _submitVoterForm();
          },
        ),
      );
      return;
    }

    _razorpayService.openPaymentGateway(
      amount: _payableAmount,
      description: 'Apply New Voter Application',
      name: 'DZI Infinity',
      contact: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitVoterForm(auth: auth, razorpayPaymentId: response.paymentId ?? '');
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

  Future<void> _doSubmitVoterForm({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() => _loading = true);

    Map<String, dynamic> formData = {
      'voter_type':             'Apply New Voter',
      'first_name':             _firstNameCtrl.text.trim(),
      'middle_name':            _middleNameCtrl.text.trim(),
      'last_name':              _lastNameCtrl.text.trim(),
      'name_in_aadhaar':        _nameInAadhaarCtrl.text.trim(),
      'selected_parent':        _fatherHasContent ? 'Father' : (_motherHasContent ? 'Mother' : 'None'),
      'father_first_name':      _fatherHasContent ? _fatherFirstNameCtrl.text.trim() : '',
      'father_middle_name':     _fatherHasContent ? _fatherMiddleNameCtrl.text.trim() : '',
      'father_last_name':       _fatherHasContent ? _fatherLastNameCtrl.text.trim() : '',
      'mother_first_name':      _motherHasContent ? _motherFirstNameCtrl.text.trim() : '',
      'mother_middle_name':     _motherHasContent ? _motherMiddleNameCtrl.text.trim() : '',
      'mother_last_name':       _motherHasContent ? _motherLastNameCtrl.text.trim() : '',
      'voter_id_ref':           _voterIdRefCtrl.text.trim(),
      'dob_or_est_date':        _dobCtrl.text.trim(),
      'gender':                 _gender ?? '',
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'email_id':               _emailCtrl.text.trim(),
      'delivery_state':         _deliveryState ?? '',
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
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/voter/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '100';
      request.fields['form_id']   = '101';
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in formData.entries) {
        request.fields[entry.key] = entry.value.toString();
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
          _trackingId = data['tracking_id'] ?? 'TRK-VOT-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = 'TRK-VOT-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
              ? VoterSuccessView(
                  title: 'New Voter Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const VoterTopNavBar(title: 'New Voter ID'),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const VoterHeroCard(),
                                VoterCategoryTabs(
                                  selectedIndex: 0,
                                  onSelectTab: widget.onSelectTab,
                                ),
                                _buildStepsAccordion(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      VoterStickyBottomBar(
                        title: _expandedSectionIndex == 4 ? "Submit New Voter Form" : (_expandedSectionIndex == 3 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 4 ? "Proceed to secure application submission" : "Save and continue",
                        icon: _expandedSectionIndex == 4 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 4) {
                            setState(() => _expandedSectionIndex++);
                          } else {
                            _submitVoterForm();
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
        // 1. Personal Information
        VoterAccordionSection(
          index: 0,
          currentIndex: _expandedSectionIndex,
          title: '1. Personal Information',
          subtitle: 'Applicant details, Name in Aadhaar & Parent details',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildPersonalInfoStep(),
        ),

        // 2. Contact Information
        VoterAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Contact Information',
          subtitle: 'Mobile number, Email ID, and Delivery state',
          leadingIcon: Icons.phone_iphone_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildVoterResponsiveRow(
                context,
                buildVoterInput('Mobile Number *', _mobileCtrl, isNum: true, placeholder: '10-digit mobile number', prefixIcon: Icons.phone_iphone_outlined),
                buildVoterInput('Email ID *', _emailCtrl, placeholder: 'Email Address', prefixIcon: Icons.mail_outline),
              ),
              const SizedBox(height: 14),
              buildVoterDropdown(
                'Delivery State *',
                _deliveryState,
                _states,
                (v) => setState(() => _deliveryState = v),
                hint: 'Select State from Database',
                prefixIcon: Icons.location_on_outlined,
              ),
            ],
          ),
        ),

        // 3. Address for Communication
        VoterAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Address For Communication',
          subtitle: 'Fill delivery address details',
          leadingIcon: Icons.home_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildAddressStep(),
        ),

        // 4. Upload Required Documents (3 Docs Only)
        VoterAccordionSection(
          index: 3,
          currentIndex: _expandedSectionIndex,
          title: '4. Upload Required Documents',
          subtitle: 'Address Proof, ID Proof, and Applicant Photo',
          leadingIcon: Icons.cloud_upload_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildVoterDocUploadCard(
                title: 'Address Proof *',
                docKey: 'doc_address_proof',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_address_proof'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_address_proof')),
              ),
              buildVoterDocUploadCard(
                title: 'ID Proof *',
                docKey: 'doc_id_proof',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_id_proof'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_id_proof')),
              ),
              buildVoterDocUploadCard(
                title: 'Applicant Photo *',
                docKey: 'doc_photo',
                uploadedDocs: _uploadedDocs,
                onPick: () => _pickFile('doc_photo'),
                onRemove: () => setState(() => _uploadedDocs.remove('doc_photo')),
              ),
            ],
          ),
        ),

        // 5. Payment Details
        VoterAccordionSection(
          index: 4,
          currentIndex: _expandedSectionIndex,
          title: '5. Payment Details',
          subtitle: 'New voter application fee & processing',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterPaymentStepBox(
            title: 'New Voter Application Fee',
            subtitle: 'Includes Election Commission filing & verification',
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
        const Text("Applicant's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
        const SizedBox(height: 8),
        buildVoterThreeColumnRow(
          context,
          buildVoterInput('First Name *', _firstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
          buildVoterInput('Middle Name', _middleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
          buildVoterInput('Last Name', _lastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        // Name in Aadhaar (Auto-filled & Frozen)
        buildVoterInput(
          'Name in Aadhaar *',
          _nameInAadhaarCtrl,
          placeholder: 'Name as per Aadhaar (auto-filled)',
          prefixIcon: Icons.assignment_ind_outlined,
          readOnly: true,
        ),
        const SizedBox(height: 14),

        // Parent Details with Auto-Hide Logic
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
          buildVoterThreeColumnRow(
            context,
            buildVoterInput('Father First Name', _fatherFirstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
            buildVoterInput('Father Middle Name', _fatherMiddleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
            buildVoterInput('Father Last Name', _fatherLastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
          ),
          const SizedBox(height: 14),
        ],

        if (!_fatherHasContent) ...[
          const Text("Mother's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
          const SizedBox(height: 8),
          buildVoterThreeColumnRow(
            context,
            buildVoterInput('Mother First Name', _motherFirstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
            buildVoterInput('Mother Middle Name', _motherMiddleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
            buildVoterInput('Mother Last Name', _motherLastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
          ),
          const SizedBox(height: 14),
        ],

        buildVoterInput('Voter ID (Reference)', _voterIdRefCtrl, placeholder: 'Existing Voter ID / Family Reference (Optional)', prefixIcon: Icons.how_to_vote_outlined),
        const SizedBox(height: 14),

        buildVoterResponsiveRow(
          context,
          buildVoterDateField(context, 'Date of Birth *', _dobCtrl),
          buildVoterDropdown('Gender *', _gender, _genders, (v) => setState(() => _gender = v), prefixIcon: Icons.wc_outlined),
        ),
        const SizedBox(height: 14),

        buildVoterInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: '12-digit Aadhaar No.', prefixIcon: Icons.assignment_ind_outlined),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildVoterResponsiveRow(
          context,
          buildVoterInput('House No./Building *', _commHouseNoCtrl, placeholder: 'House/Flat No.', prefixIcon: Icons.home_outlined),
          buildVoterInput('Street/Area *', _commStreetCtrl, placeholder: 'Street name / Local area', prefixIcon: Icons.add_road_outlined),
        ),
        const SizedBox(height: 14),
        buildVoterResponsiveRow(
          context,
          buildVoterInput('Tehsil/Post *', _commTehsilCtrl, placeholder: 'Tehsil or Post office', prefixIcon: Icons.map_outlined),
          buildVoterInput('Pincode *', _commPincodeCtrl, isNum: true, placeholder: '6-digit pincode', prefixIcon: Icons.pin_drop_outlined),
        ),
        const SizedBox(height: 14),
        buildVoterThreeColumnRow(
          context,
          buildVoterInput('District *', _commDistrictCtrl, placeholder: 'District', prefixIcon: Icons.location_city_outlined),
          buildVoterInput('State *', _commStateCtrl, placeholder: 'State name', prefixIcon: Icons.public_outlined),
          buildVoterInput('City *', _commCityCtrl, placeholder: 'City', prefixIcon: Icons.location_on_outlined),
        ),
      ],
    );
  }
}
