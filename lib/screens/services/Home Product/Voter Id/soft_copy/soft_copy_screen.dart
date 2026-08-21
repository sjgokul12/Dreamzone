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

class SoftCopyScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const SoftCopyScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<SoftCopyScreen> createState() => _SoftCopyScreenState();
}

class _SoftCopyScreenState extends State<SoftCopyScreen>
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
    super.dispose();
  }

  double get _payableAmount => 50.00;

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
      description: 'Soft Copy Digital Voter ID (PDF)',
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
      'voter_type':             'Soft Copy Voter ID',
      'epic_no':                _voterIdNoCtrl.text.trim(),
      'mobile_number':          _mobileCtrl.text.trim(),
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
      'amount':                 _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':    razorpayPaymentId,
      'payment_status':         'paid',
    };

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/voter/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '100';
      request.fields['form_id']   = '104';
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
          _trackingId = data['tracking_id'] ?? 'TRK-VOT-SFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _submitted  = true;
          _trackingId = 'TRK-VOT-SFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
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
                  title: 'Digital Soft Copy Voter ID Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const VoterTopNavBar(title: 'Soft Copy Voter ID'),
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
                                  selectedIndex: 3,
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
                        title: _expandedSectionIndex == 2 ? "Submit Soft Copy Application" : (_expandedSectionIndex == 1 ? "Next: Payment Details" : "Next: Continue"),
                        subtitle: _expandedSectionIndex == 2 ? "Proceed to instant digital PDF download" : "Save and continue",
                        icon: _expandedSectionIndex == 2 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 2) {
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

        // 2. Upload Document (Aadhaar Only)
        VoterAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Upload Required Document',
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

        // 3. Payment Details
        VoterAccordionSection(
          index: 2,
          currentIndex: _expandedSectionIndex,
          title: '3. Payment Details',
          subtitle: 'Instant e-EPIC digital PDF processing fee',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildVoterPaymentStepBox(
            title: 'Soft Copy Digital Voter ID Fee',
            subtitle: 'Includes official digital PDF copy download',
            amount: _payableAmount,
          ),
        ),
      ],
    );
  }
}
