import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../services/dth_api_service.dart';
import '../../../../services/bbps_invoice_pdf_service.dart';
import '../../../../core/payment/razorpay_service.dart';
import '../bbps_receipt_screen.dart';

/// Convenient alias so both `DTH` and `DTHScreen` can be used.
typedef DTH = DTHScreen;


class DTHScreen extends StatefulWidget {
  const DTHScreen({super.key});

  @override
  State<DTHScreen> createState() => _DTHScreenState();
}

class _DTHScreenState extends State<DTHScreen> with TickerProviderStateMixin {
  // Premium Purple Theme Palette
  static const Color primaryPurple = Color(0xFF7F00FF);
  static const Color primaryDark = Color(0xFF5E00C9);
  static const Color accentViolet = Color(0xFFE100FF);
  static const Color accentRed = Color(0xFFFF6B00);
  static const Color bgGradientEnd = Color(0xFFF9FAFB);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF8FAFC);

  // Form Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _customerIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  // Track expanded assurance tile
  int? _expandedAssuranceIndex;

  // Operators dynamically loaded from backend database (/api/dth/operators)
  List<Map<String, dynamic>> _operators = [];
  bool _operatorsLoading = true;
  String? _operatorsError;

  // Fallback operators matching official RoundPay SPKey codes (51, 53, 54, 55, 56)
  static const List<Map<String, dynamic>> _defaultOperators = [
    {'id': '51', 'spkey': '51', 'code': 'AIRTEL_DTH', 'name': 'Airtel Digital TV', 'label': 'Airtel Digital TV'},
    {'id': '53', 'spkey': '53', 'code': 'DISH_TV', 'name': 'Dish TV', 'label': 'Dish TV'},
    {'id': '54', 'spkey': '54', 'code': 'SUN_DIRECT', 'name': 'Sun Direct', 'label': 'Sun Direct'},
    {'id': '55', 'spkey': '55', 'code': 'TATA_SKY', 'name': 'Tata Sky', 'label': 'Tata Sky'},
    {'id': '56', 'spkey': '56', 'code': 'VIDEOCON_D2H', 'name': 'Videocon D2h', 'label': 'Videocon D2h'},
  ];

  // Selected operator
  Map<String, dynamic>? _selectedOperator;

  // Customer Info & Plans Loading State
  bool _fetchingCustomerInfo = false;
  Map<String, dynamic>? _customerInfo;
  String? _detectedCircle;

  bool _fetchingPlans = false;
  List<Map<String, dynamic>> _dthPlans = [];

  // Submission State
  bool _submitting = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  // Razorpay Service
  final RazorpayService _razorpayService = RazorpayService();

  // Operator icon mapping
  static IconData _iconForOperator(String code, String label) {
    final key = '${code}_$label'.toLowerCase();
    if (key.contains('airtel')) return Icons.tv_rounded;
    if (key.contains('dish')) return Icons.satellite_alt_rounded;
    if (key.contains('sun')) return Icons.wb_sunny_rounded;
    if (key.contains('tata') || key.contains('sky') || key.contains('play')) {
      return Icons.live_tv_rounded;
    }
    if (key.contains('videocon') || key.contains('d2h')) {
      return Icons.connected_tv_rounded;
    }
    if (key.contains('reliance')) return Icons.personal_video_rounded;
    return Icons.tv_rounded;
  }

  static Color _colorForOperator(String code, String label) {
    final key = '${code}_$label'.toLowerCase();
    if (key.contains('airtel')) return const Color(0xFFE11D48);
    if (key.contains('dish')) return const Color(0xFF0284C7);
    if (key.contains('sun')) return const Color(0xFFF59E0B);
    if (key.contains('tata') || key.contains('sky') || key.contains('play')) {
      return const Color(0xFF7C3AED);
    }
    if (key.contains('videocon') || key.contains('d2h')) {
      return const Color(0xFF10B981);
    }
    if (key.contains('reliance')) return const Color(0xFF2563EB);
    return primaryPurple;
  }

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _fetchOperatorsFromBackend();
  }

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    _amountCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchOperatorsFromBackend() async {
    setState(() => _operatorsLoading = true);
    try {
      final res = await ApiService.fetchApi('/dth/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null && (data['operators'] as List).isNotEmpty) {
        final rawList = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _operators = rawList;
            _operatorsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _operators = List.from(_defaultOperators);
            _operatorsLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _operators = List.from(_defaultOperators);
          _operatorsLoading = false;
        });
      }
    }
  }

  // Auto-Detect Operator on Typing
  Future<void> _autoDetectOperator() async {
    final customerId = _customerIdCtrl.text.trim();
    if (customerId.length < 5) return;

    try {
      final opResult = await DthApiService.fetchOperatorAndCircle(customerId);
      if (opResult['success'] == true && opResult['operator'] != null && opResult['operator'].toString().isNotEmpty) {
        final detectedOpStr = opResult['operator'].toString().toUpperCase();
        _detectedCircle = opResult['circle']?.toString();

        if (mounted) {
          setState(() {
            for (var op in _operators) {
              final label = (op['label'] ?? op['name'] ?? '').toString().toUpperCase();
              final code = (op['code'] ?? '').toString().toUpperCase();
              if (label.contains(detectedOpStr) || code.contains(detectedOpStr) ||
                  (detectedOpStr.contains('AIRTEL') && label.contains('AIRTEL')) ||
                  (detectedOpStr.contains('TATA') && (label.contains('TATA') || label.contains('SKY'))) ||
                  (detectedOpStr.contains('DISH') && label.contains('DISH')) ||
                  (detectedOpStr.contains('SUN') && label.contains('SUN')) ||
                  ((detectedOpStr.contains('VIDEOCON') || detectedOpStr.contains('D2H')) && (label.contains('VIDEOCON') || label.contains('D2H')))) {
                _selectedOperator = op;
                break;
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  // Action 1: Fetch & Show Live DTH Customer Info Modal / Sheet
  Future<void> _handleFetchCustomerInfo() async {
    final customerId = _customerIdCtrl.text.trim();
    if (customerId.isEmpty) {
      _showSnackBar('Please enter Customer ID first', isError: true);
      return;
    }
    if (_selectedOperator == null) {
      _showSnackBar('Please select an Operator first', isError: true);
      return;
    }

    setState(() => _fetchingCustomerInfo = true);

    final opName = _selectedOperator!['label']?.toString() ?? _selectedOperator!['name']?.toString() ?? '';
    final result = await DthApiService.fetchCustomerInfo(
      customerId: customerId,
      operatorNameOrCode: opName,
    );

    if (mounted) {
      setState(() {
        _fetchingCustomerInfo = false;
        if (result['customer_info'] != null) {
          _customerInfo = Map<String, dynamic>.from(result['customer_info']);
        }
      });

      if (_customerInfo != null) {
        _showCustomerInfoBottomSheet(_customerInfo!);
      } else {
        _showSnackBar(result['message']?.toString() ?? 'Could not fetch customer info', isError: true);
      }
    }
  }

  // Bottom Sheet for DTH Customer Info
  void _showCustomerInfoBottomSheet(Map<String, dynamic> info) {
    final name = info['customer_name']?.toString() ?? 'Subscriber';
    final vc = info['customer_id']?.toString() ?? _customerIdCtrl.text.trim();
    final rmn = info['rmn']?.toString() ?? '';
    final status = info['status']?.toString() ?? 'Active';
    final balance = info['current_balance']?.toString() ?? '₹ 0.00';
    final monthly = info['monthly_recharge']?.toString() ?? '';
    final nextDate = info['next_recharge_date']?.toString() ?? '';
    final plan = info['plan_name']?.toString() ?? 'Active Plan';
    final address = info['address']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: primaryPurple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DTH Customer Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'Live subscriber details',
                            style: const TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Highlight Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F00FF), Color(0xFF5E00C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 12, color: Colors.amberAccent),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'VC / Customer ID: $vc',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                    ),
                    if (rmn.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Registered Mobile: $rmn',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Detail Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Current Balance', balance, Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
                    if (monthly.isNotEmpty) ...[
                      const Divider(height: 20, color: borderColor),
                      _buildModalRow('Monthly Recharge', monthly, Icons.calendar_month_rounded, primaryPurple),
                    ],
                    if (nextDate.isNotEmpty) ...[
                      const Divider(height: 20, color: borderColor),
                      _buildModalRow('Next Due Date', nextDate, Icons.event_available_rounded, const Color(0xFFF59E0B)),
                    ],
                    if (plan.isNotEmpty) ...[
                      const Divider(height: 20, color: borderColor),
                      _buildModalRow('Current Pack', plan, Icons.tv_rounded, primaryPurple),
                    ],
                    if (address.isNotEmpty) ...[
                      const Divider(height: 20, color: borderColor),
                      _buildModalRow('Address', address, Icons.location_on_rounded, textMuted),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1-Tap Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final numericMonthly = monthly.replaceAll(RegExp(r'[^0-9.]'), '');
                    if (numericMonthly.isNotEmpty) {
                      setState(() => _amountCtrl.text = numericMonthly);
                      _showSnackBar('Recharge amount set to ₹$numericMonthly');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    monthly.isNotEmpty ? 'Recharge Monthly Plan ($monthly)' : 'Use This Customer ID',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Action 2: Fetch & Show DTH Plans Modal
  Future<void> _handleFetchDthPlans() async {
    if (_selectedOperator == null) {
      _showSnackBar('Please select an Operator first', isError: true);
      return;
    }

    final opName = _selectedOperator!['label']?.toString() ?? _selectedOperator!['name']?.toString() ?? '';

    setState(() => _fetchingPlans = true);
    _dthPlans = await DthApiService.fetchPlans(opName);
    if (mounted) setState(() => _fetchingPlans = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DthPlansBottomSheet(
        operatorName: opName,
        plans: _dthPlans,
        onSelectPlan: (plan) {
          Navigator.pop(ctx);
          final price = plan['price']?.toString() ?? '';
          setState(() {
            _amountCtrl.text = price;
          });
          _showSnackBar('Selected ${plan['plan_name']} (₹$price)');
        },
      ),
    );
  }

  // Submit Recharge
  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOperator == null) {
      _showSnackBar('Please select a DTH operator', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnackBar('Please login to recharge', isError: true);
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'DTH Recharge – ${_selectedOperator!['label'] ?? 'Payment'}',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitDth(auth: auth, razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _showSnackBar('Payment failed: ${response.message ?? "Unknown error"}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitDth({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() { _submitting = true; _resultStatus = null; });

    try {
      final res = await ApiService.postApi('/dth/pay', {
        'user_id':             auth.userId,
        'customer_id':         _customerIdCtrl.text.trim(),
        'operator_id':         _selectedOperator!['spkey']?.toString() ?? _selectedOperator!['id']?.toString() ?? '',
        'operator_name':       _selectedOperator!['label']?.toString() ?? _selectedOperator!['name']?.toString() ?? '',
        'amount':              _amountCtrl.text.trim(),
        'razorpay_payment_id': razorpayPaymentId,
        'payment_status':      'paid',
      });

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage = (data['message']?.toString() ??
              (_resultStatus == 'success'
                  ? 'DTH Recharge submitted successfully!'
                  : 'DTH Recharge failed. Please try again.')).replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim();
          _merchantTxnId = data['merchant_txn_id']?.toString() ??
              'DTH${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'pending';
          _resultMessage =
              "Couldn't confirm the recharge status right now. Please check status in a moment.";
          _merchantTxnId = 'DTH${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Operator Brand Picker Sheet
  void _openOperatorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select DTH Operator',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap your TV provider to continue',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.connected_tv_rounded, color: primaryPurple, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_operatorsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                  ),
                )
              else if (_operatorsError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(_operatorsError!, style: const TextStyle(color: accentRed)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.3,
                  ),
                  itemCount: _operators.length,
                  itemBuilder: (context, index) {
                    final op = _operators[index];
                    final isSelected = _selectedOperator != null &&
                        (op['spkey']?.toString() == _selectedOperator!['spkey']?.toString() ||
                         op['code']?.toString() == _selectedOperator!['code']?.toString());
                    final code = op['code']?.toString() ?? '';
                    final label = op['label']?.toString() ?? op['name']?.toString() ?? '';
                    final Color brandColor = _colorForOperator(code, label);
                    final IconData brandIcon = _iconForOperator(code, label);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOperator = op;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? brandColor.withValues(alpha: 0.12) : inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? brandColor : borderColor,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(brandIcon, color: brandColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSelected ? 'Selected ✓' : 'Tap to select',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? brandColor : textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _resultStatus != null
                    ? _buildResultView()
                    : Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildIntegratedTopHeader(context),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18),
                                  _buildQuickPillsRow(),
                                  const SizedBox(height: 20),
                                  _buildFormCard(),
                                  const SizedBox(height: 24),
                                  _buildSubmitButton(),
                                  const SizedBox(height: 24),
                                  _buildAssuranceListCard(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Top Header
  Widget _buildIntegratedTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, primaryDark, accentViolet],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'BBPS Assured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      TextSpan(
                        text: 'RECHARGE YOUR ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: '(DTH)',
                        style: TextStyle(color: Color(0xFFFFD1D1), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DTH Service Portal',
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your Customer ID & Select Operator to check plans & info',
                              style: TextStyle(
                                fontSize: 13,
                                color: textDark,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.satellite_alt_rounded,
                          color: primaryPurple,
                          size: 26,
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
    );
  }

  // Quick Pills
  Widget _buildQuickPillsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPillItem(Icons.badge_rounded, 'Customer ID'),
          _buildPillItem(Icons.grid_view_rounded, 'Operators'),
          _buildPillItem(Icons.person_search_rounded, 'Customer Info'),
          _buildPillItem(Icons.bolt_rounded, 'DTH Plans'),
        ],
      ),
    );
  }

  Widget _buildPillItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryPurple.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryPurple, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  // Main Form Card
  Widget _buildFormCard() {
    final selectedLabel = _selectedOperator != null
        ? (_selectedOperator!['label']?.toString() ??
            _selectedOperator!['name']?.toString() ??
            'Unknown')
        : null;

    final selectedCode = _selectedOperator?['code']?.toString() ?? '';
    final Color selectedColor = _selectedOperator != null
        ? _colorForOperator(selectedCode, selectedLabel ?? '')
        : const Color(0xFF94A3B8);
    final IconData selectedIcon = _selectedOperator != null
        ? _iconForOperator(selectedCode, selectedLabel ?? '')
        : Icons.tv_off_rounded;

    // Check if Customer ID and Operator are both entered/selected
    final bool isReadyForActions =
        _customerIdCtrl.text.trim().isNotEmpty && _selectedOperator != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CUSTOMER ID FIELD
          const Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                '1. Customer ID / VC Number',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customerIdCtrl,
            keyboardType: TextInputType.text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: InputDecoration(
              hintText: 'Enter your DTH Customer ID / VC Number',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.subtitles_rounded, color: primaryPurple, size: 20),
              suffixIcon: _customerIdCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                      onPressed: () {
                        setState(() {
                          _customerIdCtrl.clear();
                          _customerInfo = null;
                        });
                      },
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2.0),
              ),
            ),
            onChanged: (val) {
              setState(() {});
              if (val.trim().length >= 6) {
                _autoDetectOperator();
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your Customer ID';
              }
              if (value.trim().length < 4) {
                return 'Please enter a valid Customer ID';
              }
              return null;
            },
          ),

          const SizedBox(height: 22),

          // 2. OPERATOR SELECTION FIELD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 18, color: primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    '2. DTH Operator',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              if (_detectedCircle != null && _detectedCircle!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📍 $_detectedCircle',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Operator selector box
          InkWell(
            onTap: _openOperatorPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedOperator != null ? primaryPurple : borderColor,
                  width: _selectedOperator != null ? 1.5 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(selectedIcon, color: selectedColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLabel ?? 'Select Operator',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selectedLabel == null ? FontWeight.w400 : FontWeight.w700,
                            color: selectedLabel == null ? const Color(0xFF94A3B8) : textDark,
                          ),
                        ),
                        Text(
                          selectedLabel != null ? 'Tap to change provider' : 'Choose Airtel, Dish TV, Tata Sky etc.',
                          style: const TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedLabel != null ? 'Change' : 'Select',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. TWO BIG PROMINENT BUTTONS: DTH CUSTOMER INFO & DTH PLANS
          // HIDDEN until Customer ID and Operator are both entered
          if (isReadyForActions) ...[
            const SizedBox(height: 24),
            _buildTwoBigActionButtons(),
          ],

          const SizedBox(height: 24),

          // 4. RECHARGE AMOUNT FIELD
          const Row(
            children: [
              Icon(Icons.currency_rupee_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                '3. Recharge Amount (₹)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter amount e.g. 299 or select from plans',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2.0),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the recharge amount';
              }
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Quick amount chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [199, 299, 399, 499, 649, 999, 1499].map((amt) {
              final isCurrent = _amountCtrl.text == amt.toString();
              return InkWell(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? primaryPurple : primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCurrent ? primaryPurple : primaryPurple.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '₹$amt',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : primaryPurple,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 2 BIG PROMINENT BUTTONS WIDGET (DTH Customer Info & DTH Plans)
  Widget _buildTwoBigActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // BIG BUTTON 1: DTH Customer Info
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fetchingCustomerInfo ? null : _handleFetchCustomerInfo,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFC4B5FD), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: _fetchingCustomerInfo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.person_search_rounded, color: Colors.white, size: 18),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF7C3AED), size: 14),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Customer Info',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Balance & Due Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // BIG BUTTON 2: DTH Plans
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fetchingPlans ? null : _handleFetchDthPlans,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                              child: _fetchingPlans
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 14),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'DTH Plans',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Offers & Packages',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Submit Button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
        ),
        onPressed: _submitting ? null : _handleProceed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _submitting
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [const Color(0xFFFF6B00), const Color(0xFFE65100)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Pay Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Result View (replaces form after submission)
  Widget _buildResultView() {
    final isSuccess = _resultStatus == 'success';
    final isPending = _resultStatus == 'pending';
    final Color statusColor = isSuccess
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    final IconData statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.cancel_rounded;
    final String statusTitle = isSuccess
        ? 'DTH Recharge Successful!'
        : isPending
            ? 'Processing…'
            : 'Recharge Failed';
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'DTH Recharge',
      operatorName: _selectedOperator?['name']?.toString() ?? 'DTH Operator',
      accountNumber: _customerIdCtrl.text.trim(),
      customerName: _customerInfo?['customerName']?.toString() ?? _customerInfo?['name']?.toString() ?? '',
      merchantTxnId: _merchantTxnId ?? 'DTH${now.millisecondsSinceEpoch}',
      dateTimeStr: dtStr,
      amount: paidAmt,
      status: isSuccess ? 'Success' : (isPending ? 'Pending' : 'Failed'),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Transaction Reference ID',
                    style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _merchantTxnId ?? '—',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Download / View Bill Receipt & Share Buttons ──
            if (isSuccess || isPending) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 20),
                  label: const Text('View & Download Bill Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => BbpsInvoicePdfService.shareToWhatsApp(receipt),
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => BbpsInvoicePdfService.shareViaEmail(receipt),
                      icon: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
                      label: const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryPurple,
                        side: const BorderSide(color: primaryPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _resultStatus = null;
                    _resultMessage = null;
                    _merchantTxnId = null;
                    _customerIdCtrl.clear();
                    _amountCtrl.clear();
                    _selectedOperator = null;
                    _customerInfo = null;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'New Recharge',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Assurance Card
  Widget _buildAssuranceListCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildClickableAssuranceTile(
            index: 0,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Instant Processing',
            subtitle: 'Instant TV channel activation in real-time',
            detailText:
                '⚡ Real-time direct bill settlement and immediate TV signal refresh with your DTH provider.',
          ),
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
          _buildClickableAssuranceTile(
            index: 1,
            icon: Icons.shield_rounded,
            color: const Color(0xFF10B981),
            title: '100% BBPS Secure Payment',
            subtitle: 'Encrypted transactions protected by BBPS',
            detailText:
                '🛡️ End-to-end 256-bit SSL encrypted transaction authorized by National Payments Corporation of India.',
          ),
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
          _buildClickableAssuranceTile(
            index: 2,
            icon: Icons.receipt_long_rounded,
            color: primaryPurple,
            title: 'Instant Digital Receipt',
            subtitle: 'Official digital proof of DTH recharge',
            detailText:
                '🧾 Download official BBPS bill receipt instantly after successful payment.',
          ),
        ],
      ),
    );
  }

  Widget _buildClickableAssuranceTile({
    required int index,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String detailText,
  }) {
    final isExpanded = _expandedAssuranceIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedAssuranceIndex = isExpanded ? null : index;
        });
      },
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: primaryPurple,
                  size: 22,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
                ),
                child: Text(
                  detailText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryDark,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── DTH PLANS BOTTOM SHEET MODAL (LIVE API & DB) ───────────────────────────
class _DthPlansBottomSheet extends StatefulWidget {
  final String operatorName;
  final List<Map<String, dynamic>> plans;
  final Function(Map<String, dynamic>) onSelectPlan;

  const _DthPlansBottomSheet({
    required this.operatorName,
    required this.plans,
    required this.onSelectPlan,
  });

  @override
  State<_DthPlansBottomSheet> createState() => _DthPlansBottomSheetState();
}

class _DthPlansBottomSheetState extends State<_DthPlansBottomSheet> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    // Extract unique categories from plans
    final Set<String> catSet = {'All'};
    for (var p in widget.plans) {
      final cat = p['category']?.toString() ?? p['validity']?.toString();
      if (cat != null && cat.isNotEmpty) {
        catSet.add(cat);
      }
    }
    final categories = catSet.toList();

    final filteredPlans = _selectedCategory == 'All'
        ? widget.plans
        : widget.plans.where((p) =>
            (p['category']?.toString() == _selectedCategory) ||
            (p['validity']?.toString() == _selectedCategory)).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.operatorName} Plans',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B4B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Choose a recharge package to auto-fill amount',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Chips
          if (categories.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: const Color(0xFF7F00FF),
                      backgroundColor: const Color(0xFFF8FAFC),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF64748B),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF7F00FF) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Plans List
          Expanded(
            child: filteredPlans.isEmpty
                ? const Center(
                    child: Text('No plans available for this selection', style: TextStyle(color: Color(0xFF64748B))),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredPlans.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final plan = filteredPlans[idx];
                      final name = plan['plan_name']?.toString() ?? 'Plan';
                      final price = plan['price']?.toString() ?? '0';
                      final validity = plan['validity']?.toString() ?? plan['category']?.toString() ?? 'Pack';
                      final channels = plan['channels']?.toString() ?? '';
                      final desc = plan['desc']?.toString() ?? '';
                      final lang = plan['language']?.toString() ?? '';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7F00FF).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          validity,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF7F00FF),
                                          ),
                                        ),
                                      ),
                                      if (lang.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            lang,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (channels.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '📺 $channels',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹$price',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7F00FF),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => widget.onSelectPlan(plan),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7F00FF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Select',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
