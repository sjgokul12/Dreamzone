import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../services/prepaid_api_service.dart';
import '../../../../core/payment/razorpay_service.dart';
import 'postpaid_recharge_screen.dart';

class PrepaidRechargeScreen extends StatefulWidget {
  const PrepaidRechargeScreen({super.key});

  @override
  State<PrepaidRechargeScreen> createState() => _PrepaidRechargeScreenState();
}

class _PrepaidRechargeScreenState extends State<PrepaidRechargeScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF1E1B4B);
  static const Color textSubdued = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  // Operator & Circle State
  String? _selectedOperator;
  String? _selectedCircle;
  String? _detectedOpCode;
  String? _detectedCircleCode;

  bool _isAutoDetecting = false;
  bool _autoDetected = false;

  // Plan & R-Offer Loading State
  bool _loadingPlans = false;
  bool _loadingROffers = false;
  List<Map<String, dynamic>> _livePlans = [];
  String _selectedCategory = 'All';

  // Submission State
  bool _submitting = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  final RazorpayService _razorpayService = RazorpayService();

  // Dynamic Operators & Circles loaded from API / Database
  List<Map<String, dynamic>> _operators = [];
  List<String> _circles = [];
  bool _loadingOperators = false;
  bool _loadingCircles = false;

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _loadOperatorsAndCircles();
  }

  Future<void> _loadOperatorsAndCircles() async {
    setState(() {
      _loadingOperators = true;
      _loadingCircles = true;
    });

    try {
      final ops = await PrepaidApiService.fetchOperators(type: 'prepaid');
      final circs = await PrepaidApiService.fetchCircles();

      if (mounted) {
        setState(() {
          _operators = ops;
          _circles = circs;
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

  String get _cleanMobile => _mobileCtrl.text.replaceAll('+91', '').replaceAll(' ', '').trim();

  bool get _canShowActionButtons => _cleanMobile.length == 10 && _selectedOperator != null;

  void _onMobileChanged(String value) {
    final clean = value.replaceAll('+91', '').replaceAll(' ', '').trim();
    if (clean.length == 10) {
      _autoDetectOperatorAndCircle(clean);
    } else {
      if (_autoDetected) {
        setState(() => _autoDetected = false);
      }
    }
  }

  Future<void> _autoDetectOperatorAndCircle(String mobile) async {
    setState(() => _isAutoDetecting = true);

    try {
      final res = await PrepaidApiService.fetchOperatorAndCircle(mobile);
      if (mounted && res['success'] == true) {
        final detectedOp = (res['operator'] ?? '').toString().trim();
        final detectedCircle = (res['circle'] ?? '').toString().trim();
        final detectedOpCode = (res['opcode'] ?? '').toString().trim();
        final detectedCircleCode = (res['circle_code'] ?? '').toString().trim();

        setState(() {
          if (detectedOp.isNotEmpty && detectedOp != 'null') {
            final match = _operators.firstWhere(
              (o) {
                final lbl = (o['label'] ?? o['name'] ?? '').toString().toLowerCase();
                final code = (o['code'] ?? '').toString().toLowerCase();
                final d = detectedOp.toLowerCase();
                return lbl.contains(d) || d.contains(lbl) || code.contains(d) || d.contains(code);
              },
              orElse: () => <String, dynamic>{},
            );

            if (match.isNotEmpty) {
              _selectedOperator = (match['label'] ?? match['name'])?.toString() ?? detectedOp;
              _detectedOpCode = (match['spkey'] ?? match['code'] ?? match['id'])?.toString() ?? detectedOpCode;
            } else {
              _selectedOperator = detectedOp;
              _detectedOpCode = detectedOpCode;
            }
          }

          if (detectedCircle.isNotEmpty && detectedCircle != 'null') {
            final matchCirc = _circles.firstWhere(
              (c) {
                final cl = c.toLowerCase();
                final dc = detectedCircle.toLowerCase();
                return cl.contains(dc) || dc.contains(cl);
              },
              orElse: () => detectedCircle,
            );
            _selectedCircle = matchCirc;
            _detectedCircleCode = detectedCircleCode.isNotEmpty ? detectedCircleCode : matchCirc;
          }

          _autoDetected = true;
          _isAutoDetecting = false;
        });

        _showSnack('Auto-detected: $_selectedOperator • $_selectedCircle');
      } else {
        if (mounted) setState(() => _isAutoDetecting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isAutoDetecting = false);
    }
  }

  // ==================== 1. FETCH & SHOW R-OFFERS ====================
  Future<void> _showROffersSheet() async {
    if (_cleanMobile.length != 10) {
      _showSnack('Please enter a 10-digit mobile number first', isError: true);
      return;
    }

    setState(() => _loadingROffers = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Special R-Offers',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryDark),
                          ),
                          Text(
                            'Exclusive personalized deals for +91 $_cleanMobile',
                            style: const TextStyle(fontSize: 12, color: textSubdued, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: textSubdued),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: PrepaidApiService.fetchROffers(
                      mobileNo: _cleanMobile,
                      operatorCode: _selectedOperator ?? _detectedOpCode ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFFEC4899)),
                              SizedBox(height: 12),
                              Text('Checking live R-Offers from telecom server...', style: TextStyle(color: textSubdued, fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      final offers = snapshot.data ?? [];
                      if (offers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_outlined, size: 54, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'No direct R-Offers for this number',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: primaryDark),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'You can browse all standard recharge plans using the "Browse Plans" button.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textSubdued, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: offers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final o = offers[idx];
                          final price = o['price']?.toString() ?? '0';
                          final desc = o['desc']?.toString() ?? '';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF43F5E),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '₹$price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc.isNotEmpty ? desc : 'Special R-Offer pack for this number',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryDark,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _amountCtrl.text = price.replaceAll('.0', '');
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF43F5E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Select', style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    setState(() => _loadingROffers = false);
  }

  // ==================== 2. FETCH & BROWSE MOBILE PLANS ====================
  Future<void> _showBrowsePlansSheet() async {
    setState(() => _loadingPlans = true);

    final cleanMobile = _mobileCtrl.text.replaceAll('+91', '').replaceAll(' ', '').trim();
    final opCode = _detectedOpCode ?? _selectedOperator ?? '';
    final circleCode = _detectedCircleCode ?? _selectedCircle ?? '';

    try {
      final plans = await PrepaidApiService.fetchMobilePlans(
        operatorCode: opCode,
        circleCode: circleCode,
        mobile: cleanMobile,
      );
      if (mounted) {
        setState(() {
          _livePlans = plans;
          _loadingPlans = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final categories = <String>['All'];
          for (var p in _livePlans) {
            final cat = (p['category'] ?? 'General').toString();
            if (!categories.contains(cat)) categories.add(cat);
          }

          final filteredPlans = _selectedCategory == 'All'
              ? _livePlans
              : _livePlans.where((p) => p['category'] == _selectedCategory).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryPurple, Color(0xFF9333EA)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedOperator ?? "Mobile"} Plans',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryDark),
                          ),
                          Text(
                            '${_selectedCircle ?? "All India"} • Live PlanAPI packages',
                            style: const TextStyle(fontSize: 12, color: textSubdued, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: textSubdued),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                if (categories.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((cat) {
                        final isSel = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : primaryDark,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: primaryPurple,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _selectedCategory = cat);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 14),

                // Plans List
                Expanded(
                  child: filteredPlans.isEmpty
                      ? Center(
                          child: Text(
                            _loadingPlans ? 'Loading live plans...' : 'No plans available for this selection',
                            style: const TextStyle(color: textSubdued, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredPlans.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final p = filteredPlans[idx];
                            final price = p['price']?.toString() ?? '0';
                            final validity = p['validity']?.toString() ?? 'Active';
                            final desc = p['desc']?.toString() ?? '';
                            final cat = p['category']?.toString() ?? '';

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
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              '₹$price',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: primaryDark,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                validity,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: primaryPurple,
                                                ),
                                              ),
                                            ),
                                            if (cat.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  cat,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0284C7),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            desc,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF475569),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _amountCtrl.text = price.replaceAll('.0', '');
                                      });
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Select', style: TextStyle(fontWeight: FontWeight.w800)),
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
        },
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
            if (_loadingOperators)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryPurple)))
            else if (_operators.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No operators found in database.', style: TextStyle(color: textSubdued))))
            else
              ..._operators.map((op) {
                final label = (op['label'] ?? op['name'] ?? '').toString();
                final code = (op['id'] ?? op['code'] ?? '').toString();
                final isSel = label == _selectedOperator;
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
                    child: const Icon(Icons.cell_tower_rounded, color: primaryPurple, size: 20),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? primaryPurple : primaryDark,
                    ),
                  ),
                  trailing: isSel ? const Icon(Icons.check_circle_rounded, color: primaryPurple) : null,
                  onTap: () {
                    setState(() {
                      _selectedOperator = label;
                      _detectedOpCode = (code.isNotEmpty ? code : op['spkey'] ?? op['id'])?.toString();
                    });
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
            if (_loadingCircles)
              const Expanded(child: Center(child: CircularProgressIndicator(color: primaryPurple)))
            else if (_circles.isEmpty)
              const Expanded(child: Center(child: Text('No circles found in database.', style: TextStyle(color: textSubdued))))
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
                      trailing: isSel ? const Icon(Icons.check_circle_rounded, color: primaryPurple) : null,
                      onTap: () {
                        setState(() {
                          _selectedCircle = c;
                          _detectedCircleCode = c;
                        });
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

  Future<void> _submitRecharge() async {
    if (!_formKey.currentState!.validate()) return;

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

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Prepaid Recharge – $_selectedOperator',
      name: 'DZI Infinity',
      contact: _cleanMobile,
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitRecharge(
          auth: auth,
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
    required String razorpayPaymentId,
  }) async {
    setState(() {
      _submitting = true;
      _resultStatus = null;
    });

    try {
      final res = await ApiService.postApi('/recharge', {
        'user_id': auth.userId,
        'mobile_number': _cleanMobile,
        'operator_id': _detectedOpCode ?? _selectedOperator ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
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
                    'PREPAID',
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
                  'Mobile Recharge',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instant recharge with live PlanAPI offers & packages',
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
            color: primaryPurple.withValues(alpha: 0.05),
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
            // Switch to Postpaid link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Prepaid Connection',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: primaryDark),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryPurple),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),

            // 1. Mobile Number Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mobile Number',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryDark),
                ),
                if (_isAutoDetecting)
                  const Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
                      ),
                      SizedBox(width: 6),
                      Text('Detecting Operator...', style: TextStyle(fontSize: 11, color: primaryPurple, fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: _onMobileChanged,
              validator: (v) {
                final clean = (v ?? '').replaceAll('+91', '').replaceAll(' ', '').trim();
                if (clean.length != 10) return 'Enter a valid 10-digit mobile number';
                return null;
              },
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primaryDark,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                  child: Text(
                    '+91 ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryPurple),
                  ),
                ),
                suffixIcon: _autoDetected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                    : null,
                counterText: '',
                hintText: 'Enter 10-digit mobile number',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
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

            // 2. Operator Selector
            const Text(
              'Operator',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryDark),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showOperatorPicker,
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
                        _selectedOperator ?? 'Select operator',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedOperator != null ? primaryDark : textSubdued,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: textSubdued),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Circle Selector
            const Text(
              'Circle / Region',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryDark),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCirclePicker,
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
                        _selectedCircle ?? 'Select circle',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _selectedCircle != null ? primaryDark : textSubdued,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: textSubdued),
                  ],
                ),
              ),
            ),

            // TWO BIG ACTION BUTTONS (Hidden until Mobile + Operator ready)
            if (_canShowActionButtons) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  // Button 1: Special R-Offer
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _loadingROffers ? null : _showROffersSheet,
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'R-Offers',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Button 2: Browse Plans
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPurple, Color(0xFF9333EA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _loadingPlans ? null : _showBrowsePlansSheet,
                        icon: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                        label: const Text(
                          'Browse Plans',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 22),

            // 4. Amount Input
            const Text(
              'Recharge Amount',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primaryDark),
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: primaryDark,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8, top: 12),
                  child: Text(
                    '₹',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryPurple),
                  ),
                ),
                hintText: 'Enter plan amount',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
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
            const SizedBox(height: 12),

            // Quick Preset Amount Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [19, 199, 299, 349, 649, 999, 2999].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        '₹$amt',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: primaryPurple),
                      ),
                      backgroundColor: const Color(0xFFEDE9FE),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () => setState(() => _amountCtrl.text = amt.toString()),
                    ),
                  );
                }).toList(),
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
                _receiptRow('Mobile Number', _cleanMobile),
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
