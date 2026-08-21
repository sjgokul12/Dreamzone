import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../core/payment/razorpay_service.dart';
import 'postpaid_recharge_screen.dart';

class PrepaidRechargeScreen extends StatefulWidget {
  const PrepaidRechargeScreen({super.key});

  @override
  State<PrepaidRechargeScreen> createState() => _PrepaidRechargeScreenState();
}

class _PrepaidRechargeScreenState extends State<PrepaidRechargeScreen> {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color textSubdued = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _amountCtrl = TextEditingController();
  final ApiService _api = ApiService();

  // All data loaded dynamically from Python database API
  List<Map<String, dynamic>> _operators = [];
  List<String> _circles = [];
  String? _selectedOperator;
  String? _selectedCircle;

  bool _loadingOperators = true;
  bool _loadingCircles = true;
  bool _loadingPlans = false;
  List<Map<String, dynamic>> _livePlans = [];

  bool _submitting = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  final RazorpayService _razorpayService = RazorpayService();

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    setState(() {
      _loadingOperators = true;
      _loadingCircles = true;
    });

    try {
      final results = await Future.wait([
        _api.getRechargeOperators('prepaid'),
        _api.getRechargeCircles(),
      ]);

      final opRes = results[0];
      final circleRes = results[1];

      if (mounted) {
        setState(() {
          if (opRes['success'] == true && opRes['operators'] != null) {
            _operators = List<Map<String, dynamic>>.from(opRes['operators']);
            if (_operators.isNotEmpty && _selectedOperator == null) {
              _selectedOperator = _operators.first['label'];
            }
          }

          if (circleRes['success'] == true && circleRes['circles'] != null) {
            _circles = List<String>.from(circleRes['circles']);
            if (_circles.isNotEmpty && _selectedCircle == null) {
              _selectedCircle = _circles.first;
            }
          }

          _loadingOperators = false;
          _loadingCircles = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingOperators = false;
          _loadingCircles = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _amountCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _onMobileChanged(String value) {
    String clean = value.replaceAll('+91 ', '').replaceAll(' ', '').trim();
    if (clean.length == 10 && _operators.isNotEmpty) {
      final prefix = clean.substring(0, 2);
      for (final op in _operators) {
        final label = (op['label'] ?? '').toString().toLowerCase();
        if (['98', '99', '94'].contains(prefix) && label.contains('airtel')) {
          setState(() => _selectedOperator = op['label']);
          break;
        } else if (['63', '70', '79', '89'].contains(prefix) && label.contains('jio')) {
          setState(() => _selectedOperator = op['label']);
          break;
        } else if (['90', '91', '97'].contains(prefix) && (label.contains('vi') || label.contains('vodafone'))) {
          setState(() => _selectedOperator = op['label']);
          break;
        } else if (prefix == '94' && label.contains('bsnl')) {
          setState(() => _selectedOperator = op['label']);
          break;
        }
      }
    }
  }

  Future<void> _submitRecharge() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOperator == null || _selectedOperator!.isEmpty) {
      _showSnack('Please select an operator', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnack('Please login to recharge', isError: true);
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _showSnack('Please enter a valid recharge amount', isError: true);
      return;
    }

    final opData = _operators.firstWhere(
      (o) => o['label'] == _selectedOperator,
      orElse: () => {'id': _selectedOperator, 'label': _selectedOperator},
    );

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Prepaid Recharge – $_selectedOperator',
      name: 'DZI Infinity',
      contact: _mobileCtrl.text.replaceAll('+91 ', '').trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitRecharge(
          auth: auth,
          opData: opData,
          razorpayPaymentId: response.paymentId ?? '',
        );
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _showSnack('Payment cancelled or failed: ${response.message ?? ""}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitRecharge({
    required dynamic auth,
    required dynamic opData,
    required String razorpayPaymentId,
  }) async {
    setState(() {
      _submitting = true;
      _resultStatus = null;
    });

    try {
      final res = await ApiService.postApi('/recharge', {
        'user_id': auth.userId,
        'mobile_number': _mobileCtrl.text.replaceAll('+91 ', '').trim(),
        'operator_id': opData['id'] ?? opData['label'],
        'operator_name': _selectedOperator,
        'circle': _selectedCircle ?? '',
        'amount': _amountCtrl.text.trim(),
        'type': 'prepaid',
        'razorpay_payment_id': razorpayPaymentId,
        'payment_status': 'paid',
      }, timeoutSeconds: 30);

      final data = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage = (data['message'] ??
                  (_resultStatus == 'success'
                      ? 'Prepaid recharge completed successfully!'
                      : 'Recharge failed. Amount will be refunded if debited.'))
              .replaceAll('(TEST MODE)', '')
              .replaceAll('(TEST MODE - no real money moved)', '')
              .trim();
          _merchantTxnId = data['merchant_txn_id'] ??
              'DZI-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'failed';
          _resultMessage = 'Recharge processing error: $e';
        });
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showOperatorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Prepaid Operator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryDark),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: textSubdued),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_operators.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No operators found in database.', style: TextStyle(color: textSubdued)),
                ),
              )
            else
              ..._operators.map((op) {
                final isSel = op['label'] == _selectedOperator;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: isSel ? const Color(0xFFF5F3FF) : Colors.transparent,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      color: primaryPurple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    op['label'] ?? '',
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? primaryPurple : primaryDark,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle_rounded, color: primaryPurple)
                      : null,
                  onTap: () {
                    setState(() => _selectedOperator = op['label']);
                    Navigator.pop(ctx);
                  },
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCirclePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Circle / Region',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryDark),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: textSubdued),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_circles.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No circles found in database.', style: TextStyle(color: textSubdued)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _circles.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) {
                    final c = _circles[idx];
                    final isSel = c == _selectedCircle;
                    return ListTile(
                      title: Text(
                        c,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? primaryPurple : primaryDark,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: primaryPurple)
                          : null,
                      onTap: () {
                        setState(() => _selectedCircle = c);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBrowsePlans() async {
    final opData = _operators.firstWhere(
      (o) => o['label'] == _selectedOperator,
      orElse: () => {'code': _selectedOperator ?? '', 'id': _selectedOperator ?? ''},
    );
    final opCode = opData['code'] ?? opData['id'] ?? '';
    final circle = _selectedCircle ?? '';

    setState(() => _loadingPlans = true);

    try {
      final res = await _api.getRechargePlans(opCode, circle);
      if (mounted && res['success'] == true && res['plans'] != null) {
        setState(() {
          _livePlans = List<Map<String, dynamic>>.from(res['plans']);
          _loadingPlans = false;
        });
      } else {
        setState(() => _loadingPlans = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse Prepaid Plans',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: primaryDark),
                    ),
                    Text(
                      '${_selectedOperator ?? "Operator"} • ${_selectedCircle ?? "All India"}',
                      style: const TextStyle(fontSize: 12.5, color: textSubdued, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: textSubdued),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loadingPlans
                  ? const Center(child: CircularProgressIndicator(color: primaryPurple))
                  : _livePlans.isEmpty
                      ? const Center(
                          child: Text(
                            'No plans available from database for selected operator.',
                            style: TextStyle(color: textSubdued, fontSize: 13.5),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _livePlans.length,
                          itemBuilder: (ctx, idx) {
                            final p = _livePlans[idx];
                            final amt = p['amount']?.toString() ?? '0';
                            final validity = p['validity']?.toString() ?? 'Active';
                            final data = p['data']?.toString() ?? '';
                            final desc = p['description']?.toString() ?? p['desc']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '₹$amt',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: primaryDark,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                validity,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryPurple,
                                                ),
                                              ),
                                            ),
                                            if (data.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  data,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0284C7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            desc,
                                            style: const TextStyle(fontSize: 12.5, color: textSubdued, height: 1.3),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _amountCtrl.text = amt);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Select', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _resultStatus != null ? _buildResultView() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCFBFF), Color(0xFFF3EDFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: primaryPurple, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PREPAID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mobile Recharge',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instant recharge with live database operators & plans',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSubdued,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            right: -15,
            top: 25,
            child: Image.asset(
              'assets/Mobile.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.phone_android_rounded,
                size: 110,
                color: Color(0xFFDDD6FE),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch to Postpaid tab link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prepaid Connection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PostpaidRechargeScreen()),
                    );
                  },
                  icon: const Icon(Icons.sim_card_outlined, size: 16, color: primaryPurple),
                  label: const Text(
                    'Switch to Postpaid',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),

            // 1. Mobile Number
            const Text(
              'Mobile Number',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              onChanged: _onMobileChanged,
              validator: (v) {
                final clean = (v ?? '').replaceAll('+91 ', '').trim();
                if (clean.length != 10) return 'Enter a valid 10-digit mobile number';
                return null;
              },
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: primaryDark,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android_rounded, color: primaryPurple),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryPurple, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Operator Selector (Database Loaded)
            const Text(
              'Operator',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _loadingOperators ? null : _showOperatorPicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cell_tower_rounded, color: primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _loadingOperators
                            ? 'Loading operators from database...'
                            : (_selectedOperator ?? 'Select operator'),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedOperator != null ? primaryDark : textSubdued,
                        ),
                      ),
                    ),
                    if (_loadingOperators)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down_rounded, color: textSubdued),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Circle Selector (Database Loaded)
            const Text(
              'Circle / Region',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _loadingCircles ? null : _showCirclePicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _loadingCircles
                            ? 'Loading circles from database...'
                            : (_selectedCircle ?? 'Select circle'),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedCircle != null ? primaryDark : textSubdued,
                        ),
                      ),
                    ),
                    if (_loadingCircles)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down_rounded, color: textSubdued),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 4. Amount & Browse Plans
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recharge Amount',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: primaryDark,
                  ),
                ),
                InkWell(
                  onTap: _showBrowsePlans,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 14, color: primaryPurple),
                        SizedBox(width: 4),
                        Text(
                          'Browse Plans',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter an amount';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                return null;
              },
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryDark,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8, top: 12),
                  child: Text(
                    '₹',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryPurple),
                  ),
                ),
                hintText: 'Enter plan amount',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryPurple, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: primaryPurple.withValues(alpha: 0.4),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Proceed to Recharge',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final isSuccess = _resultStatus == 'success';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFE11D48),
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSuccess ? 'Recharge Successful!' : 'Recharge Failed',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            _resultMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: textSubdued, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _receiptRow('Transaction ID', _merchantTxnId ?? '-'),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _receiptRow('Mobile Number', _mobileCtrl.text.replaceAll('+91 ', '').trim()),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _receiptRow('Operator', _selectedOperator ?? '-'),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _receiptRow('Amount', '₹${_amountCtrl.text.trim()}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _resultStatus = null;
                  _resultMessage = null;
                  _amountCtrl.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Make Another Recharge', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: textSubdued)),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryDark)),
      ],
    );
  }
}
