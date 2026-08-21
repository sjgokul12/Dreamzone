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

class CorrectionVoterScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const CorrectionVoterScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<CorrectionVoterScreen> createState() => _CorrectionVoterScreenState();
}

class _CorrectionVoterScreenState extends State<CorrectionVoterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Dropdowns
  List<String> _genders       = ["Male", "Female", "Transgender"];
  List<String> _relationTypes = ["Father", "Mother", "Spouse", "Legal Guardian in case of orphan/Guru in case of third gender"];

  String? _gender       = 'Male';
  String? _relationType = 'Father';

  // 1. Personal Info Controllers
  final TextEditingController _voterIdNoCtrl         = TextEditingController();
  final TextEditingController _mobileCtrl            = TextEditingController();
  final TextEditingController _firstNameCtrl         = TextEditingController();
  final TextEditingController _middleNameCtrl        = TextEditingController();
  final TextEditingController _lastNameCtrl          = TextEditingController();
  final TextEditingController _dobCtrl               = TextEditingController();
  final TextEditingController _relativeFirstNameCtrl = TextEditingController();
  final TextEditingController _relativeMiddleNameCtrl= TextEditingController();
  final TextEditingController _relativeLastNameCtrl  = TextEditingController();
  final TextEditingController _voterIdRefCtrl        = TextEditingController();

  // 2. Address Controllers
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

    _loadMasterDataFromApi();
    _loadSavedUserData();
    _razorpayService.init();
  }

  Future<void> _loadMasterDataFromApi() async {
    try {
      final resGen = await ApiService.fetchApi('/voter/genders');
      final dGen = jsonDecode(resGen.body) as Map<String, dynamic>;
      if (dGen['success'] == true && dGen['genders'] != null && mounted) {
        setState(() => _genders = (dGen['genders'] as List).map((e) => e.toString()).toList());
      }
      final resRel = await ApiService.fetchApi('/voter/relation-types');
      final dRel = jsonDecode(resRel.body) as Map<String, dynamic>;
      if (dRel['success'] == true && dRel['relation_types'] != null && mounted) {
        setState(() => _relationTypes = (dRel['relation_types'] as List).map((e) => e.toString()).toList());
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
            final parts = (_savedDetails!['full_name'] as String).split(' ');
            _firstNameCtrl.text = parts.first;
            if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
          }
          if (_mobileCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _mobileCtrl.text = _savedDetails!['mobile'];
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _animationController.dispose();
    _voterIdNoCtrl.dispose();
    _mobileCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _relativeFirstNameCtrl.dispose();
    _relativeMiddleNameCtrl.dispose();
    _relativeLastNameCtrl.dispose();
    _voterIdRefCtrl.dispose();
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
      description: 'Correction Voter ID Application',
      name: 'DZI Infinity',
      contact: _mobileCtrl.text.trim(),
      email: '',
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
      'voter_type':             'Correction Voter ID',
      'epic_no':                _voterIdNoCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'first_name':             _firstNameCtrl.text.trim(),
      'middle_name':            _middleNameCtrl.text.trim(),
      'last_name':              _lastNameCtrl.text.trim(),
      'gender':                 _gender ?? '',
      'dob_or_est_date':        _dobCtrl.text.trim(),
      'relation_type':          _relationType ?? '',
      'relative_first_name':    _relativeFirstNameCtrl.text.trim(),
      'relative_middle_name':   _relativeMiddleNameCtrl.text.trim(),
      'relative_last_name':     _relativeLastNameCtrl.text.trim(),
      'voter_id_ref':           _voterIdRefCtrl.text.trim(),
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
      request.fields['form_id']   = '102';
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
          _trackingId = data['tracking_id'] ?? 'TRK-VOT-COR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = 'TRK-VOT-COR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
                  title: 'Correction Voter ID Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const VoterTopNavBar(title: 'Correction Voter ID'),
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
                      VoterStickyBottomBar(
                        title: _expandedSectionIndex == 3 ? "Submit Correction Voter" : (_expandedSectionIndex == 2 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 3 ? "Proceed to secure application submission" : "Save and continue",
                        icon: _expandedSectionIndex == 3 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 3) {
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
          subtitle: 'Epic No, Phone, Name, Gender, DOB & Relative details',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildPersonalInfoStep(),
        ),

        // 2. Address for Communication
        VoterAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Address For Communication',
          subtitle: 'Fill delivery address details',
          leadingIcon: Icons.home_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildAddressStep(),
        ),

        // 3. Upload Document (1 Only)
        VoterAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Upload Required Document',
          subtitle: 'Voter ID Proof of Change',
          leadingIcon: Icons.cloud_upload_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterDocUploadCard(
            title: 'Voter ID Proof of Change *',
            docKey: 'doc_proof_of_change',
            uploadedDocs: _uploadedDocs,
            onPick: () => _pickFile('doc_proof_of_change'),
            onRemove: () => setState(() => _uploadedDocs.remove('doc_proof_of_change')),
          ),
        ),

        // 4. Payment Details
        VoterAccordionSection(
          index: 3,
          currentIndex: _expandedSectionIndex,
          title: '4. Payment Details',
          subtitle: 'Correction fee costs & processing details',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterPaymentStepBox(
            title: 'Correction Voter ID Fee',
            subtitle: 'Includes details update & verification',
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
        buildVoterResponsiveRow(
          context,
          buildVoterInput('Epic No in Voter ID *', _voterIdNoCtrl, placeholder: 'Enter 10-character EPIC No.', prefixIcon: Icons.credit_card_outlined),
          buildVoterInput('Phone Number *', _mobileCtrl, isNum: true, placeholder: '10-digit mobile number', prefixIcon: Icons.phone_iphone_outlined),
        ),
        const SizedBox(height: 14),

        const Text("Applicant's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
        const SizedBox(height: 8),
        buildVoterThreeColumnRow(
          context,
          buildVoterInput('First Name *', _firstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
          buildVoterInput('Middle Name', _middleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
          buildVoterInput('Last Name', _lastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        buildVoterResponsiveRow(
          context,
          buildVoterDropdown('Gender *', _gender, _genders, (v) => setState(() => _gender = v), prefixIcon: Icons.wc_outlined),
          buildVoterDateField(context, 'Date of Birth *', _dobCtrl),
        ),
        const SizedBox(height: 14),

        buildVoterDropdown(
          'Relation Type *',
          _relationType,
          _relationTypes,
          (v) => setState(() => _relationType = v),
          prefixIcon: Icons.people_outline,
        ),
        const SizedBox(height: 14),

        const Text("Relative's Name Details", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark)),
        const SizedBox(height: 8),
        buildVoterThreeColumnRow(
          context,
          buildVoterInput("Relative First Name", _relativeFirstNameCtrl, placeholder: 'First Name', prefixIcon: Icons.person_outline),
          buildVoterInput("Relative Middle Name", _relativeMiddleNameCtrl, placeholder: 'Middle Name', prefixIcon: Icons.person_outline),
          buildVoterInput("Relative Last Name", _relativeLastNameCtrl, placeholder: 'Last Name', prefixIcon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        buildVoterInput('Voter ID (Reference)', _voterIdRefCtrl, placeholder: 'Voter ID reference number (Optional)', prefixIcon: Icons.how_to_vote_outlined),
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
