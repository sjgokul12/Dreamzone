import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/recharge_service.dart';

// Live mobile recharge screen. This is DELIBERATELY separate from
// ServiceDetailScreen (the generic dynamic-form flow used by your
// other services) because recharge needs an instant, real API call
// and result - not a stored "application" for staff to review later.
//
// Wire it up wherever your service list currently does:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)));
// Change that to route here instead for whichever service you mark
// as the recharge one, e.g.:
//   if (service['category'] == 'Recharge') {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen()));
//   } else {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)));
//   }
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF8F9FF);
  static const Color textPrimaryColor = Color(0xFF1A1A2E);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFFFFFFF);

  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  List<dynamic> _operators = [];
  Map<String, dynamic>? _selectedOperator;
  bool _loadingOperators = true;
  bool _submitting = false;

  // Result state, shown after a submit.
  String? _resultStatus; // 'pending' | 'success' | 'failed'
  String? _resultMessage;
  String? _merchantTxnId;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOperators() async {
    setState(() => _loadingOperators = true);
    try {
      final data = await RechargeService.getOperators('prepaid');
      if (data['success'] == true && mounted) {
        setState(() {
          _operators = data['operators'] ?? [];
          if (_operators.isNotEmpty) _selectedOperator = _operators.first;
        });
      }
    } catch (e) {
      debugPrint('Error loading operators: $e');
    }
    if (mounted) setState(() => _loadingOperators = false);
  }

  Future<void> _submitRecharge() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOperator == null) {
      _showSnack('Please select an operator', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnack('Please login to recharge', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _resultStatus = null;
      _resultMessage = null;
      _merchantTxnId = null;
    });

    try {
      final data = await RechargeService.submitRecharge({
        'user_id': auth.userId,
        'mobile_number': _mobileCtrl.text.trim(),
        'operator_id': _selectedOperator!['id'],
        'operator_name': _selectedOperator!['label'],
        'amount': _amountCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _submitting = false;
          if (data['success'] == true) {
            _resultStatus = data['status'];
            _resultMessage = data['message'];
            _merchantTxnId = data['merchant_txn_id'];
          } else {
            _resultStatus = 'failed';
            _resultMessage = data['message'] ?? 'Recharge failed';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'failed';
          _resultMessage =
              'Connection error. Please check your internet and try again.';
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    if (_merchantTxnId == null) return;
    setState(() => _checkingStatus = true);
    try {
      final data = await RechargeService.checkStatus(_merchantTxnId!);
      if (data['success'] == true && mounted) {
        setState(() {
          _resultStatus = data['status'];
          if (_resultStatus == 'success') {
            _resultMessage = 'Recharge successful!';
          } else if (_resultStatus == 'failed') {
            _resultMessage = 'Recharge failed.';
          } else {
            _resultMessage = 'Still processing... please check again shortly.';
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking status: $e');
    }
    if (mounted) setState(() => _checkingStatus = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startNewRecharge() {
    setState(() {
      _resultStatus = null;
      _resultMessage = null;
      _merchantTxnId = null;
      _mobileCtrl.clear();
      _amountCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Mobile Recharge',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _resultStatus != null ? _buildResultView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Recharge any prepaid mobile\ninstantly',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Operator',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _loadingOperators
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: primary),
                          ),
                        )
                      : _operators.isEmpty
                      ? Text(
                          'No operators available. Pull to refresh.',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 12,
                          ),
                        )
                      : DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedOperator,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: _operators
                              .cast<Map<String, dynamic>>()
                              .map(
                                (op) => DropdownMenuItem(
                                  value: op,
                                  child: Text(op['label'] ?? op['code'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedOperator = v),
                        ),
                  const SizedBox(height: 16),

                  const Text(
                    'Mobile Number',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon: const Icon(
                        Icons.phone,
                        size: 20,
                        color: primary,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length != 10 ||
                          int.tryParse(v.trim()) == null) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Recharge Amount (₹)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 199',
                      prefixIcon: const Icon(
                        Icons.currency_rupee,
                        size: 20,
                        color: primary,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = num.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),

                  // Quick-pick common amounts.
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [99, 149, 199, 299, 499, 599].map((amt) {
                      return InkWell(
                        onTap: () =>
                            setState(() => _amountCtrl.text = amt.toString()),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹$amt',
                            style: const TextStyle(
                              fontSize: 12,
                              color: primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Recharge Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Payment is processed instantly through our recharge partner. '
              'If a recharge shows "processing", it will resolve automatically within a few minutes.',
              style: TextStyle(
                fontSize: 11,
                color: textSecondaryColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    Color color;
    IconData icon;
    String title;
    switch (_resultStatus) {
      case 'success':
        color = success;
        icon = Icons.check_circle;
        title = 'Recharge Successful!';
        break;
      case 'failed':
        color = danger;
        icon = Icons.cancel;
        title = 'Recharge Failed';
        break;
      default:
        color = warning;
        icon = Icons.hourglass_top;
        title = 'Processing...';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 70),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _resultMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (_merchantTxnId != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Reference ID',
                      style: TextStyle(fontSize: 11, color: textSecondaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _merchantTxnId!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_resultStatus == 'pending')
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _checkingStatus ? null : _checkStatus,
                  icon: _checkingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                  style: OutlinedButton.styleFrom(foregroundColor: primary),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _startNewRecharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Recharge Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
