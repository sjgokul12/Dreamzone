import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

typedef LoanPayment   = LoanPaymentScreen;
typedef LoanRepayment = LoanPaymentScreen;

class LoanPaymentScreen extends StatefulWidget {
  const LoanPaymentScreen({super.key});

  @override
  State<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends State<LoanPaymentScreen>
    with TickerProviderStateMixin {
  // ─── Theme Colors ────────────────────────────────────────────────────────
  static const Color primaryPurple     = Color(0xFF7C3AED);
  static const Color primaryDarkPurple = Color(0xFF6D28D9);
  static const Color accentBlue        = Color(0xFF3B82F6);
  static const Color bgLavender        = Color(0xFFF5EEFF);
  static const Color cardWhite         = Colors.white;
  static const Color textDark          = Color(0xFF1E1B4B);
  static const Color textMuted         = Color(0xFF6B7280);
  static const Color borderColor       = Color(0xFFEDE4FF);
  static const Color inputFill         = Color(0xFFF9F5FF);

  final _formKey       = GlobalKey<FormState>();
  final _loanAccCtrl   = TextEditingController();
  final _amountCtrl    = TextEditingController();
  final _searchCtrl    = TextEditingController();

  // ─── Operators State ──────────────────────────────────────────────────────
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
      _loanAccCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code, String loanType) {
    final k = '${code}_$loanType'.toLowerCase();
    if (k.contains('bank') || k.contains('dcb') || k.contains('au_bank') || k.contains('andhra')) return const Color(0xFF2563EB);
    if (k.contains('bajaj'))   return const Color(0xFFEA580C);
    if (k.contains('housing') || k.contains('home') || k.contains('aavas') || k.contains('aadhar') ||
        k.contains('altum') || k.contains('easy') || k.contains('capri_hf')) {
      return const Color(0xFF059669);
    }
    if (k.contains('vehicle') || k.contains('cars24') || k.contains('auto') || k.contains('baid')) return const Color(0xFF4F46E5);
    if (k.contains('micro') || k.contains('arohan') || k.contains('annapurna_mfi') || k.contains('chaitanya') || k.contains('agora')) return const Color(0xFFDB2777);
    if (k.contains('education') || k.contains('eduvanz') || k.contains('avanse')) return const Color(0xFF7C3AED);
    if (k.contains('msme') || k.contains('capri_global') || k.contains('ambit')) return const Color(0xFFD97706);
    if (k.contains('nidhi') || k.contains('ajeevak') || k.contains('alfastar')) return const Color(0xFF0D9488);
    if (k.contains('agri')) return const Color(0xFF16A34A);
    if (k.contains('adani'))   return const Color(0xFF0284C7);
    if (k.contains('aditya') || k.contains('birla')) return const Color(0xFF9333EA);
    return primaryPurple;
  }

  static IconData _iconFor(String loanType) {
    final k = loanType.toLowerCase();
    if (k.contains('housing') || k.contains('home')) return Icons.home_rounded;
    if (k.contains('vehicle') || k.contains('auto')) return Icons.directions_car_rounded;
    if (k.contains('education')) return Icons.school_rounded;
    if (k.contains('micro')) return Icons.handshake_rounded;
    if (k.contains('msme') || k.contains('business')) return Icons.business_center_rounded;
    if (k.contains('agri')) return Icons.agriculture_rounded;
    if (k.contains('nidhi')) return Icons.savings_rounded;
    if (k.contains('bank')) return Icons.account_balance_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  @override
  void initState() {
    super.initState();
    _fetchOperators();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _loanAccCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/loan-payment/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
            _opsError = data['message']?.toString() ?? 'Failed to load loan providers';
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
    if (_selectedOp == null) { _snack('Please select a loan provider', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await http.post(
        Uri.parse('$_base/loan-payment/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':         auth.userId,
          'loan_account_no': _loanAccCtrl.text.trim(),
          'operator_id':     _selectedOp!['spkey']?.toString() ?? '',
          'operator_name':   _selectedOp!['label']?.toString() ?? '',
          'amount':          _amountCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 60));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus  = data['success'] == true ? (data['status']?.toString() ?? 'success') : 'failed';
          _resultMessage = data['message']?.toString() ?? (_resultStatus == 'success' ? 'EMI paid successfully!' : 'Payment failed');
          _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'LOAN${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false; _resultStatus = 'pending';
          _resultMessage = "Couldn't confirm payment. Check status in transactions.";
          _merchantTxnId = 'LOAN${DateTime.now().millisecondsSinceEpoch}';
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
      backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF10B981),
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
            final label    = (op['label'] ?? '').toString().toLowerCase();
            final loanType = (op['loan_type'] ?? '').toString().toLowerCase();
            return label.contains(q) || loanType.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Container(
                width: 44, height: 5,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Select Loan Provider',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} providers available',
                        style: const TextStyle(fontSize: 12, color: textMuted)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: primaryPurple, size: 20),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by provider name or loan type…',
                    hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryPurple, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded, color: textMuted, size: 18),
                            onPressed: () { _searchCtrl.clear(); setModal(() {}); })
                        : null,
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: _opsLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading loan providers…', style: TextStyle(color: textMuted)),
                        ]),
                      )
                    : _opsError != null
                        ? Padding(
                            padding: const EdgeInsets.all(28),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ]),
                          )
                        : filtered.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No providers match your search', style: TextStyle(color: textMuted)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) {
                                  final op        = filtered[i];
                                  final label     = op['label']?.toString() ?? '';
                                  final loanType  = op['loan_type']?.toString() ?? '';
                                  final code      = op['code']?.toString() ?? '';
                                  final col       = _colorFor(code, loanType);
                                  final icon      = _iconFor(loanType);
                                  final isSel     = _selectedOp != null &&
                                      op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(icon, color: col, size: 20),
                                    ),
                                    title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDark)),
                                    subtitle: loanType.isNotEmpty
                                        ? Container(
                                            margin: const EdgeInsets.only(top: 3),
                                            child: Row(children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: col.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6)),
                                                child: Text(loanType, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w700)),
                                              ),
                                            ]),
                                          )
                                        : null,
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, color: primaryPurple, size: 22)
                                        : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                    onTap: () { setState(() => _selectedOp = op); Navigator.pop(ctx); },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLavender,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: _resultStatus != null ? _buildResult() : Column(children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 16),
                        _buildPillGrid(),
                        const SizedBox(height: 16),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildInstantCreditCard(),
                        const SizedBox(height: 20),
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                        _buildSecurityFooter(),
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

  // ─── Header Bar ──────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(
        onTap: () => Navigator.maybePop(ctx),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: primaryPurple, size: 20),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
          ),
          const SizedBox(width: 7),
          const Text('BBPS Assured', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          const Icon(Icons.settings_outlined, color: primaryPurple, size: 16),
        ]),
      ),
    ]),
  );

  // ─── Top Hero Banner ─────────────────────────────────────────────────────
  Widget _buildHeroBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEDE4FF), Color(0xFFDDD0FC), Color(0xFFEDEAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
      boxShadow: [
        BoxShadow(color: primaryDarkPurple.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
      ],
    ),
    child: Stack(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 6,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE5D5FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.credit_card_rounded, color: primaryPurple, size: 15),
                SizedBox(width: 5),
                Text('LOAN EMI', style: TextStyle(color: primaryPurple, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ]),
            ),
            const SizedBox(height: 14),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, height: 1.15, fontFamily: 'Roboto'),
                children: [
                  TextSpan(text: 'Pay Your\n', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 22)),
                  TextSpan(text: 'Loan EMI', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w900, fontSize: 28)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter your Loan Account Number\nand select your lender to proceed\nsecurely.',
              style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.9), height: 1.35, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: SizedBox(
              height: 140,
              child: Image.asset(
                'assets/laons.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/loans.png',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx2, err2, st2) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_rounded, size: 64, color: primaryPurple),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
          ),
          child: const Icon(Icons.account_balance_rounded, color: primaryPurple, size: 18),
        ),
      ),
    ]),
  );

  // ─── 4 Feature Pills Grid Card ───────────────────────────────────────────
  Widget _buildPillGrid() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Expanded(child: _pillItem(Icons.account_balance_wallet_outlined, 'Loan A/C No.', 'Account Details')),
      Container(width: 1, height: 38, color: const Color(0xFFF1F5F9)),
      Expanded(child: _pillItem(Icons.account_balance_outlined, 'Lenders', 'All Providers')),
      Container(width: 1, height: 38, color: const Color(0xFFF1F5F9)),
      Expanded(child: _pillItem(Icons.flash_on_outlined, 'Instant', 'Quick Pay')),
      Container(width: 1, height: 38, color: const Color(0xFFF1F5F9)),
      Expanded(child: _pillItem(Icons.security_outlined, 'Secured', '100% Safe')),
    ]),
  );

  Widget _pillItem(IconData icon, String title, String sub) => Column(children: [
    Container(
      width: 42, height: 42,
      decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
      child: Icon(icon, color: primaryPurple, size: 20),
    ),
    const SizedBox(height: 8),
    Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: textDark), textAlign: TextAlign.center, maxLines: 1),
    const SizedBox(height: 2),
    Text(sub, style: const TextStyle(fontSize: 10, color: textMuted), textAlign: TextAlign.center, maxLines: 1),
  ]);

  // ─── Input Form Card (Account No + Provider + Amount) ─────────────────────
  Widget _buildFormCard() {
    final selLabel    = _selectedOp?['label']?.toString();
    final selCode     = _selectedOp?['code']?.toString() ?? '';
    final selLoanType = _selectedOp?['loan_type']?.toString() ?? '';
    final selColor    = _selectedOp != null ? _colorFor(selCode, selLoanType) : primaryPurple;
    final selIcon     = _selectedOp != null ? _iconFor(selLoanType) : Icons.account_balance_outlined;

    return Column(children: [
      // 1. Loan Account Number Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_wallet_rounded, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Loan Account Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loanAccCtrl,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
              LengthLimitingTextInputFormatter(25),
            ],
            decoration: InputDecoration(
              hintText: 'Enter your Loan Account / Customer ID',
              hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 14, right: 10),
                alignment: Alignment.centerLeft,
                width: 20,
                child: const Text('#', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryPurple)),
              ),
              suffixIcon: _loanAccCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                      onPressed: () => setState(() => _loanAccCtrl.clear()),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Loan Account Number' : null,
          ),
        ]),
      ),

      const SizedBox(height: 14),

      // 2. Operators / Bank Selector Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_rounded, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 14),

          // Selector box
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: _opsLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2))
                      : Icon(selIcon, color: selColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _opsLoading ? 'Loading providers…' : selLabel ?? 'Select Loan Provider / Bank',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w500 : FontWeight.w700,
                      color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDark,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 22),
              ]),
            ),
          ),

          // Error banner if backend connection failed
          if (_opsError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFE11D48), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _opsError!,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFE11D48), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _fetchOperators,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, color: primaryPurple, size: 14),
                      SizedBox(width: 4),
                      Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryPurple)),
                    ]),
                  ),
                ),
              ]),
            ),
          ],

          // Dynamic EMI Amount input (shown when account no & operator selected)
          if (_canShowAmount) ...[
            const SizedBox(height: 18),
            const Row(children: [
              Icon(Icons.currency_rupee_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('EMI Amount (₹)', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                hintText: 'Enter EMI amount e.g. 5000',
                hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
                filled: true, fillColor: inputFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter EMI amount';
                if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [1000, 2500, 5000, 10000, 15000, 25000].map((amt) => InkWell(
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
        ]),
      ),
    ]);
  }

  // ─── Instant EMI Credit Card ─────────────────────────────────────────────
  Widget _buildInstantCreditCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
        child: const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Instant EMI Credit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 2),
          Text(
            'Once payment is successful, your EMI will be credited instantly.',
            style: TextStyle(fontSize: 11.5, color: textMuted.withValues(alpha: 0.85), height: 1.3),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: inputFill,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: primaryPurple, size: 18),
      ),
    ]),
  );

  // ─── Submit Button ("Fetch EMI & Proceed") ───────────────────────────────
  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: primaryPurple.withValues(alpha: 0.35),
      ),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [primaryPurple, accentBlue],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                  ),
                  Text(
                    _canShowAmount ? 'Pay Loan EMI' : 'Fetch EMI & Proceed',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                ]),
        ),
      ),
    ),
  );

  // ─── Security Footer Bar ────────────────────────────────────────────────
  Widget _buildSecurityFooter() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.verified_user_outlined, size: 14, color: textMuted),
      const SizedBox(width: 5),
      const Text('100% Secure Payments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('•', style: TextStyle(color: textMuted)),
      ),
      const Icon(Icons.lock_outline_rounded, size: 14, color: textMuted),
      const SizedBox(width: 5),
      const Text('Encrypted & Safe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('', style: TextStyle(color: textMuted)),
      ),
      
    ],
  );

  // ─── Result Screen ───────────────────────────────────────────────────────
  Widget _buildResult() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? const Color(0xFFF59E0B) : const Color(0xFFE11D48);
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'EMI Paid Successfully!' : isPen ? 'Payment Processing…' : 'Payment Failed';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: col.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: col, size: 48),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: col)),
          const SizedBox(height: 10),
          Text(
            _resultMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: textMuted, height: 1.5),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 6),
              Text(
                _merchantTxnId ?? '—',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryPurple, letterSpacing: 0.5),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _loanAccCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Pay Another EMI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}
