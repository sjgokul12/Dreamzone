import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/api_service.dart';

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
  String? _selectedOperator;
  bool _instantSettlement = true;

  bool _operatorsLoading = true;
  String? _operatorsError;
  List<Map<String, dynamic>> _operators = [];

  @override
  void initState() {
    super.initState();
    _fetchOperators();
  }

  @override
  void dispose() {
    _consumerNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _operatorsLoading = true; _operatorsError = null; });
    try {
      final res = await ApiService.fetchApi('/gas-cylinder/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null && (data['operators'] as List).isNotEmpty) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _operatorsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
            _operators = [];
            _operatorsLoading = false;
            _operatorsError = data['message']?.toString() ?? 'Failed to load gas operators';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _operators = [];
          _operatorsLoading = false;
          _operatorsError = 'Failed to load gas operators. Please check connection and retry.';
        });
      }
    }
  }

  void _openOperatorPicker() {
    if (_operatorsLoading) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 18),
            const Text(
              'Select Operator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark),
            ),
            const SizedBox(height: 16),
            if (_operatorsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_operatorsError!, style: const TextStyle(color: textMuted)),
              )
            else
              ..._operators.map((op) {
                final isSelected = _selectedOperator == op['label'];
                return InkWell(
                  onTap: () {
                    setState(() => _selectedOperator = op['label'] as String);
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
                        Icon(Icons.propane_tank_rounded, color: primaryPurple, size: 20),
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
              }),
          ],
        ),
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
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
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

  // ─── Proceed Button ─────────────────────────────────────────────────────
  Widget _buildProceedButton() {
    final canProceed = _consumerNumberCtrl.text.trim().isNotEmpty && _selectedOperator != null;

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
        ),
        onPressed: () {
          if (_consumerNumberCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your Consumer / BP number')),
            );
            return;
          }
          if (_selectedOperator == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select an operator')),
            );
            return;
          }
          // TODO: Wire this up to the Gas Cylinder payment API,
          // the same way landline_screen.dart / dth_screen.dart call theirs.
        },
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