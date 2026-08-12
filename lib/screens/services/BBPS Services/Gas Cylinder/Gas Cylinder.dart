import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

typedef GasCylinder = GasCylinderScreen;

class GasCylinderScreen extends StatefulWidget {
  const GasCylinderScreen({super.key});
  @override
  State<GasCylinderScreen> createState() => _GasCylinderScreenState();
}

class _GasCylinderScreenState extends State<GasCylinderScreen>
    with TickerProviderStateMixin {

  static const Color primaryRose   = Color(0xFF00A896);
  static const Color primaryOrange = Color(0xFFFF6B00);
  static const Color accentNavy    = Color(0xFF0F172A);
  static const Color accentRed     = Color(0xFFFF6B00);
  static const Color bgEnd         = Color(0xFFF4FBF7);
  static const Color cardWhite     = Colors.white;
  static const Color textDark      = Color(0xFF0F172A);
  static const Color textMuted     = Color(0xFF64748B);
  static const Color borderColor   = Color(0xFFFECDD3);
  static const Color inputFill     = Color(0xFFFFF1F2);

  final _formKey        = GlobalKey<FormState>();
  final _consumerIdCtrl = TextEditingController();
  final _amountCtrl     = TextEditingController();
  int?  _expandedIdx;

  // ─── Operators (pre-fetched on initState → INSTANT picker) ───────────────
  List<Map<String, dynamic>> _operators   = [];
  bool                        _opsLoading = true;
  String?                     _opsError;
  Map<String, dynamic>?       _selectedOp;

  bool    _submitting    = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  String get _base => ApiService.baseUrl;
  bool get _canShowAmount =>
      _consumerIdCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code) {
    if (code.contains('BPCL'))   return const Color(0xFF0284C7);
    if (code.contains('HPCL'))   return const Color(0xFFE11D48);
    if (code.contains('INDANE')) return const Color(0xFFEA580C);
    return primaryRose;
  }

  static IconData _iconFor(String code) {
    if (code.contains('BPCL'))   return Icons.local_fire_department_rounded;
    if (code.contains('HPCL'))   return Icons.propane_rounded;
    if (code.contains('INDANE')) return Icons.fireplace_rounded;
    return Icons.propane_tank_rounded;
  }

  @override
  void initState() {
    super.initState();
    _fetchOperators(); // ✅ Pre-fetch immediately → picker opens instantly
  }

  @override
  void dispose() {
    _consumerIdCtrl.dispose(); _amountCtrl.dispose(); super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/gas-cylinder/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
          _opsError = data['message']?.toString() ?? 'Failed to load gas providers';
          _opsLoading = false;
        });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _opsError = 'Failed to connect to server. Tap Retry.';
        _opsLoading = false;
      });
      }
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) { _snack('Please select an LPG operator', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await http.post(
        Uri.parse('$_base/gas-cylinder/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':       auth.userId,
          'consumer_no':   _consumerIdCtrl.text.trim(),
          'operator_id':   _selectedOp!['spkey']?.toString() ?? '',
          'operator_name': _selectedOp!['label']?.toString() ?? '',
          'amount':        _amountCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
        _submitting    = false;
        _resultStatus  = data['success'] == true ? (data['status']?.toString() ?? 'success') : 'failed';
        _resultMessage = data['message']?.toString() ?? (_resultStatus == 'success' ? 'LPG bill paid!' : 'Payment failed');
        _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'LPG${DateTime.now().millisecondsSinceEpoch}';
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _submitting = false; _resultStatus = 'pending';
        _resultMessage = "Couldn't confirm payment. Check history.";
        _merchantTxnId = 'LPG${DateTime.now().millisecondsSinceEpoch}';
      });
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
      ]),
      backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Select LPG Provider',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                Text(_opsLoading ? 'Loading…' : '${_operators.length} providers',
                    style: const TextStyle(fontSize: 12, color: textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.propane_tank_rounded, color: primaryRose, size: 20),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(
            child: _opsLoading
                ? const Padding(padding: EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: primaryRose, strokeWidth: 2.5),
                      SizedBox(height: 14),
                      Text('Loading LPG providers…', style: TextStyle(color: textMuted)),
                    ]))
                : _opsError != null
                    ? Padding(padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 10),
                          Text(_opsError!, textAlign: TextAlign.center, maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: textMuted, fontSize: 12)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () { Navigator.pop(ctx); _fetchOperators(); },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryRose, foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ]))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        shrinkWrap: true,
                        itemCount: _operators.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (_, i) {
                          final op    = _operators[i];
                          final label = op['label']?.toString() ?? '';
                          final code  = op['code']?.toString() ?? '';
                          final co    = op['company']?.toString() ?? '';
                          final col   = _colorFor(code);
                          final icon  = _iconFor(code);
                          final isSel = _selectedOp != null &&
                              op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Icon(icon, color: col, size: 24),
                            ),
                            title: Text(label, style: TextStyle(fontSize: 14,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDark)),
                            subtitle: co.isNotEmpty ? Text(co, style: const TextStyle(fontSize: 12, color: textMuted)) : null,
                            trailing: isSel
                                ? const Icon(Icons.check_circle_rounded, color: primaryRose, size: 22)
                                : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            onTap: () { setState(() => _selectedOp = op); Navigator.pop(ctx); },
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgEnd,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: _resultStatus != null ? _buildResult() : Column(children: [
                _buildAppBar(context),
                Expanded(child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Form(key: _formKey, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildHero(),
                    const SizedBox(height: 18),
                    _buildPills(),
                    const SizedBox(height: 20),
                    _buildFormCard(),
                    if (_canShowAmount) ...[const SizedBox(height: 24), _buildSubmitBtn()],
                    const SizedBox(height: 24),
                    _buildAssurance(),
                    const SizedBox(height: 24),
                  ])),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(onTap: () => Navigator.maybePop(ctx), borderRadius: BorderRadius.circular(16),
        child: Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 18))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryRose.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: primaryRose.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: primaryRose, size: 18),
          SizedBox(width: 6),
          Text('BBPS Assured', style: TextStyle(color: primaryRose, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
    ]),
  );

  Widget _buildHero() => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [primaryRose, Color(0xFF028090), accentNavy],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: primaryRose.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 16),
            SizedBox(width: 4),
            Text('LPG BOOKING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ])),
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.propane_tank_rounded, color: Colors.white, size: 22)),
      ]),
      const SizedBox(height: 18),
      RichText(text: const TextSpan(
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.2, fontFamily: 'Roboto'),
        children: [
          TextSpan(text: 'PAY YOUR ', style: TextStyle(color: Colors.white)),
          TextSpan(text: '(LPG Cylinder Bill)', style: TextStyle(color: Color(0xFFFFD1D1), fontWeight: FontWeight.w900)),
        ])),
      const SizedBox(height: 8),
      Text('Select your LPG provider and enter Consumer ID',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.88), height: 1.4)),
    ]),
  );

  Widget _buildPills() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _pill(Icons.badge_rounded, 'Consumer ID'),
      _pill(Icons.propane_tank_rounded, 'Operators'),
      _pill(Icons.bolt_rounded, 'Instant'),
      _pill(Icons.security_rounded, 'Secured'),
    ]),
  );

  Widget _pill(IconData icon, String label) => Column(children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: primaryRose, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
  ]);

  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selCode  = _selectedOp?['code']?.toString() ?? '';
    final selColor = _selectedOp != null ? _colorFor(selCode) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selCode) : Icons.propane_tank_rounded;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Consumer ID
        const Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: primaryRose),
          SizedBox(width: 8),
          Text('Consumer ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _consumerIdCtrl,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')), LengthLimitingTextInputFormatter(20)],
          decoration: InputDecoration(
            hintText: 'Enter your LPG Consumer ID',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true, fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.tag_rounded, color: primaryRose, size: 20),
            suffixIcon: _consumerIdCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _consumerIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryRose, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Consumer ID' : null,
        ),

        const SizedBox(height: 22),

        // Operators
        const Row(children: [
          Icon(Icons.propane_tank_rounded, size: 18, color: primaryRose),
          SizedBox(width: 8),
          Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _openPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: _opsLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryRose, strokeWidth: 2))
                    : Icon(selIcon, color: selColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _opsLoading ? 'Loading providers…' : selLabel ?? 'Select LPG Provider',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14,
                    fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w400 : FontWeight.w700,
                    color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(_opsError != null ? 'Retry' : 'Choose',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryRose))),
            ]),
          ),
        ),

        if (_opsError != null) ...[
          const SizedBox(height: 6),
          GestureDetector(onTap: _fetchOperators,
            child: Row(children: [
              const Icon(Icons.refresh_rounded, size: 14, color: accentRed),
              const SizedBox(width: 4),
              Expanded(child: Text(_opsError!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: accentRed))),
            ])),
        ],

        if (_canShowAmount) ...[
          const SizedBox(height: 22),
          const Row(children: [
            Icon(Icons.currency_rupee_rounded, size: 18, color: primaryRose),
            SizedBox(width: 8),
            Text('Bill Amount (₹)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter bill amount',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true, fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryRose, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryRose, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter bill amount';
              if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: [700, 850, 900, 1050, 1200].map((amt) => InkWell(
              onTap: () => setState(() => _amountCtrl.text = amt.toString()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryRose.withValues(alpha: 0.25))),
                child: Text('₹$amt', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryRose))),
            )).toList()),
        ],
      ]),
    );
  }

  Widget _buildSubmitBtn() => SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 6, shadowColor: primaryRose.withValues(alpha: 0.35)),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting ? [Colors.grey.shade400, Colors.grey.shade500] : [primaryRose, const Color(0xFF028090)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18)),
        child: Container(alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Pay LPG Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ])),
      ),
    ),
  );

  Widget _buildResult() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? const Color(0xFFF59E0B) : Colors.redAccent;
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'Bill Paid!' : isPen ? 'Processing…' : 'Payment Failed';
    return Padding(padding: const EdgeInsets.all(20),
      child: Container(padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(color: col.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: col, size: 48)),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: col)),
          const SizedBox(height: 10),
          Text(_resultMessage ?? '', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5)),
          const SizedBox(height: 22),
          Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryRose.withValues(alpha: 0.2))),
            child: Column(children: [
              const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryRose, letterSpacing: 0.5)),
            ])),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _consumerIdCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: primaryRose, foregroundColor: Colors.white, elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Pay Another Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            )),
        ])));
  }

  Widget _buildAssurance() => Container(
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6))]),
    child: Column(children: [
      _tile(0, Icons.bolt_rounded, const Color(0xFFF59E0B), 'Instant Booking', 'Direct settlement with OMC',
          '⚡ Real-time LPG booking confirmation sent directly to your oil marketing company.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(1, Icons.shield_rounded, const Color(0xFF10B981), '100% BBPS Secure', 'Encrypted via BBPS network',
          '🛡️ 256-bit SSL encrypted payment authorized by NPCI.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(2, Icons.receipt_long_rounded, primaryRose, 'Instant Receipt', 'Official LPG booking proof',
          '🧾 Download official BBPS receipt after successful booking.'),
    ]),
  );

  Widget _tile(int idx, IconData icon, Color color, String title, String sub, String detail) {
    final isExp = _expandedIdx == idx;
    return InkWell(onTap: () => setState(() => _expandedIdx = isExp ? null : idx),
      borderRadius: BorderRadius.circular(28),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
              Text(sub, style: const TextStyle(fontSize: 12, color: textMuted)),
            ])),
            Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryRose, size: 22),
          ]),
          if (isExp) ...[
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryRose.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryRose.withValues(alpha: 0.15))),
              child: Text(detail, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF028090), height: 1.35))),
          ],
        ])));
  }
}
