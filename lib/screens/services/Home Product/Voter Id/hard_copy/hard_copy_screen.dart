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

class HardCopyScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const HardCopyScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<HardCopyScreen> createState() => _HardCopyScreenState();
}

class _HardCopyScreenState extends State<HardCopyScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // 1. Personal Info Controllers (3 Fields Only)
  final TextEditingController _voterIdNoCtrl = TextEditingController();
  final TextEditingController _mobileCtrl    = TextEditingController();
  final TextEditingController _aadhaarCtrl   = TextEditingController();

  // 2. Address Controllers
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

    _loadSavedUserData();
    _razorpayService.init();
  }

  Future<void> _loadSavedUserData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) return;
    try {
      final res = await _api.getUserSavedDetails(auth.userId!);
      if (res['success'] == true && res['details'] != null && mounted) {
        setState(() {
          _savedDetails = res['details'];
          if (_mobileCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _mobileCtrl.text = _savedDetails!['mobile'];
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
    _voterIdNoCtrl.dispose();
    _mobileCtrl.dispose();
    _aadhaarCtrl.dispose();
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
      description: 'Hard Copy PVC Voter ID',
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
      'voter_type':             'Hard Copy Voter ID',
      'epic_no':                _voterIdNoCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
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
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/voter/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '100';
      request.fields['form_id']   = '103';
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
          _trackingId = data['tracking_id'] ?? 'TRK-VOT-HRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = 'TRK-VOT-HRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
                  title: 'Hard Copy PVC Voter ID Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const VoterTopNavBar(title: 'Hard Copy Voter ID'),
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
                      VoterStickyBottomBar(
                        title: _expandedSectionIndex == 3 ? "Submit Hard Copy Application" : (_expandedSectionIndex == 2 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 3 ? "Proceed to secure physical PVC order" : "Save and continue",
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
        // 1. Personal Information (3 Fields Only)
        VoterAccordionSection(
          index: 0,
          currentIndex: _expandedSectionIndex,
          title: '1. Personal Information',
          subtitle: 'Epic No, Phone Number & Aadhaar Number',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            children: [
              buildVoterInput('Epic No in Voter ID *', _voterIdNoCtrl, placeholder: 'Enter 10-character EPIC No.', prefixIcon: Icons.credit_card_outlined),
              const SizedBox(height: 14),
              buildVoterResponsiveRow(
                context,
                buildVoterInput('Phone Number *', _mobileCtrl, isNum: true, placeholder: '10-digit mobile number', prefixIcon: Icons.phone_iphone_outlined),
                buildVoterInput('Aadhaar Number *', _aadhaarCtrl, isNum: true, placeholder: '12-digit Aadhaar No.', prefixIcon: Icons.assignment_ind_outlined),
              ),
            ],
          ),
        ),

        // 2. Address for Communication (Delivery Address)
        VoterAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Address For Communication',
          subtitle: 'Select delivery address and enter details',
          leadingIcon: Icons.home_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: _buildAddressStep(),
        ),

        // 3. Upload Document (Aadhaar Only)
        VoterAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Upload Required Document',
          subtitle: 'Aadhaar Card copy',
          leadingIcon: Icons.cloud_upload_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterDocUploadCard(
            title: 'Aadhaar *',
            docKey: 'doc_aadhaar',
            uploadedDocs: _uploadedDocs,
            onPick: () => _pickFile('doc_aadhaar'),
            onRemove: () => setState(() => _uploadedDocs.remove('doc_aadhaar')),
          ),
        ),

        // 4. Payment Details
        VoterAccordionSection(
          index: 3,
          currentIndex: _expandedSectionIndex,
          title: '4. Payment Details',
          subtitle: 'PVC card printing & delivery charges',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterPaymentStepBox(
            title: 'Hard Copy PVC Card Fee',
            subtitle: 'Includes high-grade PVC printing & doorstep delivery',
            amount: _payableAmount,
          ),
        ),
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
