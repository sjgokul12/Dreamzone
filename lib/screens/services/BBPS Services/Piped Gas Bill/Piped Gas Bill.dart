import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

/// Convenient aliases
typedef PipedGasBill = PipedGasBillScreen;

class PipedGasBillScreen extends StatefulWidget {
  const PipedGasBillScreen({super.key});

  @override
  State<PipedGasBillScreen> createState() => _PipedGasBillScreenState();
}

class _PipedGasBillScreenState extends State<PipedGasBillScreen>
    with TickerProviderStateMixin {
  // Theme palette
  static const Color primaryCyan  = Color(0xFF00A896);
  static const Color primaryDark  = Color(0xFF028090);
  static const Color accentNavy   = Color(0xFF0F172A);
  static const Color accentAmber  = Color(0xFFFF6B00);
  static const Color accentRed    = Color(0xFFFF6B00);
  static const Color bgEnd        = Color(0xFFF4FBF7);
  static const Color cardWhite    = Colors.white;
  static const Color textDark     = Color(0xFF0F172A);
  static const Color textMuted    = Color(0xFF64748B);
  static const Color borderColor  = Color(0xFFBAE6FD);
  static const Color inputFill    = Color(0xFFF0F9FF);

  // Form
  final _formKey        = GlobalKey<FormState>();
  final _consumerIdCtrl = TextEditingController();
  final _amountCtrl     = TextEditingController();
  final _searchCtrl     = TextEditingController();
  int?  _expandedIdx;

  // ─── Operators: fetched on init, INSTANT when picker opens ────────────────
  List<Map<String, dynamic>> _operators   = [];
  bool                        _opsLoading = true;   // fetching in background
  String?                     _opsError;
  Map<String, dynamic>?       _selectedOp;

  // ─── Submit state ─────────────────────────────────────────────────────────
  bool    _submitting    = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String get _base => ApiService.baseUrl;

  bool get _canShowAmount =>
      _consumerIdCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('adani'))          return const Color(0xFF0EA5E9);
    if (k.contains('mahanagar') || k.contains('mgl'))  return const Color(0xFF0284C7);
    if (k.contains('indraprastha') || k.contains('igl')) return const Color(0xFF10B981);
    if (k.contains('gujarat') || k.contains('ggl') || k.contains('gspl') ||
        k.contains('sabarmati') || k.contains('sgl') || k.contains('charotar') ||
        k.contains('vadodara') || k.contains('irm')) {
      return const Color(0xFFF59E0B);
    }
    if (k.contains('torrent'))        return const Color(0xFF6366F1);
    if (k.contains('gail'))           return const Color(0xFF8B5CF6);
    if (k.contains('maharashtra') || k.contains('mngl')) return const Color(0xFFEC4899);
    if (k.contains('hpcl') || k.contains('hp oil') || k.contains('hindustan')) return const Color(0xFF22C55E);
    if (k.contains('indian oil') || k.contains('ioc')) return const Color(0xFFEF4444);
    if (k.contains('assam'))          return const Color(0xFF14B8A6);
    if (k.contains('haryana'))        return const Color(0xFFF97316);
    if (k.contains('rajasthan'))      return const Color(0xFFE11D48);
    if (k.contains('bhagyanagar'))    return const Color(0xFF0891B2);
    if (k.contains('central') || k.contains('up gas')) return const Color(0xFF7C3AED);
    if (k.contains('green gas'))      return const Color(0xFF059669);
    if (k.contains('godavari'))       return const Color(0xFF0D9488);
    if (k.contains('tripura'))        return const Color(0xFF2563EB);
    if (k.contains('purba') || k.contains('megha') || k.contains('naveriya') ||
        k.contains('unique') || k.contains('ucpgpl')) {
      return const Color(0xFF64748B);
    }
    return primaryCyan;
  }

  static IconData _iconFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('mahanagar') || k.contains('mgl')) return Icons.gas_meter_rounded;
    if (k.contains('indraprastha') || k.contains('igl')) return Icons.fireplace_rounded;
    if (k.contains('gujarat') || k.contains('ggl') || k.contains('sabarmati') ||
        k.contains('vadodara') || k.contains('charotar')) {
      return Icons.hvac_rounded;
    }
    if (k.contains('gail'))   return Icons.hub_rounded;
    if (k.contains('hpcl') || k.contains('hindustan') || k.contains('hp oil') ||
        k.contains('indian oil') || k.contains('ioc')) {
      return Icons.local_gas_station_rounded;
    }
    if (k.contains('torrent')) return Icons.bolt_rounded;
    if (k.contains('assam') || k.contains('tripura') || k.contains('purba') ||
        k.contains('megha') || k.contains('naveriya')) {
      return Icons.propane_rounded;
    }
    return Icons.local_fire_department_rounded;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // ✅ Pre-fetch operators immediately on screen open → INSTANT dropdown
    _fetchOperators();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _consumerIdCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── API: Fetch Operators (called on initState — not on picker open) ───────
  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/piped-gas/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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
        _opsError = 'Failed to connect. Tap Retry.';
        _opsLoading = false;
      });
      }
    }
  }

  // ─── API: Submit Bill ─────────────────────────────────────────────────────
  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) {
      _snack('Please select a piped gas operator', isError: true);
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _snack('Please login to pay bill', isError: true);
      return;
    }
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await ApiService.postApi('/piped-gas/pay', {
        'user_id':       auth.userId,
        'consumer_no':   _consumerIdCtrl.text.trim(),
        'operator_id':   _selectedOp!['spkey']?.toString() ?? '',
        'operator_name': _selectedOp!['label']?.toString() ?? '',
        'amount':        _amountCtrl.text.trim(),
      });
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus  = data['success'] == true ? (data['status']?.toString() ?? 'success') : 'failed';
          _resultMessage = data['message']?.toString() ?? (_resultStatus == 'success' ? 'Bill paid!' : 'Payment failed');
          _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'GAS${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus  = 'pending';
          _resultMessage = "Couldn't confirm payment. Check history shortly.";
          _merchantTxnId = 'GAS${DateTime.now().millisecondsSinceEpoch}';
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
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
      ]),
      backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Operator Picker (opens INSTANTLY — data already loaded) ─────────────
  void _openOperatorPicker() {
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
            final city  = (op['city'] ?? '').toString().toLowerCase();
            return label.contains(q) || city.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              const SizedBox(height: 12),
              Container(width: 44, height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10))),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Select Gas Operator',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    const SizedBox(height: 3),
                    Text(_opsLoading
                        ? 'Loading operators…'
                        : '${_operators.length} gas companies available',
                        style: const TextStyle(fontSize: 12, color: textMuted)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: primaryCyan, size: 20),
                  ),
                ]),
              ),
              // Search box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search gas company or city…',
                    hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: textMuted, size: 18),
                            onPressed: () { _searchCtrl.clear(); setModal(() {}); })
                        : null,
                    filled: true, fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Content
              Flexible(
                child: _opsLoading
                    // ✅ This should rarely show because we pre-fetch on initState
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: primaryCyan, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading gas operators…',
                              style: TextStyle(color: textMuted, fontSize: 13)),
                        ]))
                    : _opsError != null
                        ? Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(_opsError!, textAlign: TextAlign.center,
                                  maxLines: 4, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: textMuted, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () { Navigator.pop(ctx); _fetchOperators(); },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryCyan, foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ]))
                        : filtered.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No operators match your search',
                                    style: TextStyle(color: textMuted)))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) {
                                  final op    = filtered[i];
                                  final label = op['label']?.toString() ?? op['name']?.toString() ?? '';
                                  final city  = op['city']?.toString() ?? '';
                                  final code  = op['code']?.toString() ?? '';
                                  final col   = _colorFor(code, label);
                                  final icon  = _iconFor(code, label);
                                  final isSel = _selectedOp != null &&
                                      op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(icon, color: col, size: 20),
                                    ),
                                    title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                            color: textDark)),
                                    subtitle: city.isNotEmpty
                                        ? Text(city, style: const TextStyle(fontSize: 11, color: textMuted))
                                        : null,
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, color: primaryCyan, size: 22)
                                        : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                    onTap: () {
                                      setState(() => _selectedOp = op);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
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
              child: _resultStatus != null
                  ? _buildResultView()
                  : Column(children: [
                      _buildAppBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildHeroCard(),
                              const SizedBox(height: 18),
                              _buildQuickPills(),
                              const SizedBox(height: 20),
                              _buildFormCard(),
                              if (_canShowAmount) ...[
                                const SizedBox(height: 24),
                                _buildSubmitButton(),
                              ],
                              const SizedBox(height: 24),
                              _buildAssuranceCard(),
                              const SizedBox(height: 24),
                            ]),
                          ),
                        ),
                      ),
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        InkWell(
          onTap: () => Navigator.maybePop(ctx),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardWhite, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 18),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cardWhite, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryCyan.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: primaryCyan.withValues(alpha: 0.08),
                blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: const Row(children: [
            Icon(Icons.verified_rounded, color: primaryCyan, size: 18),
            SizedBox(width: 6),
            Text('BBPS Assured',
                style: TextStyle(color: primaryCyan, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  // ─── Hero Card ────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryCyan, primaryDark, accentNavy],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primaryCyan.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 16),
              SizedBox(width: 4),
              Text('PIPED GAS', style: TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.gas_meter_rounded, color: Colors.white, size: 22),
          ),
        ]),
        const SizedBox(height: 18),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              letterSpacing: 0.2, fontFamily: 'Roboto'),
          children: [
            TextSpan(text: 'PAY YOUR ',
                style: TextStyle(color: Colors.white)),
            TextSpan(text: '(Piped Gas Bill)',
                style: TextStyle(color: Color(0xFFFFD1D1), fontWeight: FontWeight.w900)),
          ],
        )),
        const SizedBox(height: 8),
        Text('Enter your Consumer Number and we\'ll take care of the rest!',
            style: TextStyle(fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88), height: 1.4)),
      ]),
    );
  }

  // ─── Quick Pills ──────────────────────────────────────────────────────────
  Widget _buildQuickPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardWhite, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _pill(Icons.badge_rounded, 'Consumer No.'),
        _pill(Icons.propane_tank_rounded, 'Operators'),
        _pill(Icons.bolt_rounded, 'Instant'),
        _pill(Icons.security_rounded, 'Secured'),
      ]),
    );
  }

  Widget _pill(IconData icon, String label) => Column(children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(
            color: primaryCyan.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(icon, color: primaryCyan, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
  ]);

  // ─── Form Card ────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString() ?? _selectedOp?['name']?.toString();
    final selCode  = _selectedOp?['code']?.toString() ?? '';
    final selColor = _selectedOp != null ? _colorFor(selCode, selLabel!) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selCode, selLabel!) : Icons.propane_tank_rounded;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── 1. Consumer No. ─────────────────────────────────────────────────
        const Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: primaryCyan),
          SizedBox(width: 8),
          Text('Consumer Number',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _consumerIdCtrl,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your Consumer / BP number',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true, fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.tag_rounded, color: primaryCyan, size: 20),
            suffixIcon: _consumerIdCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _consumerIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryCyan, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your Consumer Number';
            if (v.trim().length < 3) return 'Enter a valid Consumer Number';
            return null;
          },
        ),

        const SizedBox(height: 22),

        // ── 2. Operators (data already loaded, INSTANT open) ────────────────
        const Row(children: [
          Icon(Icons.propane_tank_rounded, size: 18, color: primaryCyan),
          SizedBox(width: 8),
          Text('Operators',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),

        InkWell(
          onTap: _openOperatorPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: inputFill, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: _opsLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: primaryCyan, strokeWidth: 2))
                    : Icon(selIcon, color: selColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _opsLoading
                      ? 'Loading operators…'
                      : selLabel ?? 'Select Gas Operator',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w400 : FontWeight.w700,
                    color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_opsError != null ? 'Retry' : 'Choose',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w800, color: primaryCyan)),
              ),
            ]),
          ),
        ),

        if (_opsError != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _fetchOperators,
            child: Row(children: [
              const Icon(Icons.refresh_rounded, size: 14, color: accentRed),
              const SizedBox(width: 4),
              Expanded(child: Text(_opsError!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: accentRed))),
            ]),
          ),
        ],

        // ── 3. Amount (appears after Consumer + Operator selected) ──────────
        if (_canShowAmount) ...[
          const SizedBox(height: 22),
          const Row(children: [
            Icon(Icons.currency_rupee_rounded, size: 18, color: primaryCyan),
            SizedBox(width: 8),
            Text('Bill Amount (₹)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter bill amount e.g. 350',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true, fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryCyan, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryCyan, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: accentRed, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: accentRed, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter the bill amount';
              if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: [200, 350, 500, 750, 1000, 1500].map((amt) => InkWell(
              onTap: () => setState(() => _amountCtrl.text = amt.toString()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryCyan.withValues(alpha: 0.25)),
                ),
                child: Text('₹$amt', style: const TextStyle(fontSize: 11.5,
                    fontWeight: FontWeight.bold, color: primaryCyan)),
              ),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  // ─── Submit Button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 6, shadowColor: primaryCyan.withValues(alpha: 0.35),
        ),
        onPressed: _submitting ? null : _handleProceed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _submitting
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [primaryCyan, primaryDark],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Pay Gas Bill', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ])),
        ),
      ),
    );
  }

  // ─── Result View ──────────────────────────────────────────────────────────
  Widget _buildResultView() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? const Color(0xFFF59E0B) : Colors.redAccent;
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'Bill Paid!' : isPen ? 'Processing…' : 'Payment Failed';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardWhite, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24, offset: const Offset(0, 10))],
        ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryCyan.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              const Text('Transaction Reference ID',
                  style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: primaryCyan, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _consumerIdCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan, foregroundColor: Colors.white, elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Pay Another Bill',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Assurance Card ───────────────────────────────────────────────────────
  Widget _buildAssuranceCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        _tile(0, Icons.bolt_rounded, const Color(0xFFF59E0B),
            'Instant Settlement', 'Direct settlement with your gas distribution company',
            '⚡ Real-time bill settlement directly with your city gas distribution company.'),
        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
        _tile(1, Icons.shield_rounded, const Color(0xFF10B981),
            '100% BBPS Secure', 'Encrypted transactions via BBPS network',
            '🛡️ 256-bit SSL encrypted payment authorized by NPCI through BBPS.'),
        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
        _tile(2, Icons.receipt_long_rounded, primaryCyan,
            'Instant Digital Receipt', 'Official proof of gas bill payment',
            '🧾 Download official BBPS receipt immediately after successful payment.'),
      ]),
    );
  }

  Widget _tile(int idx, IconData icon, Color color, String title, String sub, String detail) {
    final isExp = _expandedIdx == idx;
    return InkWell(
      onTap: () => setState(() => _expandedIdx = isExp ? null : idx),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 12, color: textMuted)),
            ])),
            Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: primaryCyan, size: 22),
          ]),
          if (isExp) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryCyan.withValues(alpha: 0.15)),
              ),
              child: Text(detail, style: const TextStyle(fontSize: 12.5,
                  fontWeight: FontWeight.w600, color: primaryDark, height: 1.35)),
            ),
          ],
        ]),
      ),
    );
  }
}
