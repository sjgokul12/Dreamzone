import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/recharge_service.dart';

// Live mobile recharge screen with Prepaid + Postpaid tabs, matching
// the plan-browsing / bill-fetch flow of typical BBPS recharge
// portals. This is DELIBERATELY separate from ServiceDetailScreen
// (the generic dynamic-form flow used by your other services) because
// recharge needs instant, real API calls and results - not a stored
// "application" for staff to review later.
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF00A896);
  static const Color primaryDark = Color(0xFF028090);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF4FBF7);
  static const Color textPrimaryColor = Color(0xFF1A1A2E);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFFFFFFF);

  late TabController _tabController;

  // ---------- Shared result state (used after either tab submits) ----------
  String? _resultStatus; // 'pending' | 'success' | 'failed'
  String? _resultMessage;
  String? _merchantTxnId;
  bool _checkingStatus = false;
  bool _submitting = false;

  // ---------- PREPAID tab state ----------
  final _prepaidFormKey = GlobalKey<FormState>();
  final _prepaidMobileCtrl = TextEditingController();
  final _customAmountCtrl = TextEditingController();
  List<dynamic> _prepaidOperators = [];
  Map<String, dynamic>? _selectedPrepaidOperator;
  List<String> _circles = [];
  String? _selectedCircle;
  bool _loadingPrepaidOperators = true;
  bool _loadingPlans = false;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  String? _plansNotConfiguredMessage;

  // ---------- POSTPAID tab state ----------
  final _postpaidFormKey = GlobalKey<FormState>();
  final _postpaidMobileCtrl = TextEditingController();
  List<dynamic> _postpaidOperators = [];
  Map<String, dynamic>? _selectedPostpaidOperator;
  bool _loadingPostpaidOperators = true;
  bool _fetchingBill = false;
  Map<String, dynamic>? _bill;
  String? _billNotConfiguredMessage;
  String? _billErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrepaidOperators();
    _loadPostpaidOperators();
    _loadCircles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prepaidMobileCtrl.dispose();
    _customAmountCtrl.dispose();
    _postpaidMobileCtrl.dispose();
    super.dispose();
  }

  // ==================== LOADERS ====================

  Future<void> _loadPrepaidOperators() async {
    setState(() => _loadingPrepaidOperators = true);
    try {
      final data = await RechargeService.getOperators('prepaid');
      if (data['success'] == true && mounted) {
        final list = (data['operators'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        setState(() {
          _prepaidOperators = list;
          _selectedPrepaidOperator = _prepaidOperators.isNotEmpty ? _prepaidOperators.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _prepaidOperators = [];
          _selectedPrepaidOperator = null;
        });
      }
    }
    if (mounted) setState(() => _loadingPrepaidOperators = false);
  }

  Future<void> _loadPostpaidOperators() async {
    setState(() => _loadingPostpaidOperators = true);
    try {
      final data = await RechargeService.getOperators('postpaid');
      if (data['success'] == true && mounted) {
        final list = (data['operators'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        setState(() {
          _postpaidOperators = list;
          _selectedPostpaidOperator = _postpaidOperators.isNotEmpty ? _postpaidOperators.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postpaidOperators = [];
          _selectedPostpaidOperator = null;
        });
      }
    }
    if (mounted) setState(() => _loadingPostpaidOperators = false);
  }

  Future<void> _loadCircles() async {
    try {
      final data = await RechargeService.getCircles();
      if (data['success'] == true && mounted) {
        final list = List<String>.from(data['circles'] ?? []);
        setState(() {
          _circles = list;
          _selectedCircle = _circles.isNotEmpty ? _circles.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _circles = [];
          _selectedCircle = null;
        });
      }
    }
  }

  // ==================== PREPAID: BROWSE PLANS ====================

  Future<void> _browsePlans() async {
    if (_selectedPrepaidOperator == null) {
      _showSnack('Please select an operator', isError: true);
      return;
    }
    if (_prepaidMobileCtrl.text.trim().length != 10) {
      _showSnack('Enter a valid 10-digit mobile number', isError: true);
      return;
    }

    setState(() {
      _loadingPlans = true;
      _plans = [];
      _selectedPlan = null;
      _plansNotConfiguredMessage = null;
    });

    try {
      final data = await RechargeService.browsePlans(
        _selectedPrepaidOperator!['id'].toString(),
        _selectedCircle ?? '',
        _prepaidMobileCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          if (data['not_configured'] == true) {
            _plansNotConfiguredMessage = data['message'];
          } else if (data['success'] == true) {
            _plans = data['plans'] ?? [];
            if (_plans.isEmpty) {
              _plansNotConfiguredMessage =
                  'No plans found for this operator/circle right now.';
            }
          } else {
            _plansNotConfiguredMessage =
                data['message'] ?? 'Could not load plans';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _plansNotConfiguredMessage =
              'Connection error while loading plans.',
        );
      }
    }
    if (mounted) setState(() => _loadingPlans = false);
  }

  // ==================== POSTPAID: GET BILL ====================

  Future<void> _getBill() async {
    if (_selectedPostpaidOperator == null) {
      _showSnack('Please select an operator', isError: true);
      return;
    }
    if (_postpaidMobileCtrl.text.trim().length != 10) {
      _showSnack('Enter a valid 10-digit mobile number', isError: true);
      return;
    }

    setState(() {
      _fetchingBill = true;
      _bill = null;
      _billNotConfiguredMessage = null;
      _billErrorMessage = null;
    });

    try {
      final data = await RechargeService.getBill({
        'mobile_number': _postpaidMobileCtrl.text.trim(),
        'operator_id': _selectedPostpaidOperator!['id'],
      });
      if (mounted) {
        setState(() {
          if (data['not_configured'] == true) {
            _billNotConfiguredMessage = data['message'];
          } else if (data['success'] == true) {
            _bill = data['bill'];
          } else {
            _billErrorMessage =
                data['message'] ??
                'Unable to get bill details. Please try again after a few minutes.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _billErrorMessage = 'Connection error while fetching bill.',
        );
      }
    }
    if (mounted) setState(() => _fetchingBill = false);
  }

  // ==================== SUBMIT (shared by both tabs) ====================

  Future<void> _submitRecharge({
    required String mobileNumber,
    required Map<String, dynamic> operator,
    required num amount,
  }) async {
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
        'mobile_number': mobileNumber,
        'operator_id': operator['id'],
        'operator_name': operator['label'],
        'amount': amount.toString(),
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

  void _startOver() {
    setState(() {
      _resultStatus = null;
      _resultMessage = null;
      _merchantTxnId = null;
      _prepaidMobileCtrl.clear();
      _postpaidMobileCtrl.clear();
      _customAmountCtrl.clear();
      _plans = [];
      _selectedPlan = null;
      _bill = null;
      _plansNotConfiguredMessage = null;
      _billNotConfiguredMessage = null;
      _billErrorMessage = null;
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
        bottom: _resultStatus != null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'PREPAID'),
                  Tab(text: 'POSTPAID'),
                ],
              ),
      ),
      body: _resultStatus != null
          ? _buildResultView()
          : TabBarView(
              controller: _tabController,
              children: [_buildPrepaidTab(), _buildPostpaidTab()],
            ),
    );
  }

  // ==================== PREPAID TAB ====================

  Widget _buildPrepaidTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _prepaidFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner('Recharge any prepaid mobile\ninstantly'),
            const SizedBox(height: 20),
            _buildCard(
              children: [
                const Text(
                  'Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _prepaidMobileCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _fieldDecoration(
                    'Enter 10-digit mobile number',
                    Icons.phone,
                  ),
                  validator: (v) => (v == null || v.trim().length != 10)
                      ? 'Enter a valid 10-digit number'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildOperatorDropdown(
                        operators: _prepaidOperators,
                        selected: _selectedPrepaidOperator,
                        loading: _loadingPrepaidOperators,
                        onChanged: (v) =>
                            setState(() => _selectedPrepaidOperator = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCircle,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          'Circle',
                          Icons.map_outlined,
                        ),
                        items: _circles
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCircle = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _loadingPlans ? null : _browsePlans,
                    icon: _loadingPlans
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.list_alt),
                    label: const Text('Browse Plans'),
                    style: OutlinedButton.styleFrom(foregroundColor: primary),
                  ),
                ),
              ],
            ),

            if (_plansNotConfiguredMessage != null) ...[
              const SizedBox(height: 16),
              _buildInfoBanner(_plansNotConfiguredMessage!),
            ],

            if (_plans.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Select a Plan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _buildPlanGrid(),
            ],

            const SizedBox(height: 20),
            _buildCard(
              children: [
                const Text(
                  'Or Enter Custom Amount',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  decoration: _fieldDecoration(
                    'e.g. 199',
                    Icons.currency_rupee,
                  ),
                  onChanged: (_) => setState(() => _selectedPlan = null),
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitPrepaidRecharge,
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
                    : Text(
                        _selectedPlan != null
                            ? 'Recharge with ₹${_selectedPlan!['amount']}'
                            : 'Recharge Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final isSelected = _selectedPlan == plan;
        final amount = plan['amount']?.toString() ?? '-';
        final talktime = plan['talktime']?.toString();
        final validity = plan['validity']?.toString();
        final description = plan['description']?.toString();

        return InkWell(
          onTap: () {
            setState(() {
              _selectedPlan = plan;
              _customAmountCtrl.clear();
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [primary, primaryDark])
                  : null,
              color: isSelected ? null : cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[300]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹$amount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : primary,
                  ),
                ),
                const SizedBox(height: 4),
                if (talktime != null)
                  Text(
                    'Talktime: $talktime',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : textSecondaryColor,
                    ),
                  ),
                if (validity != null)
                  Text(
                    'Validity: $validity',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : textSecondaryColor,
                    ),
                  ),
                if (description != null && talktime == null && validity == null)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitPrepaidRecharge() {
    if (!_prepaidFormKey.currentState!.validate()) return;
    if (_selectedPrepaidOperator == null) {
      _showSnack('Please select an operator', isError: true);
      return;
    }

    num? amount;
    if (_selectedPlan != null) {
      amount = num.tryParse(_selectedPlan!['amount'].toString());
    } else if (_customAmountCtrl.text.trim().isNotEmpty) {
      amount = num.tryParse(_customAmountCtrl.text.trim());
    }

    if (amount == null || amount <= 0) {
      _showSnack('Select a plan or enter a valid custom amount', isError: true);
      return;
    }

    _submitRecharge(
      mobileNumber: _prepaidMobileCtrl.text.trim(),
      operator: _selectedPrepaidOperator!,
      amount: amount,
    );
  }

  // ==================== POSTPAID TAB ====================

  Widget _buildPostpaidTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _postpaidFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner('Pay your postpaid mobile bill\ninstantly'),
            const SizedBox(height: 20),
            _buildCard(
              children: [
                const Text(
                  'Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _postpaidMobileCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _fieldDecoration(
                    'Enter 10-digit mobile number',
                    Icons.phone,
                  ),
                  validator: (v) => (v == null || v.trim().length != 10)
                      ? 'Enter a valid 10-digit number'
                      : null,
                ),
                const SizedBox(height: 14),
                _buildOperatorDropdown(
                  operators: _postpaidOperators,
                  selected: _selectedPostpaidOperator,
                  loading: _loadingPostpaidOperators,
                  onChanged: (v) =>
                      setState(() => _selectedPostpaidOperator = v),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _fetchingBill ? null : _getBill,
                    icon: _fetchingBill
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.receipt_long),
                    label: const Text('Get Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_billNotConfiguredMessage != null) ...[
              const SizedBox(height: 16),
              _buildInfoBanner(_billNotConfiguredMessage!),
            ],

            if (_billErrorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_billErrorMessage!),
            ],

            if (_bill != null) ...[
              const SizedBox(height: 20),
              _buildBillCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard() {
    final customerName = _bill!['customer_name']?.toString();
    final billAmount = _bill!['bill_amount'];
    final dueDate = _bill!['due_date']?.toString();
    final billNumber = _bill!['bill_number']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: success.withAlpha(80)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: success),
              const SizedBox(width: 8),
              const Text(
                'Bill Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          if (customerName != null) _billRow('Customer', customerName),
          if (billNumber != null) _billRow('Bill Number', billNumber),
          if (dueDate != null) _billRow('Due Date', dueDate),
          _billRow('Amount Due', '₹$billAmount', highlight: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () {
                      final amt = num.tryParse(billAmount.toString());
                      if (amt == null || amt <= 0) {
                        _showSnack('Invalid bill amount', isError: true);
                        return;
                      }
                      _submitRecharge(
                        mobileNumber: _postpaidMobileCtrl.text.trim(),
                        operator: _selectedPostpaidOperator!,
                        amount: amt,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay ₹$billAmount',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? success : textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED UI HELPERS ====================

  Widget _buildHeaderBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.4, color: danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorDropdown({
    required List<dynamic> operators,
    required Map<String, dynamic>? selected,
    required bool loading,
    required void Function(Map<String, dynamic>?) onChanged,
  }) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }
    if (operators.isEmpty) {
      return Text(
        'No operators available yet.',
        style: TextStyle(color: textSecondaryColor, fontSize: 12),
      );
    }
    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: selected,
      isExpanded: true,
      decoration: _fieldDecoration('Operator', Icons.sim_card),
      items: operators
          .cast<Map<String, dynamic>>()
          .map(
            (op) => DropdownMenuItem(
              value: op,
              child: Text(
                op['label'] ?? op['code'] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: primary),
      counterText: '',
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                onPressed: _startOver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start Over'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
