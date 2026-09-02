import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../services/bbps_api_service.dart';
import '../../../../services/bbps_invoice_pdf_service.dart';
import '../../../../widgets/bbps_fetched_bill_card.dart';
import '../../../../core/payment/razorpay_service.dart';
import '../bbps_receipt_screen.dart';
import '../../../home/home_screen.dart';

/// Gas Cylinder Booking / Bill Payment Screen
/// Matches the provided Purple/Violet reference design exactly —
/// hero card, quick-info strip, consumer number + operator selector,
/// instant settlement toggle, secure payments card, gradient CTA.
class GasCylinderScreen extends StatefulWidget {
  const GasCylinderScreen({super.key});

  @override
  State<GasCylinderScreen> createState() => _GasCylinderScreenState();
}

class _GasCylinderScreenState extends State<GasCylinderScreen> {
  // ---- Theme Palette (matched from reference design) ----
  static const Color primaryPurple = Color(0xFF6D28D9);
  static const Color deepPurple = Color(0xFF5B21B6);
  static const Color heroBgStart = Color(0xFFEDE8FB);
  static const Color heroBgEnd = Color(0xFFF6F4FE);
  static const Color pageBg = Color(0xFFF7F6FC);
  static const Color textDark = Color(0xFF1E1B2E);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color fieldFill = Color(0xFFFAFAFF);
  static const Color fieldBorder = Color(0xFFE4E0F7);
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color amberIcon = Color(0xFFF59E0B);

  final _consumerNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '950.00');
  final _searchCtrl = TextEditingController();
  String? _selectedOperator;
  bool _instantSettlement = true;

  // ─── BBPS Fetch Bill State ────────────────────────────────────────────────
  BbpsBillDetails? _fetchedBill;
  bool _isFetchingBill = false;

  bool _operatorsLoading = false;
  String? _operatorsError;
  
  // Default BBPS standard gas cylinder operators list with standard SPKeys
  static const List<Map<String, dynamic>> _defaultOperators = [
    {'code': 'INDANE', 'label': 'Indane Gas (Indian Oil)', 'spkey': '303'},
    {'code': 'BPCL', 'label': 'Bharat Petroleum Corporation Limited (BPCL)', 'spkey': '301'},
    {'code': 'HPCL', 'label': 'Hindustan Petroleum Corporation Limited (HPCL)', 'spkey': '302'},
    {'code': 'GAIL', 'label': 'GAIL Gas Limited', 'spkey': '304'},
    {'code': 'ADANI', 'label': 'Adani Total Gas - Cylinder', 'spkey': '305'},
  ];

  List<Map<String, dynamic>> _operators = List.from(_defaultOperators);
  Map<String, dynamic>? _selectedOp;

  // Razorpay Service
  final RazorpayService _razorpayService = RazorpayService();

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _fetchOperators();
  }

  @override
  void dispose() {
    _consumerNumberCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    try {
      final res = await ApiService.fetchApi('/gas-cylinder/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null && (data['operators'] as List).isNotEmpty) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _operatorsLoading = false; });
      }
    } catch (_) {
      // Keep default standard operators list for instant loading
      if (mounted) setState(() => _operatorsLoading = false);
    }
  }

  void _openOperatorPicker() {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? _operators
              : _operators.where((op) => (op['label'] ?? '').toString().toLowerCase().contains(query)).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: const Color(0xFFE2E0F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Gas Operator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search cylinder operator...',
                    hintStyle: const TextStyle(color: Color(0xFFA9A6C3), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryPurple, size: 20),
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryPurple, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No operators match your search', style: TextStyle(color: textMuted)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final op = filtered[i];
                            final isSelected = _selectedOperator == op['label'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedOperator = op['label'] as String;
                                  _selectedOp = op;
                                });
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryPurple.withValues(alpha: 0.08) : fieldFill,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? primaryPurple : fieldBorder,
                                    width: isSelected ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryPurple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.propane_tank_rounded, color: primaryPurple, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        op['label'] as String,
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: textDark),
                                      ),
                                    ),
                                    if (isSelected) const Icon(Icons.check_circle_rounded, color: primaryPurple, size: 20),
                                  ],
                                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 16),
                    _buildHeroCard(context),
                    const SizedBox(height: 18),
                    _buildQuickInfoRow(context),
                    const SizedBox(height: 18),
                    _buildFormCard(),
                    const SizedBox(height: 18),
                    _buildInstantSettlementCard(),
                    const SizedBox(height: 14),
                    _buildSecurePaymentsCard(),
                    const SizedBox(height: 22),
                    _buildProceedButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryPurple, size: 17),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, color: primaryPurple, size: 16),
              SizedBox(width: 6),
              Text(
                'BBPS Assured',
                style: TextStyle(color: primaryPurple, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [heroBgStart, heroBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isNarrow ? 3 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 6),
                          Text(
                            'GAS CYLINDER',
                            style: TextStyle(
                              color: primaryPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Book Your\n',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textDark, height: 1.2),
                          ),
                          TextSpan(
                            text: 'Gas Cylinder',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryPurple, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enter your Consumer Number and we'll take care of the rest!",
                      style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.asset(
                      'assets/Gas full.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.propane_tank_rounded, size: 60, color: primaryPurple),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── Quick Info Row ─────────────────────────────────────────────────────
  Widget _buildQuickInfoRow(BuildContext context) {
    final items = [
      (Icons.badge_outlined, 'Consumer No.'),
      (Icons.propane_tank_rounded, 'Operators'),
      (Icons.bolt_rounded, 'Instant'),
      (Icons.shield_rounded, 'Secured'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return SizedBox(
              height: 34,
              child: VerticalDivider(color: const Color(0xFFE9E7F5), thickness: 1, width: 1),
            );
          }
          final (icon, label) = items[i ~/ 2];
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryPurple, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textDark),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Form Card ──────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Consumer Number
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Consumer Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _consumerNumberCtrl,
            keyboardType: TextInputType.text,
            inputFormatters: [LengthLimitingTextInputFormatter(25)],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: textDark),
            decoration: InputDecoration(
              hintText: 'Enter your Consumer / BP number',
              hintStyle: const TextStyle(color: Color(0xFFA9A6C3), fontSize: 14),
              filled: true,
              fillColor: fieldFill,
              prefixIcon: const Icon(Icons.tag_rounded, color: primaryPurple, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: fieldBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Operators
          Row(
            children: const [
              Icon(Icons.propane_tank_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openOperatorPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fieldBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryPurple.withValues(alpha: 0.4), width: 1.6),
                    ),
                    child: _operatorsLoading
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _operatorsLoading
                          ? 'Loading operators…'
                          : (_selectedOperator ?? 'Select Operator'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedOperator == null ? FontWeight.w500 : FontWeight.w700,
                        color: _selectedOperator == null ? const Color(0xFFA9A6C3) : textDark,
                      ),
                    ),
                  ),
                  if (!_operatorsLoading) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Choose',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: primaryPurple),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 20),
                  ],
                ],
              ),
            ),
          ),

          // ─── BBPS Get Bill / Fetch Bill Button & Card ───
          if (_consumerNumberCtrl.text.trim().isNotEmpty && _selectedOperator != null) ...[
            const SizedBox(height: 16),
            BbpsFetchedBillCard(
              bill: _fetchedBill,
              isFetching: _isFetchingBill,
              primaryColor: primaryPurple,
              onFetchBill: _onFetchBill,
            ),
          ],

          // ─── Amount Input (Shown when Consumer ID & Operator are filled) ───
          if (_consumerNumberCtrl.text.trim().isNotEmpty && _selectedOperator != null) ...[
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.currency_rupee_rounded, size: 18, color: primaryPurple),
                SizedBox(width: 8),
                Text('Cylinder Amount (₹)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter amount e.g. 950',
                hintStyle: const TextStyle(color: Color(0xFFA9A6C3), fontSize: 13.5),
                filled: true,
                fillColor: fieldFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: fieldBorder, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [850, 950, 1050, 1150, 1250].map((amt) => InkWell(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                  ),
                  child: Text('₹$amt', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: primaryPurple)),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Instant Settlement Card ────────────────────────────────────────────
  Widget _buildInstantSettlementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: amberBg, shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: amberIcon, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Instant Settlement', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
                SizedBox(height: 3),
                Text(
                  'Direct settlement with your gas distribution company',
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: _instantSettlement,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryPurple,
            onChanged: (v) => setState(() => _instantSettlement = v),
          ),
        ],
      ),
    );
  }

  // ─── Secure Payments Card ───────────────────────────────────────────────
  Widget _buildSecurePaymentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryPurple, deepPurple]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('100% Secure Payments', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: primaryPurple)),
                SizedBox(height: 3),
                Text(
                  'Your transactions are protected with bank-level security',
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: primaryPurple, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _onFetchBill() async {
    FocusScope.of(context).unfocus();
    final account = _consumerNumberCtrl.text.trim();
    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Consumer ID / BP number')),
      );
      return;
    }
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gas cylinder operator')),
      );
      return;
    }

    final op = _selectedOp ?? _operators.firstWhere(
      (e) => e['label'] == _selectedOperator || e['name'] == _selectedOperator,
      orElse: () => <String, dynamic>{},
    );
    String spKey = (op['spkey'] ?? op['id'] ?? '').toString();
    if (spKey.isEmpty) {
      final name = _selectedOperator!.toLowerCase();
      if (name.contains('indane')) {
        spKey = '303';
      } else if (name.contains('bharat') || name.contains('bpcl')) {
        spKey = '301';
      } else if (name.contains('hp')) {
        spKey = '302';
      } else {
        spKey = '301';
      }
    }

    setState(() => _isFetchingBill = true);
    try {
      final bill = await BbpsApiService.fetchBill(
        spKey: spKey,
        account: account,
      );
      if (mounted) {
        setState(() {
          _isFetchingBill = false;
          _fetchedBill = bill;
          if (bill.dueAmount > 0) {
            _amountCtrl.text = bill.dueAmount.toStringAsFixed(2);
          }
        });
        if (bill.isSuccess && bill.dueAmount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bill fetched successfully! Amount: ₹${bill.dueAmount.toStringAsFixed(2)}'), backgroundColor: const Color(0xFF10B981)),
          );
        } else if (!bill.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(bill.message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching bill: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleProceed() async {
    if (_consumerNumberCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Consumer ID / BP number')),
      );
      return;
    }
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an operator')),
      );
      return;
    }

    final amtVal = double.tryParse(_amountCtrl.text.trim());
    if (amtVal == null || amtVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book cylinder')),
      );
      return;
    }

    _razorpayService.openPaymentGateway(
      amount: amtVal,
      description: 'Gas Cylinder Booking – $_selectedOperator',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitGasCylinder(auth: auth, razorpayPaymentId: response.paymentId ?? '', amountVal: amtVal);
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${response.message ?? "Unknown error"}')),
          );
        }
      },
    );
  }

  Future<void> _doSubmitGasCylinder({required dynamic auth, required String razorpayPaymentId, required double amountVal}) async {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    try {
      final res = await ApiService.postApi('/gas-cylinder/pay', {
        'user_id': auth.userId,
        'consumer_number': _consumerNumberCtrl.text.trim(),
        'operator_name': _selectedOperator ?? '',
        'amount': amountVal.toStringAsFixed(2),
        'fetch_bill_id': _fetchedBill?.fetchBillId ?? '',
        'ref_id': _fetchedBill?.refId ?? '',
        'customer_name': _fetchedBill?.customerName ?? '',
        'bill_number': _fetchedBill?.billNumber ?? '',
        'due_date': _fetchedBill?.dueDate ?? '',
        'razorpay_payment_id': razorpayPaymentId,
        'payment_status': 'paid',
      });
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final txnId = data['merchant_txn_id']?.toString() ?? 'GAS${now.millisecondsSinceEpoch}';

      final receipt = BbpsReceiptModel(
        serviceCategory: 'Gas Cylinder Booking',
        operatorName: _selectedOperator ?? 'LPG Provider',
        accountNumber: _consumerNumberCtrl.text.trim(),
        customerName: _fetchedBill?.customerName ?? '',
        merchantTxnId: txnId,
        dateTimeStr: dtStr,
        amount: amountVal,
        status: 'Success',
        billNumber: _fetchedBill?.billNumber,
        dueDate: _fetchedBill?.dueDate,
        billPeriod: _fetchedBill?.billPeriod,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
        );
      }
    } catch (_) {
      final receipt = BbpsReceiptModel(
        serviceCategory: 'Gas Cylinder Booking',
        operatorName: _selectedOperator ?? 'LPG Provider',
        accountNumber: _consumerNumberCtrl.text.trim(),
        customerName: _fetchedBill?.customerName ?? '',
        merchantTxnId: 'GAS${now.millisecondsSinceEpoch}',
        dateTimeStr: dtStr,
        amount: amountVal,
        status: 'Success',
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
        );
      }
    }
  }

  // ─── Proceed Button ─────────────────────────────────────────────────────
  Widget _buildProceedButton() {
    final canProceed = _consumerNumberCtrl.text.trim().isNotEmpty &&
        _selectedOperator != null &&
        (double.tryParse(_amountCtrl.text.trim()) ?? 0) > 0;

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
        ),
        onPressed: _handleProceed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canProceed ? [primaryPurple, deepPurple] : [const Color(0xFFB7A9EE), const Color(0xFFA292E0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Proceed to Pay Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.2),
                ),
                Positioned(
                  right: 4,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: deepPurple, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


