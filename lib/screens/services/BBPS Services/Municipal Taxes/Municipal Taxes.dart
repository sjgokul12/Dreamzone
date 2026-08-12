import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

typedef MunicipalTaxes = MunicipalTaxesScreen;
typedef MunicipalTax   = MunicipalTaxesScreen;

class MunicipalTaxesScreen extends StatefulWidget {
  const MunicipalTaxesScreen({super.key});

  @override
  State<MunicipalTaxesScreen> createState() => _MunicipalTaxesScreenState();
}

class _MunicipalTaxesScreenState extends State<MunicipalTaxesScreen>
    with TickerProviderStateMixin {

  static const Color primaryTeal     = Color(0xFF00A896);
  static const Color secondaryTeal   = Color(0xFF0284C7);
  static const Color textDarkHeading = Color(0xFF0F172A);
  static const Color textSubdued     = Color(0xFF64748B);
  static const Color bgCanvas        = Color(0xFFF4FBF7);
  static const Color cardSurface     = Colors.white;
  static const Color borderColor     = Color(0xFFBAE6FD);
  static const Color inputFill       = Color(0xFFF0F9FF);

  final _formKey        = GlobalKey<FormState>();
  final _consumerIdCtrl = TextEditingController();
  final _amountCtrl     = TextEditingController();
  final _searchCtrl     = TextEditingController();
  int?  _expandedIdx;

  // ─── Operators: pre-fetched on initState → INSTANT picker ────────────────
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

  static Color _colorFor(String name) {
    final k = name.toLowerCase();
    if (k.contains('chennai') || k.contains('hyderabad')) return const Color(0xFF10B981);
    if (k.contains('mumbai') || k.contains('kalyan') || k.contains('kolhapur')) return const Color(0xFF0284C7);
    if (k.contains('kolkata') || k.contains('delhi')) return const Color(0xFF8B5CF6);
    if (k.contains('ahmedabad') || k.contains('gujarat')) return const Color(0xFFF59E0B);
    if (k.contains('gram') || k.contains('panchayat')) return const Color(0xFF059669);
    return primaryTeal;
  }

  static IconData _iconFor(String name) {
    final k = name.toLowerCase();
    if (k.contains('gram') || k.contains('panchayat')) return Icons.gavel_rounded;
    if (k.contains('property') || k.contains('land')) return Icons.home_rounded;
    if (k.contains('trade') || k.contains('market')) return Icons.store_rounded;
    return Icons.location_city_rounded;
  }

  @override
  void initState() {
    super.initState();
    _fetchOperators(); // ✅ Pre-fetch on screen open → INSTANT picker
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _consumerIdCtrl.dispose(); _amountCtrl.dispose(); _searchCtrl.dispose(); super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/municipal-taxes/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
          _opsError = data['message']?.toString() ?? 'Failed to load municipal authorities';
          _opsLoading = false;
        });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _opsError = 'Failed to connect. Ensure python run.py is running.';
        _opsLoading = false;
      });
      }
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) { _snack('Please select a municipal tax operator', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await http.post(
        Uri.parse('$_base/municipal-taxes/pay'),
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
        _resultMessage = data['message']?.toString() ?? (_resultStatus == 'success' ? 'Tax paid!' : 'Payment failed');
        _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'MUN${DateTime.now().millisecondsSinceEpoch}';
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _submitting = false; _resultStatus = 'pending';
        _resultMessage = "Couldn't confirm payment. Check history.";
        _merchantTxnId = 'MUN${DateTime.now().millisecondsSinceEpoch}';
      });
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
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
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final q        = _searchCtrl.text.toLowerCase();
          final filtered = _operators.where((op) {
            final label = (op['label'] ?? op['name'] ?? '').toString().toLowerCase();
            return label.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Container(width: 44, height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Select Municipal Authority',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkHeading)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} authorities available',
                        style: const TextStyle(fontSize: 12, color: textSubdued)),
                  ])),
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.location_city_rounded, color: primaryTeal, size: 20)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchCtrl, onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search municipal corporation…',
                    hintStyle: const TextStyle(color: textSubdued, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryTeal, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded, color: textSubdued, size: 18),
                            onPressed: () { _searchCtrl.clear(); setModal(() {}); })
                        : null,
                    filled: true, fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: _opsLoading
                    ? const Padding(padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: primaryTeal, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading authorities…', style: TextStyle(color: textSubdued)),
                        ]))
                    : _opsError != null
                        ? Padding(padding: const EdgeInsets.all(28),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(_opsError!, textAlign: TextAlign.center, maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: textSubdued, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () { Navigator.pop(ctx); _fetchOperators(); },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ]))
                        : filtered.isEmpty
                            ? const Padding(padding: EdgeInsets.all(32),
                                child: Text('No authorities match your search', style: TextStyle(color: textSubdued)))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) {
                                  final op    = filtered[i];
                                  final label = op['label']?.toString() ?? '';
                                  final col   = _colorFor(label);
                                  final icon  = _iconFor(label);
                                  final isSel = _selectedOp != null &&
                                      op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                                    leading: Container(padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(icon, color: col, size: 20)),
                                    title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDarkHeading)),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, color: primaryTeal, size: 22)
                                        : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                    onTap: () { setState(() => _selectedOp = op); Navigator.pop(ctx); },
                                  );
                                }),
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
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
          decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDarkHeading, size: 18))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: primaryTeal, size: 18),
          SizedBox(width: 6),
          Text('BBPS Assured', style: TextStyle(color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
    ]),
  );

  Widget _buildHero() => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [primaryTeal, secondaryTeal, Color(0xFF0F172A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.location_city_rounded, color: Colors.amberAccent, size: 16),
            SizedBox(width: 4),
            Text('MUNICIPAL TAX', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ])),
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22)),
      ]),
      const SizedBox(height: 18),
      RichText(text: const TextSpan(
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.2, fontFamily: 'Roboto'),
        children: [
          TextSpan(text: 'PAY YOUR ', style: TextStyle(color: Colors.white)),
          TextSpan(text: '(Municipal Tax)', style: TextStyle(color: Color(0xFFBAE6FD), fontWeight: FontWeight.w900)),
        ])),
      const SizedBox(height: 8),
      Text('Enter Consumer ID / Property Tax No. & select your Corporation',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.88), height: 1.4)),
    ]),
  );

  Widget _buildPills() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _pill(Icons.badge_rounded, 'Consumer ID'),
      _pill(Icons.location_city_rounded, 'Corporation'),
      _pill(Icons.bolt_rounded, 'Instant'),
      _pill(Icons.security_rounded, 'Secured'),
    ]),
  );

  Widget _pill(IconData icon, String label) => Column(children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: primaryTeal, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSubdued)),
  ]);

  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selColor = _selectedOp != null ? _colorFor(selLabel!) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selLabel!) : Icons.location_city_outlined;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 🟢 1. CONSUMER ID / PROPERTY TAX NO. FIRST!
        const Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: primaryTeal),
          SizedBox(width: 8),
          Text('Consumer ID / Property Tax No.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDarkHeading)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _consumerIdCtrl,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDarkHeading),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\/]')), LengthLimitingTextInputFormatter(25)],
          decoration: InputDecoration(
            hintText: 'Enter Consumer ID / Property Tax No.',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true, fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.tag_rounded, color: primaryTeal, size: 20),
            suffixIcon: _consumerIdCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _consumerIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryTeal, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Property Tax / Consumer No.' : null,
        ),

        const SizedBox(height: 22),

        // 🟢 2. OPERATORS SECOND!
        const Row(children: [
          Icon(Icons.location_city_rounded, size: 18, color: primaryTeal),
          SizedBox(width: 8),
          Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDarkHeading)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _openPicker, borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: _opsLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2))
                    : Icon(selIcon, color: selColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _opsLoading ? 'Loading authorities…' : selLabel ?? 'Select Municipal Operator',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14,
                    fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w400 : FontWeight.w700,
                    color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDarkHeading))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(_opsError != null ? 'Retry' : 'Choose',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryTeal))),
            ]),
          ),
        ),

        if (_opsError != null) ...[
          const SizedBox(height: 6),
          GestureDetector(onTap: _fetchOperators,
            child: Row(children: [
              const Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
              const SizedBox(width: 4),
              Expanded(child: Text(_opsError!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent))),
            ])),
        ],

        if (_canShowAmount) ...[
          const SizedBox(height: 22),
          const Row(children: [
            Icon(Icons.currency_rupee_rounded, size: 18, color: primaryTeal),
            SizedBox(width: 8),
            Text('Tax Amount (₹)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDarkHeading)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDarkHeading),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter tax amount e.g. 1500',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true, fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryTeal, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryTeal, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter tax amount';
              if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: [500, 1000, 1500, 2500, 5000, 10000].map((amt) => InkWell(
              onTap: () => setState(() => _amountCtrl.text = amt.toString()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryTeal.withValues(alpha: 0.25))),
                child: Text('₹$amt', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryTeal))),
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
          elevation: 6, shadowColor: primaryTeal.withValues(alpha: 0.35)),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting ? [Colors.grey.shade400, Colors.grey.shade500] : [primaryTeal, secondaryTeal],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18)),
        child: Container(alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Pay Municipal Tax', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
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
    final title = isOk ? 'Tax Paid!' : isPen ? 'Processing…' : 'Payment Failed';
    return Padding(padding: const EdgeInsets.all(20),
      child: Container(padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(color: col.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: col, size: 48)),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: col)),
          const SizedBox(height: 10),
          Text(_resultMessage ?? '', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textSubdued, height: 1.5)),
          const SizedBox(height: 22),
          Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryTeal.withValues(alpha: 0.2))),
            child: Column(children: [
              const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textSubdued)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryTeal, letterSpacing: 0.5)),
            ])),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _consumerIdCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Pay Another Tax', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            )),
        ])));
  }

  Widget _buildAssurance() => Container(
    decoration: BoxDecoration(color: cardSurface, borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6))]),
    child: Column(children: [
      _tile(0, Icons.bolt_rounded, const Color(0xFFF59E0B), 'Instant Settlement', 'Direct settlement with municipal corporation', '⚡ Real-time property tax settlement credited directly to city corporation.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(1, Icons.shield_rounded, const Color(0xFF10B981), '100% BBPS Secure', 'Encrypted via BBPS network', '🛡️ 256-bit SSL encrypted payment authorized by NPCI.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(2, Icons.receipt_long_rounded, primaryTeal, 'Instant Receipt', 'Official property tax payment receipt', '🧾 Download official BBPS receipt after tax payment.'),
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
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading)),
              Text(sub, style: const TextStyle(fontSize: 12, color: textSubdued)),
            ])),
            Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryTeal, size: 22),
          ]),
          if (isExp) ...[
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryTeal.withValues(alpha: 0.15))),
              child: Text(detail, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: secondaryTeal, height: 1.35))),
          ],
        ])));
  }
}
