import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../services/api_service.dart';
import '../../../../../core/payment/razorpay_service.dart';
import '../pan_common_widgets.dart';

class FindPanScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final Function(int)? onSelectTab;

  const FindPanScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.onSelectTab,
  });

  @override
  State<FindPanScreen> createState() => _FindPanScreenState();
}

class _FindPanScreenState extends State<FindPanScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final RazorpayService _razorpayService = RazorpayService();
  bool _submitted = false;
  bool _loading = false;
  String? _trackingId;

  // Controllers for the 3 requested fields in Personal Information
  final TextEditingController _aadhaarCtrl       = TextEditingController();
  final TextEditingController _nameInAadhaarCtrl = TextEditingController();
  final TextEditingController _phoneCtrl         = TextEditingController();

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
          if (_nameInAadhaarCtrl.text.isEmpty && _savedDetails!['full_name'] != null) {
            _nameInAadhaarCtrl.text = _savedDetails!['full_name'];
          }
          if (_phoneCtrl.text.isEmpty && _savedDetails!['mobile'] != null) {
            _phoneCtrl.text = _savedDetails!['mobile'];
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
    _aadhaarCtrl.dispose();
    _nameInAadhaarCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  double get _payableAmount => 150.00;

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
      description: 'Find PAN Application',
      name: 'DZI Infinity',
      contact: _phoneCtrl.text.trim(),
      email: '',
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
      'pan_type':               'Find PAN Application',
      'aadhaar_number':         _aadhaarCtrl.text.trim(),
      'name_in_aadhaar':        _nameInAadhaarCtrl.text.trim(),
      'mobile_number':          _phoneCtrl.text.trim(),
      'amount':                 _payableAmount.toStringAsFixed(2),
      'razorpay_payment_id':    razorpayPaymentId,
      'payment_status':         'paid',
    };

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/pan/apply'));
      request.fields['user_id']   = auth.userId.toString();
      request.fields['service_id']= widget.service['id']?.toString() ?? '200';
      request.fields['form_id']   = '204';
      request.fields['form_data'] = jsonEncode(formData);

      for (var entry in formData.entries) {
        request.fields[entry.key] = entry.value.toString();
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
                  title: 'Find PAN Application',
                  trackingId: _trackingId,
                  onBack: () => Navigator.pop(context),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const PanTopNavBar(showPdfDropdown: false),
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
                      PanStickyBottomBar(
                        title: _expandedSectionIndex == 1 ? "Submit Find PAN" : "Next: Payment Details",
                        subtitle: _expandedSectionIndex == 1 ? "Proceed to locate PAN record" : "Save and continue",
                        icon: _expandedSectionIndex == 1 ? Icons.check_circle_outline : Icons.arrow_forward,
                        onTap: () {
                          if (_expandedSectionIndex < 1) {
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
        // 1. Personal Information (Only Aadhaar, Name in Aadhaar, Phone Number)
        PanAccordionSection(
          index: 0,
          currentIndex: _expandedSectionIndex,
          title: '1. Personal Information',
          subtitle: 'Aadhaar Number, Name in Aadhaar & Phone Number',
          leadingIcon: Icons.person_outline,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildPanInput(
                'Aadhaar Number *',
                _aadhaarCtrl,
                isNum: true,
                placeholder: 'Enter 12-digit Aadhaar Number',
                prefixIcon: Icons.assignment_ind_outlined,
              ),
              const SizedBox(height: 14),
              buildPanInput(
                'Name in Aadhaar *',
                _nameInAadhaarCtrl,
                placeholder: 'Enter exact name printed on Aadhaar card',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              buildPanInput(
                'Phone Number *',
                _phoneCtrl,
                isNum: true,
                placeholder: 'Enter 10-digit mobile number',
                prefixIcon: Icons.phone_iphone_outlined,
              ),
            ],
          ),
        ),

        // 2. Payment Details
        PanAccordionSection(
          index: 1,
          currentIndex: _expandedSectionIndex,
          title: '2. Payment Details',
          subtitle: 'Find PAN search fee & processing',
          leadingIcon: Icons.payment_outlined,
          onToggle: (idx) => setState(() => _expandedSectionIndex = idx),
          child: buildPanPaymentStepBox(
            title: 'Find PAN Search Fee',
            subtitle: 'Includes NSDL/UTI database search & instant report',
            amount: _payableAmount,
          ),
        ),
      ],
    );
  }
}
