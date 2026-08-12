import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

class RechargeScreen extends StatefulWidget {
  final bool initialIsPostpaid;

  const RechargeScreen({
    super.key,
    this.initialIsPostpaid = false,
  });

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textSubdued = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileCtrl = TextEditingController(text: '+91 ');
  final TextEditingController _amountCtrl = TextEditingController();

  late bool _isPostpaid;
  String _selectedOperator = 'Select operator';
  String _selectedCircle = 'Select circle';

  bool _loadingData = true;
  List<Map<String, dynamic>> _prepaidOperators = [];
  List<Map<String, dynamic>> _postpaidOperators = [];
  List<String> _circles = ['Select circle'];

  bool _submitting = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  @override
  void initState() {
    super.initState();
    _isPostpaid = widget.initialIsPostpaid;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loadingData = true);
    final api = ApiService();
    try {
      final preRes = await api.getRechargeOperators('prepaid');
      final postRes = await api.getRechargeOperators('postpaid');
      final circleRes = await api.getRechargeCircles();

      List<Map<String, dynamic>> preOps = [];
      if (preRes['success'] == true && preRes['operators'] != null) {
        preOps = List<Map<String, dynamic>>.from(preRes['operators']);
      }
      
      List<Map<String, dynamic>> postOps = [];
      if (postRes['success'] == true && postRes['operators'] != null) {
        postOps = List<Map<String, dynamic>>.from(postRes['operators']);
      }
      
      List<String> circs = ['Select circle'];
      if (circleRes['success'] == true && circleRes['circles'] != null) {
        circs.addAll(List<String>.from(circleRes['circles']));
      }

      if (mounted) {
        setState(() {
          _prepaidOperators = preOps;
          _postpaidOperators = postOps;
          _circles = circs;
          _selectedOperator = 'Select operator';
          _selectedCircle = 'Select circle';
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  void _onTabChanged(bool isPostpaid) {
    if (_isPostpaid == isPostpaid) return;
    setState(() {
      _isPostpaid = isPostpaid;
      _selectedOperator = 'Select operator';
      _selectedCircle = 'Select circle';
      _amountCtrl.clear();
    });
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRecharge() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOperator == 'Select operator') {
      _showSnack('Please select an operator', isError: true);
      return;
    }
    
    // Find operator SPKey
    final currentOps = _isPostpaid ? _postpaidOperators : _prepaidOperators;
    final opData = currentOps.firstWhere(
      (o) => o['label'] == _selectedOperator,
      orElse: () => {'id': _selectedOperator}
    );

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnack('Please login to recharge', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _resultStatus = null;
    });

    try {
      // Using ApiService.postApi to fallback to localhost properly
      final res = await ApiService.postApi('/recharge', {
        'user_id': auth.userId,
        'mobile_number': _mobileCtrl.text.trim().replaceAll('+91 ', '').trim(),
        'operator_id': opData['id'],
        'operator_name': _selectedOperator,
        'circle': _selectedCircle == 'Select circle' ? '' : _selectedCircle,
        'amount': _amountCtrl.text.trim(),
        'type': _isPostpaid ? 'postpaid' : 'prepaid',
      }, timeoutSeconds: 30);

      final data = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage = data['message'] ?? (_resultStatus == 'success' ? 'Recharge successful!' : 'Recharge failed');
          _merchantTxnId = data['merchant_txn_id'] ?? 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'failed';
          _resultMessage = 'Failed to connect to server: $e';
        });
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA), // Light bluish-purple background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _resultStatus != null
                  ? _buildResultView()
                  : _buildMainForm(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          colors: [Color(0xFFFCFBFF), Color(0xFFF0EBFA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: primaryPurple, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Mobile ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: primaryPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Recharge',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Seamless & secure mobile recharges anytime, anywhere',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: textSubdued,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // 3D Image
          Positioned(
            right: -20,
            top: 10,
            child: Image.asset(
              'assets/Mobile.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(false),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 18,
                                color: !_isPostpaid ? primaryPurple : textSubdued,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Prepaid',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: !_isPostpaid ? primaryPurple : textSubdued,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: !_isPostpaid ? primaryPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(true),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sim_card_rounded,
                                size: 18,
                                color: _isPostpaid ? primaryPurple : textSubdued,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Postpaid',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _isPostpaid ? primaryPurple : textSubdued,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: _isPostpaid ? primaryPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (_loadingData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: primaryPurple),
                ),
              )
            else ...[
              // Mobile Number
              _buildLabel('Mobile Number'),
              _buildTextField(
                controller: _mobileCtrl,
                hint: 'Enter mobile number',
                icon: Icons.contact_phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter 10-digit mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Operator
              _buildLabel('Operator'),
              _buildDropdown(
                value: _selectedOperator,
                icon: Icons.cell_tower_rounded,
                items: ['Select operator', ...(_isPostpaid ? _postpaidOperators : _prepaidOperators).map((o) => o['label'].toString())],
                onChanged: (v) => setState(() => _selectedOperator = v!),
              ),
              const SizedBox(height: 20),

              // Circle
              _buildLabel('Circle'),
              _buildDropdown(
                value: _selectedCircle,
                icon: Icons.location_on_outlined,
                items: _circles,
                onChanged: (v) => setState(() => _selectedCircle = v!),
              ),
              const SizedBox(height: 20),

              // Amount
              _buildLabel('Recharge Amount'),
              _buildAmountField(),

              if (!_isPostpaid) ...[
                const SizedBox(height: 16),
                _buildAmountChips(),
              ],

              const SizedBox(height: 24),

              // Secure Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('100% Secure Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryPurple)),
                          Text('Your transactions are safe and protected', style: TextStyle(fontSize: 11, color: textSubdued)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: primaryPurple, size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRecharge,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _submitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _isPostpaid ? 'Pay Bill Now' : 'Recharge Now',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDark),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryPurple, size: 18),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 1.5)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: textSubdued),
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryDark),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryPurple, size: 18),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 1.5)),
      ),
      isExpanded: true,
      items: items.map((i) => DropdownMenuItem(
        value: i, 
        child: Text(
          i,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryDark),
      decoration: InputDecoration(
        hintText: 'Enter amount',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.currency_rupee_rounded, color: primaryPurple, size: 18),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_amountCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _amountCtrl.clear()),
                  child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 20),
                ),
              const SizedBox(width: 8),
              const Text(
                'Browse Plans',
                style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 1.5)),
      ),
      onChanged: (v) => setState(() {}),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (num.tryParse(v.trim()) == null) return 'Enter valid amount';
        return null;
      },
    );
  }

  Widget _buildAmountChips() {
    final chips = [149, 199, 299, 499, 666, 719, 999, 1499];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips.map((amt) {
        return InkWell(
          onTap: () => setState(() => _amountCtrl.text = amt.toString()),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '₹$amt',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryPurple),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultView() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _resultStatus == 'success' ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _resultStatus == 'success' ? Icons.check : Icons.close,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _resultStatus == 'success'
                ? (_isPostpaid ? 'Bill Paid Successfully!' : 'Recharge Successful!')
                : 'Transaction Failed',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            _resultMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: textSubdued, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (_merchantTxnId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _merchantTxnId!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryDark, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null;
                _amountCtrl.clear();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Recharge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
