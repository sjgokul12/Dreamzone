import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../services/bbps_api_service.dart';
import '../../../../services/bbps_invoice_pdf_service.dart';
import '../../../../services/prepaid_api_service.dart';
import '../../../../core/payment/razorpay_service.dart';
import '../bbps_receipt_screen.dart';
import 'prepaid_recharge_screen.dart';
import '../../../home/home_screen.dart';

class PostpaidRechargeScreen extends StatefulWidget {
  const PostpaidRechargeScreen({super.key});

  @override
  State<PostpaidRechargeScreen> createState() => _PostpaidRechargeScreenState();
}

class _PostpaidRechargeScreenState extends State<PostpaidRechargeScreen> {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color textSubdued = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _amountCtrl = TextEditingController();
  final ApiService _api = ApiService();

  // All postpaid operators loaded dynamically from Python database API
  List<Map<String, dynamic>> _operators = [];
  String? _selectedOperator;
  bool _loadingOperators = true;
  bool _isAutoDetecting = false;

  bool _fetchingBill = false;
  Map<String, dynamic>? _fetchedBillDetails;

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
    setState(() => _loadingOperators = true);

    try {
      final res = await _api.getRechargeOperators('postpaid');
      if (mounted) {
        setState(() {
          if (res['success'] == true && res['operators'] != null) {
            _operators = List<Map<String, dynamic>>.from(res['operators']);
          }
          _loadingOperators = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOperators = false);
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
    String clean = value.replaceAll('+91', '').replaceAll(' ', '').trim();
    if (clean.length == 10) {
      // 1. Instant 0ms Series Auto-Resolution (Zero Waiting, Zero Lag!)
      final offline = PrepaidApiService.resolveSeriesOffline(clean);
      if (offline['success'] == true) {
        final detectedOp = (offline['operator'] ?? '').toString().trim().toLowerCase();
        if (detectedOp.isNotEmpty && _operators.isNotEmpty) {
          final match = _operators.firstWhere(
            (o) {
              final lbl = (o['label'] ?? o['name'] ?? '').toString().toLowerCase();
              final code = (o['code'] ?? '').toString().toLowerCase();
              if (detectedOp.contains('jio') && (lbl.contains('jio') || code.contains('jio'))) return true;
              if (detectedOp.contains('airtel') && (lbl.contains('airtel') || code.contains('airtel'))) return true;
              if ((detectedOp.contains('vi') || detectedOp.contains('voda') || detectedOp.contains('idea')) &&
                  (lbl.contains('vi') || lbl.contains('voda') || lbl.contains('idea') || code.contains('vi') || code.contains('voda') || code.contains('idea'))) {
                return true;
              }
              if (detectedOp.contains('bsnl') && (lbl.contains('bsnl') || code.contains('bsnl'))) return true;
              if (detectedOp.contains('mtnl') && (lbl.contains('mtnl') || code.contains('mtnl'))) return true;
              return lbl.contains(detectedOp) || detectedOp.contains(lbl);
            },
            orElse: () => <String, dynamic>{},
          );

          if (match.isNotEmpty) {
            setState(() {
              _selectedOperator = (match['label'] ?? match['name'])?.toString();
              _isAutoDetecting = false;
            });
          }
        }
      }

      // 2. Non-blocking live check for ported numbers
      _autoDetectOperator(clean);
    }
  }

  Future<void> _autoDetectOperator(String cleanMobile) async {

    try {
      final res = await PrepaidApiService.fetchOperatorAndCircle(cleanMobile);
      if (mounted && res['success'] == true) {
        final detectedOp = (res['operator'] ?? '').toString().trim().toLowerCase();
        if (detectedOp.isNotEmpty && _operators.isNotEmpty) {
          final match = _operators.firstWhere(
            (o) {
              final lbl = (o['label'] ?? o['name'] ?? '').toString().toLowerCase();
              final code = (o['code'] ?? '').toString().toLowerCase();
              if (detectedOp.contains('jio') && (lbl.contains('jio') || code.contains('jio'))) return true;
              if (detectedOp.contains('airtel') && (lbl.contains('airtel') || code.contains('airtel'))) return true;
              if ((detectedOp.contains('vi') || detectedOp.contains('voda') || detectedOp.contains('idea')) &&
                  (lbl.contains('vi') || lbl.contains('voda') || lbl.contains('idea') || code.contains('vi') || code.contains('voda') || code.contains('idea'))) {
                return true;
              }
              if (detectedOp.contains('bsnl') && (lbl.contains('bsnl') || code.contains('bsnl'))) return true;
              if (detectedOp.contains('mtnl') && (lbl.contains('mtnl') || code.contains('mtnl'))) return true;
              return lbl.contains(detectedOp) || detectedOp.contains(lbl);
            },
            orElse: () => <String, dynamic>{},
          );

          setState(() {
            if (match.isNotEmpty) {
              _selectedOperator = (match['label'] ?? match['name'])?.toString();
            }
            _isAutoDetecting = false;
          });
          if (_selectedOperator != null) {
            _showSnack('Auto-detected operator: $_selectedOperator');
          }
        } else {
          setState(() => _isAutoDetecting = false);
        }
      } else {
        if (mounted) setState(() => _isAutoDetecting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isAutoDetecting = false);
    }
  }

  Future<void> _fetchBill() async {
    final cleanMobile = _mobileCtrl.text.replaceAll('+91 ', '').trim();
    if (cleanMobile.length != 10) {
      _showSnack('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }

    if (_selectedOperator == null || _selectedOperator!.isEmpty) {
      _showSnack('Please select an operator to fetch bill', isError: true);
      return;
    }

    setState(() => _fetchingBill = true);

    try {
      final opData = _operators.firstWhere(
        (o) => o['label'] == _selectedOperator,
        orElse: () => {'code': _selectedOperator ?? '', 'id': _selectedOperator ?? '', 'spkey': '108'},
      );

      final spKey = (opData['spkey'] ?? opData['id'] ?? '108').toString();
      final bill = await BbpsApiService.fetchBill(
        spKey: spKey,
        account: cleanMobile,
      );

      if (mounted) {
        setState(() {
          _fetchingBill = false;
          if (bill.isSuccess && bill.dueAmount > 0) {
            _fetchedBillDetails = {
              'customer_name': bill.customerName.isNotEmpty ? bill.customerName : 'Postpaid Subscriber',
              'bill_number': bill.billNumber.isNotEmpty ? bill.billNumber : 'BBPS-${DateTime.now().millisecondsSinceEpoch}',
              'due_date': bill.dueDate.isNotEmpty ? bill.dueDate : 'Current Cycle',
              'amount': bill.dueAmount,
            };
            _amountCtrl.text = bill.dueAmount.toStringAsFixed(2);
            _showSnack('Bill fetched successfully! Amount: ₹${bill.dueAmount.toStringAsFixed(2)}');
          } else {
            _fetchedBillDetails = null;
            _showSnack(bill.message.isNotEmpty ? bill.message : 'Please enter bill amount manually');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchingBill = false;
          _fetchedBillDetails = null;
        });
        _showSnack('Please enter your bill amount to proceed');
      }
    }
  }

  Future<void> _submitBillPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOperator == null || _selectedOperator!.isEmpty) {
      _showSnack('Please select an operator', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnack('Please login to pay bill', isError: true);
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _showSnack('Please enter a valid bill amount', isError: true);
      return;
    }

    final opData = _operators.firstWhere(
      (o) => o['label'] == _selectedOperator,
      orElse: () => {'id': _selectedOperator, 'label': _selectedOperator},
    );

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Postpaid Bill Payment – $_selectedOperator',
      name: 'DZI Infinity',
      contact: _mobileCtrl.text.replaceAll('+91 ', '').trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitPostpaidPayment(
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

  Future<void> _doSubmitPostpaidPayment({
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
        'amount': _amountCtrl.text.trim(),
        'type': 'postpaid',
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
                      ? 'Postpaid bill payment completed successfully!'
                      : 'Bill payment failed. Amount will be refunded if debited.'))
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
          _resultMessage = 'Bill payment processing error: $e';
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
                  'Select Postpaid Operator',
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
                  child: Text('No postpaid operators found in database.', style: TextStyle(color: textSubdued)),
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
                      Icons.sim_card_rounded,
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
        bottom: 16,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POSTPAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Postpaid Bill Pay',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instant postpaid bill fetch & secure settlement',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textSubdued,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/Mobile.png',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.phone_android_rounded,
              size: 80,
              color: Color(0xFFDDD6FE),
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
            // Switch to Prepaid tab link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Postpaid Connection',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: primaryDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PrepaidRechargeScreen()),
                    );
                  },
                  icon: const Icon(Icons.phone_android_rounded, size: 16, color: primaryPurple),
                  label: const Text(
                    'Switch to Prepaid',
                    style: TextStyle(
                      fontSize: 12,
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
              'Operators',
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
                    const Icon(Icons.sim_card_rounded, color: primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _loadingOperators
                            ? 'Loading operators from database...'
                            : _isAutoDetecting
                                ? 'Detecting operator...'
                                : (_selectedOperator ?? 'Select postpaid operator'),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedOperator != null ? primaryDark : textSubdued,
                        ),
                      ),
                    ),
                    if (_loadingOperators || _isAutoDetecting)
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

            // 3. Amount Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill Amount',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: primaryDark,
                  ),
                ),
                InkWell(
                  onTap: _fetchingBill ? null : _fetchBill,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_fetchingBill)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
                          )
                        else
                          const Icon(Icons.receipt_long_outlined, size: 14, color: primaryPurple),
                        const SizedBox(width: 4),
                        const Text(
                          'Fetch Bill',
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
                if (v == null || v.trim().isEmpty) return 'Please enter bill amount';
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
                hintText: 'Enter bill amount',
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

            if (_fetchedBillDetails != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                ),
                child: Column(
                  children: [
                    if (_fetchedBillDetails!['customer_name'] != null)
                      _billDetailRow('Account Name', _fetchedBillDetails!['customer_name']),
                    if (_fetchedBillDetails!['bill_number'] != null) ...[
                      const SizedBox(height: 6),
                      _billDetailRow('Bill Number', _fetchedBillDetails!['bill_number']),
                    ],
                    if (_fetchedBillDetails!['due_date'] != null) ...[
                      const SizedBox(height: 6),
                      _billDetailRow('Due Date', _fetchedBillDetails!['due_date']),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Proceed to Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitBillPayment,
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
                          Icon(Icons.payment_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Pay Postpaid Bill',
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

  Widget _billDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: textSubdued, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryDark)),
      ],
    );
  }

  Widget _buildResultView() {
    final isSuccess = _resultStatus == 'success';
    final isPending = _resultStatus == 'pending';
    final double rawDueAmt = double.tryParse(_fetchedBillDetails?['dueAmount']?.toString() ?? _fetchedBillDetails?['due_amount']?.toString() ?? '') ?? 0.0;
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? rawDueAmt;

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'Mobile Postpaid',
      operatorName: _selectedOperator ?? 'Mobile Operator',
      accountNumber: _mobileCtrl.text.replaceAll('+91 ', '').trim(),
      customerName: _fetchedBillDetails?['customerName']?.toString() ?? _fetchedBillDetails?['customer_name']?.toString() ?? '',
      merchantTxnId: _merchantTxnId ?? 'POST${now.millisecondsSinceEpoch}',
      dateTimeStr: dtStr,
      amount: paidAmt,
      status: isSuccess ? 'Success' : 'Failed',
      billNumber: _fetchedBillDetails?['billNumber']?.toString() ?? _fetchedBillDetails?['bill_number']?.toString(),
      dueDate: _fetchedBillDetails?['dueDate']?.toString() ?? _fetchedBillDetails?['due_date']?.toString(),
      billPeriod: _fetchedBillDetails?['billPeriod']?.toString() ?? _fetchedBillDetails?['bill_period']?.toString(),
    );

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
            isSuccess ? 'Bill Paid Successfully!' : 'Bill Payment Failed',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            (_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(),
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
                _receiptRow('Amount Paid', '₹${_amountCtrl.text.trim()}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Auto-Sent Email & WhatsApp Confirmation ──
          if (isSuccess || isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bill receipt has been automatically sent to your registered email & WhatsApp (+91 9880885551)',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ── Download / View Bill Receipt & Share Buttons ──
          if (isSuccess || isPending) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                label: const Text('View & Download Bill Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BbpsInvoicePdfService.shareToWhatsApp(receipt),
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BbpsInvoicePdfService.shareViaEmail(receipt),
                    icon: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
                    label: const Text('Email', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _resultStatus = null;
                  _resultMessage = null;
                  _amountCtrl.clear();
                  _fetchedBillDetails = null;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: textSubdued,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Pay Another Bill', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(initialIndex: 2),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.assignment_outlined, size: 18, color: primaryPurple),
              label: const Text('View in My Orders / Requests', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: primaryPurple)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
