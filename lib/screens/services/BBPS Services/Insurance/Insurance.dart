import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

typedef Insurance       = InsuranceScreen;
typedef InsurancePolicy = InsuranceScreen;

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with TickerProviderStateMixin {

  static const Color primaryLavender = Color(0xFF00A896);
  static const Color accentPurple    = Color(0xFF028090);
  static const Color accentNavy      = Color(0xFF0F172A);
  static const Color bgEnd           = Color(0xFFF4FBF7);
  static const Color cardWhite       = Colors.white;
  static const Color textDark        = Color(0xFF2E1065);
  static const Color textMuted       = Color(0xFF6B7280);
  static const Color borderColor     = Color(0xFFE9D5FF);
  static const Color inputBg         = Color(0xFFF8F0FF);

  final _formKey            = GlobalKey<FormState>();
  final _subscriptionIdCtrl = TextEditingController();
  final _dobCtrl            = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _amountCtrl         = TextEditingController();
  final _searchCtrl         = TextEditingController();
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
      _subscriptionIdCtrl.text.trim().isNotEmpty &&
      _dobCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _selectedOp != null;

  static Color _colorFor(String name) {
    final k = name.toLowerCase();
    if (k.contains('lic'))     return const Color(0xFFA855F7);
    if (k.contains('hdfc'))    return const Color(0xFF0284C7);
    if (k.contains('icici'))   return const Color(0xFFE11D48);
    if (k.contains('sbi'))     return const Color(0xFF059669);
    if (k.contains('bajaj'))   return const Color(0xFFD97706);
    if (k.contains('birla'))   return const Color(0xFF7C3AED);
    if (k.contains('max'))     return const Color(0xFF2563EB);
    if (k.contains('star'))    return const Color(0xFF0EA5E9);
    if (k.contains('religare')||k.contains('care')) return const Color(0xFF14B8A6);
    return primaryLavender;
  }

  static IconData _iconFor(String name) {
    final k = name.toLowerCase();
    if (k.contains('health')) return Icons.health_and_safety_rounded;
    if (k.contains('motor') || k.contains('auto')) return Icons.directions_car_rounded;
    if (k.contains('life')) return Icons.family_restroom_rounded;
    return Icons.shield_rounded;
  }

  @override
  void initState() {
    super.initState();
    _fetchOperators(); // ✅ Pre-fetch on screen open → INSTANT picker
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subscriptionIdCtrl.dispose(); _dobCtrl.dispose(); _emailCtrl.dispose();
    _amountCtrl.dispose(); _searchCtrl.dispose(); super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryLavender,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() => _dobCtrl.text = formatted);
    }
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/insurance/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
          _opsError = data['message']?.toString() ?? 'Failed to load insurance providers';
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
    if (_selectedOp == null) { _snack('Please select an insurance provider', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await http.post(
        Uri.parse('$_base/insurance/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':         auth.userId,
          'policy_no':       _subscriptionIdCtrl.text.trim(),
          'dob':             _dobCtrl.text.trim(),
          'email':           _emailCtrl.text.trim(),
          'operator_id':     _selectedOp!['spkey']?.toString() ?? '',
          'operator_name':   _selectedOp!['label']?.toString() ?? '',
          'amount':          _amountCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
        _submitting    = false;
        _resultStatus  = data['success'] == true ? (data['status']?.toString() ?? 'success') : 'failed';
        _resultMessage = data['message']?.toString() ?? (_resultStatus == 'success' ? 'Insurance premium paid!' : 'Payment failed');
        _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'INS${DateTime.now().millisecondsSinceEpoch}';
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _submitting = false; _resultStatus = 'pending';
        _resultMessage = "Couldn't confirm payment. Check history.";
        _merchantTxnId = 'INS${DateTime.now().millisecondsSinceEpoch}';
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
                    const Text('Select Insurance Provider',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} insurance companies available',
                        style: const TextStyle(fontSize: 12, color: textMuted)),
                  ])),
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.shield_rounded, color: primaryLavender, size: 20)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchCtrl, onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search insurance company name…',
                    hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryLavender, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded, color: textMuted, size: 18),
                            onPressed: () { _searchCtrl.clear(); setModal(() {}); })
                        : null,
                    filled: true, fillColor: inputBg,
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
                          CircularProgressIndicator(color: primaryLavender, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading insurance companies…', style: TextStyle(color: textMuted)),
                        ]))
                    : _opsError != null
                        ? Padding(padding: const EdgeInsets.all(28),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(_opsError!, textAlign: TextAlign.center, maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: textMuted, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () { Navigator.pop(ctx); _fetchOperators(); },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(backgroundColor: primaryLavender, foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ]))
                        : filtered.isEmpty
                            ? const Padding(padding: EdgeInsets.all(32),
                                child: Text('No insurance companies match your search', style: TextStyle(color: textMuted)))
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
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDark)),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, color: primaryLavender, size: 22)
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
          border: Border.all(color: primaryLavender.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: primaryLavender.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: primaryLavender, size: 18),
          SizedBox(width: 6),
          Text('BBPS Assured', style: TextStyle(color: primaryLavender, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
    ]),
  );

  Widget _buildHero() => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [primaryLavender, accentPurple, accentNavy],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: primaryLavender.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 16),
            SizedBox(width: 4),
            Text('INSURANCE PREMIUM', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ])),
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22)),
      ]),
      const SizedBox(height: 18),
      RichText(text: const TextSpan(
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.2, fontFamily: 'Roboto'),
        children: [
          TextSpan(text: 'PAY YOUR ', style: TextStyle(color: Colors.white)),
          TextSpan(text: '(Insurance Premium)', style: TextStyle(color: Color(0xFFE9D5FF), fontWeight: FontWeight.w900)),
        ])),
      const SizedBox(height: 8),
      Text('Enter Policy No., DOB, Email and select your Insurance Provider',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.88), height: 1.4)),
    ]),
  );

  Widget _buildPills() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _pill(Icons.receipt_long_rounded, 'Policy No.'),
      _pill(Icons.shield_rounded, 'Insurers'),
      _pill(Icons.bolt_rounded, 'Instant'),
      _pill(Icons.security_rounded, 'Secured'),
    ]),
  );

  Widget _pill(IconData icon, String label) => Column(children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: primaryLavender, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
  ]);

  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selColor = _selectedOp != null ? _colorFor(selLabel!) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selLabel!) : Icons.shield_outlined;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Policy / Subscription ID
        const Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: primaryLavender),
          SizedBox(width: 8),
          Text('Policy / Subscription Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _subscriptionIdCtrl,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\/]')), LengthLimitingTextInputFormatter(25)],
          decoration: InputDecoration(
            hintText: 'Enter Policy / Subscription Number',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true, fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.receipt_long_rounded, color: primaryLavender, size: 20),
            suffixIcon: _subscriptionIdCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _subscriptionIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryLavender, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Policy Number' : null,
        ),

        const SizedBox(height: 18),

        // Date of Birth
        const Row(children: [
          Icon(Icons.cake_outlined, size: 18, color: primaryLavender),
          SizedBox(width: 8),
          Text('Date of Birth (YYYY-MM-DD)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(16),
          child: IgnorePointer(
            child: TextFormField(
              controller: _dobCtrl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
              decoration: InputDecoration(
                hintText: 'Select Date of Birth',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true, fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(Icons.calendar_month_rounded, color: primaryLavender, size: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryLavender, width: 2)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Select Date of Birth' : null,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Email ID
        const Row(children: [
          Icon(Icons.email_outlined, size: 18, color: primaryLavender),
          SizedBox(width: 8),
          Text('Email Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          decoration: InputDecoration(
            hintText: 'Enter your Email address',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true, fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.mail_rounded, color: primaryLavender, size: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryLavender, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your Email address';
            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid Email address';
            return null;
          },
        ),

        const SizedBox(height: 22),

        // Operators
        const Row(children: [
          Icon(Icons.shield_rounded, size: 18, color: primaryLavender),
          SizedBox(width: 8),
          Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _openPicker, borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: _opsLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryLavender, strokeWidth: 2))
                    : Icon(selIcon, color: selColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _opsLoading ? 'Loading insurance companies…' : selLabel ?? 'Select Insurance Provider',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14,
                    fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w400 : FontWeight.w700,
                    color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(_opsError != null ? 'Retry' : 'Choose',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryLavender))),
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
            Icon(Icons.currency_rupee_rounded, size: 18, color: primaryLavender),
            SizedBox(width: 8),
            Text('Premium Amount (₹)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter premium amount e.g. 5000',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true, fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryLavender, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryLavender, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter premium amount';
              if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: [1000, 2500, 5000, 10000, 15000, 25000].map((amt) => InkWell(
              onTap: () => setState(() => _amountCtrl.text = amt.toString()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryLavender.withValues(alpha: 0.25))),
                child: Text('₹$amt', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryLavender))),
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
          elevation: 6, shadowColor: primaryLavender.withValues(alpha: 0.35)),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting ? [Colors.grey.shade400, Colors.grey.shade500] : [primaryLavender, accentPurple],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18)),
        child: Container(alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Pay Insurance Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
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
    final title = isOk ? 'Premium Paid!' : isPen ? 'Processing…' : 'Payment Failed';
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
            decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryLavender.withValues(alpha: 0.2))),
            child: Column(children: [
              const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryLavender, letterSpacing: 0.5)),
            ])),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _subscriptionIdCtrl.clear(); _dobCtrl.clear(); _emailCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: primaryLavender, foregroundColor: Colors.white, elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Pay Another Premium', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            )),
        ])));
  }

  Widget _buildAssurance() => Container(
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6))]),
    child: Column(children: [
      _tile(0, Icons.bolt_rounded, const Color(0xFFF59E0B), 'Instant Policy Settlement', 'Direct settlement with insurer', '⚡ Real-time insurance premium credited directly to policy account.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(1, Icons.shield_rounded, const Color(0xFF10B981), '100% BBPS Secure', 'Encrypted via BBPS network', '🛡️ 256-bit SSL encrypted payment authorized by NPCI.'),
      const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      _tile(2, Icons.receipt_long_rounded, primaryLavender, 'Instant Receipt', 'Official policy payment proof', '🧾 Download official BBPS receipt after premium payment.'),
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
            Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryLavender, size: 22),
          ]),
          if (isExp) ...[
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryLavender.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryLavender.withValues(alpha: 0.15))),
              child: Text(detail, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accentPurple, height: 1.35))),
          ],
        ])));
  }
}
