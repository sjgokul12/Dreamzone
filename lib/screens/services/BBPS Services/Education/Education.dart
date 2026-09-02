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

typedef Education = EducationScreen;

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});
  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen>
    with TickerProviderStateMixin {

  // ─── Purple / Lavender Theme (matches reference design) ───────────────────
  static const Color primaryPurple     = Color(0xFF6C63FF);
  static const Color primaryPurpleDark = Color(0xFF4834DF);
  static const Color primaryPurpleDeep = Color(0xFF5B4BD6);
  static const Color accentNavy        = Color(0xFF1E1B3A);
  static const Color accentOrange      = Color(0xFFF59E0B);
  static const Color accentRed         = Color(0xFFD63031);
  static const Color errorBg           = Color(0xFFFFEDED);
  static const Color bgGradientStart   = Color(0xFFF8F7FF);
  static const Color bgGradientEnd     = Color(0xFFFAFAFF);
  static const Color cardWhite         = Colors.white;
  static const Color textDark          = Color(0xFF1E1B3A);
  static const Color textMuted         = Color(0xFF6B7280);
  static const Color borderColor       = Color(0xFFE4DFFB);
  static const Color inputFill         = Color(0xFFF6F4FF);
  static const Color chipLavender      = Color(0xFFEDE9FE);

  final _formKey        = GlobalKey<FormState>();
  final _studentIdCtrl  = TextEditingController();
  final _amountCtrl     = TextEditingController();
  final _searchCtrl     = TextEditingController();
  int?  _expandedIdx;

  // ─── Operators: pre-fetched on initState → INSTANT picker ────────────────
  List<Map<String, dynamic>> _operators   = [];
  bool                        _opsLoading = true;
  String?                     _opsError;
  Map<String, dynamic>?       _selectedOp;

  // ─── BBPS Fetch Bill State ────────────────────────────────────────────────
  BbpsBillDetails? _fetchedBill;
  bool _isFetchingBill = false;

  bool    _submitting    = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  // ─── Razorpay Service ───
  final RazorpayService _razorpayService = RazorpayService();

  String get _base => ApiService.baseUrl;
  bool get _canShowAmount =>
      _studentIdCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('mount') || k.contains('olivet')) return const Color(0xFF6C63FF);
    if (k.contains('guru') || k.contains('khalsa') || k.contains('sikh')) return const Color(0xFF8B7CF6);
    if (k.contains('dps') || k.contains('public')) return const Color(0xFF7C6FF0);
    if (k.contains('amity')) return const Color(0xFF5B4BD6);
    if (k.contains('vit')) return const Color(0xFF6C63FF);
    if (k.contains('lpu')) return const Color(0xFF9C8CFB);
    if (k.contains('dav')) return const Color(0xFF8B7CF6);
    if (k.contains('iit') || k.contains('nit')) return const Color(0xFF4834DF);
    if (k.contains('university') || k.contains('univ')) return const Color(0xFF7C6FF0);
    return primaryPurple;
  }

  static IconData _iconFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('school') || k.contains('sec.')) return Icons.school_rounded;
    if (k.contains('college') || k.contains('khalsa')) return Icons.account_balance_rounded;
    if (k.contains('university') || k.contains('univ')) return Icons.local_library_rounded;
    if (k.contains('dps') || k.contains('public')) return Icons.menu_book_rounded;
    return Icons.cast_for_education_rounded;
  }

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _fetchOperators(); // ✅ Pre-fetch → picker opens instantly
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose(); _amountCtrl.dispose(); _searchCtrl.dispose(); _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/education/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
          _opsError = data['message']?.toString() ?? 'Failed to load institutions';
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

  Future<void> _onFetchBill() async {
    FocusScope.of(context).unfocus();
    final account = _studentIdCtrl.text.trim();
    if (account.isEmpty) {
      _snack('Please enter your Student ID', isError: true);
      return;
    }
    if (_selectedOp == null) {
      _snack('Please select an institution', isError: true);
      return;
    }

    setState(() => _isFetchingBill = true);
    try {
      final bill = await BbpsApiService.fetchBill(
        spKey: _selectedOp!['spkey']?.toString() ?? '',
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
          _snack('Fee bill fetched successfully! Amount: ₹${bill.dueAmount.toStringAsFixed(2)}');
        } else if (!bill.isSuccess) {
          _snack(bill.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingBill = false);
        _snack('Error fetching fee bill: $e', isError: true);
      }
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) { _snack('Please select an institution', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Education Fee – ${_selectedOp!['label'] ?? 'Payment'}',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitEducation(auth: auth, razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _snack('Payment failed: ${response.message ?? "Unknown error"}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitEducation({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await ApiService.postApi('/education/pay', {
        'user_id':             auth.userId,
        'student_id':          _studentIdCtrl.text.trim(),
        'operator_id':         _selectedOp!['spkey']?.toString() ?? '',
        'operator_name':       _selectedOp!['label']?.toString() ?? '',
        'amount':              _amountCtrl.text.trim(),
        'fetch_bill_id':       _fetchedBill?.fetchBillId ?? '',
        'ref_id':              _fetchedBill?.refId ?? '',
        'customer_name':       _fetchedBill?.customerName ?? '',
        'bill_number':         _fetchedBill?.billNumber ?? '',
        'due_date':            _fetchedBill?.dueDate ?? '',
        'razorpay_payment_id': razorpayPaymentId,
        'payment_status':      'paid',
      });
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage = (data['message']?.toString() ?? (_resultStatus == 'success' ? 'Fee paid!' : 'Payment failed')).replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim();
          _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'EDU${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false; _resultStatus = 'pending';
          _resultMessage = "Couldn't confirm payment. Check history.";
          _merchantTxnId = 'EDU${DateTime.now().millisecondsSinceEpoch}';
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
      backgroundColor: isError ? accentRed : const Color(0xFF10B981),
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
            final label   = (op['label'] ?? '').toString().toLowerCase();
            final city    = (op['city'] ?? '').toString().toLowerCase();
            final eduType = (op['edu_type'] ?? '').toString().toLowerCase();
            return label.contains(q) || city.contains(q) || eduType.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.80),
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
                    const Text('Select Institution',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} institutions',
                        style: const TextStyle(fontSize: 12, color: textMuted)),
                  ])),
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: chipLavender, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: primaryPurple, size: 20)),
                ]),
              ),
              if (_operators.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _searchCtrl, onChanged: (_) => setModal(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search institution or city…',
                      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryPurple, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, color: textMuted, size: 18),
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
                          CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading institutions…', style: TextStyle(color: textMuted)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ]))
                        : filtered.isEmpty
                            ? const Padding(padding: EdgeInsets.all(32),
                                child: Text('No institutions match your search', style: TextStyle(color: textMuted)))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) {
                                  final op      = filtered[i];
                                  final label   = op['label']?.toString() ?? '';
                                  final city    = op['city']?.toString() ?? '';
                                  final type    = op['edu_type']?.toString() ?? '';
                                  final code    = op['code']?.toString() ?? '';
                                  final col     = _colorFor(code, label);
                                  final icon    = _iconFor(code, label);
                                  final isSel   = _selectedOp != null &&
                                      op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                                    leading: Container(padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                        child: Icon(icon, color: col, size: 22)),
                                    title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDark)),
                                    subtitle: Row(children: [
                                      if (type.isNotEmpty) ...[
                                        Container(margin: const EdgeInsets.only(top: 3),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: col.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6)),
                                          child: Text(type, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w700))),
                                        const SizedBox(width: 6),
                                      ],
                                      if (city.isNotEmpty)
                                        Text(city, style: const TextStyle(fontSize: 11, color: textMuted)),
                                    ]),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, color: primaryPurple, size: 22)
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
      backgroundColor: bgGradientEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: _resultStatus != null ? _buildResult() : Column(children: [
                  _buildAppBar(context),
                  Expanded(child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Form(key: _formKey, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildHero(),
                      const SizedBox(height: 18),
                      _buildPills(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                      if (_opsError != null) ...[
                        const SizedBox(height: 14),
                        _buildErrorBanner(),
                      ],
                      if (_canShowAmount) ...[
                        const SizedBox(height: 24),
                        _buildSubmitBtn(),
                      ],
                      const SizedBox(height: 20),
                      _buildAssurance(),
                      const SizedBox(height: 16),
                      _buildSecurityFooter(),
                      const SizedBox(height: 24),
                    ])),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(onTap: () => Navigator.maybePop(ctx), borderRadius: BorderRadius.circular(16),
        child: Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryPurple, size: 18))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF3B82F6), size: 16),
          ),
          const SizedBox(width: 6),
          const Text('BBPS Assured', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
          ),
        ])),
    ]),
  );

  Widget _buildHero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF8B7CF6), primaryPurple, primaryPurpleDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.school_rounded, color: primaryPurple, size: 16),
                SizedBox(width: 5),
                Text('EDUCATION', style: TextStyle(color: primaryPurple, fontSize: 10.5,
                    fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ])),
            const SizedBox(height: 16),
            RichText(text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.15, fontFamily: 'Roboto'),
              children: [
                TextSpan(text: 'Pay Your\n', style: TextStyle(color: textDark)),
                TextSpan(text: 'Education Fees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ])),
            const SizedBox(height: 10),
            Text('Enter your Student ID / Enrollment Number to fetch and pay fees securely.',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.92), height: 1.45)),
          ]),
        ),
        const SizedBox(width: 8),
        _buildHeroIllustration(),
      ],
    ),
  );

  Widget _buildHeroIllustration() {
    return SizedBox(
      width: 110,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: 4, top: 8,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.5), size: 14)),
          Positioned(right: 28, top: 0,
            child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.4), size: 10)),
          Positioned(left: 8, bottom: 0,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.95), chipLavender],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.currency_rupee_rounded, color: primaryPurple, size: 28),
            )),
          Positioned(right: 0, bottom: 18,
            child: Container(
              width: 56, height: 44,
              decoration: BoxDecoration(
                color: primaryPurpleDeep,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
            )),
          Positioned(right: 12, bottom: 52,
            child: Container(
              width: 64, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF9C8CFB),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 20),
            )),
          Positioned(right: 18, top: 18,
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryPurpleDeep,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPills() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: accentNavy.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Row(children: [
      Expanded(child: _pill(Icons.badge_rounded, 'Student ID', 'Quick Fetch')),
      _pillDivider(),
      Expanded(child: _pill(Icons.school_rounded, 'Institutions', 'All Schools')),
      _pillDivider(),
      Expanded(child: _pill(Icons.bolt_rounded, 'Instant', 'Quick Pay')),
      _pillDivider(),
      Expanded(child: _pill(Icons.shield_rounded, 'Secured', '100% Safe')),
    ]),
  );

  Widget _pillDivider() => Container(width: 1, height: 42, color: const Color(0xFFEEF0F5));

  Widget _pill(IconData icon, String label, String sub) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 44, height: 44,
        decoration: BoxDecoration(color: chipLavender, shape: BoxShape.circle),
        child: Icon(icon, color: primaryPurple, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textDark),
        textAlign: TextAlign.center),
    Text(sub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: textMuted),
        textAlign: TextAlign.center),
  ]);

  Widget _buildFormCard() {
    final selLabel   = _selectedOp?['label']?.toString();
    final selCode    = _selectedOp?['code']?.toString() ?? '';
    final selColor   = _selectedOp != null ? _colorFor(selCode, selLabel!) : const Color(0xFF94A3B8);
    final selIcon    = _selectedOp != null ? _iconFor(selCode, selLabel!) : Icons.school_outlined;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: accentNavy.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.badge_outlined, size: 16, color: primaryPurple),
          ),
          const SizedBox(width: 10),
          const Text('Student ID / Enrollment No.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _studentIdCtrl,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')), LengthLimitingTextInputFormatter(20)],
          decoration: InputDecoration(
            hintText: 'Enter Student ID / Roll No.',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true, fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.tag_rounded, color: primaryPurple, size: 20),
            suffixIcon: _studentIdCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _studentIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Student ID' : null,
        ),

        const SizedBox(height: 22),

        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.school_rounded, size: 16, color: primaryPurple),
          ),
          const SizedBox(width: 10),
          const Text('Operators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2))
                    : Icon(selIcon, color: selColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _opsLoading ? 'Loading institutions…' : selLabel ?? 'Select Institution',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14,
                    fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w400 : FontWeight.w700,
                    color: (selLabel == null || _opsLoading) ? const Color(0xFF9CA3AF) : textDark))),
              Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple.withValues(alpha: 0.7), size: 24),
            ]),
          ),
        ),

        // ─── BBPS Get Bill / Fetch Bill Button & Card ───
        if (_studentIdCtrl.text.trim().isNotEmpty && _selectedOp != null) ...[
          const SizedBox(height: 16),
          BbpsFetchedBillCard(
            bill: _fetchedBill,
            isFetching: _isFetchingBill,
            primaryColor: primaryPurple,
            onFetchBill: _onFetchBill,
          ),
        ],

        if (_canShowAmount) ...[
          const SizedBox(height: 22),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.currency_rupee_rounded, size: 16, color: primaryPurple),
            ),
            const SizedBox(width: 10),
            const Text('Fee Amount (₹)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter fee amount e.g. 5000',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              filled: true, fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentRed, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter fee amount';
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
                decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryPurple.withValues(alpha: 0.2))),
                child: Text('₹$amt', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryPurple))),
            )).toList()),
        ],
      ]),
    );
  }

  Widget _buildErrorBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: errorBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accentRed.withValues(alpha: 0.15)),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: accentRed, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(
        _opsError ?? 'Failed to connect. Please check your connection and retry.',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentRed, height: 1.35),
      )),
      const SizedBox(width: 8),
      InkWell(
        onTap: _fetchOperators,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded, color: primaryPurple, size: 16),
            SizedBox(width: 4),
            Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryPurple)),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildSubmitBtn() => SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 6, shadowColor: primaryPurple.withValues(alpha: 0.35)),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting ? [Colors.grey.shade400, Colors.grey.shade500] : [primaryPurple, primaryPurpleDark],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18)),
        child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _submitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Pay Education Fee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ])),
      ),
    ),
  );

  Widget _buildResult() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? accentOrange : accentRed;
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'Education Fee Paid!' : isPen ? 'Processing…' : 'Payment Failed';
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? (_fetchedBill?.dueAmount ?? 0.0);

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'Education Fees',
      operatorName: _selectedOp?['label']?.toString() ?? 'Educational Institute',
      accountNumber: _studentIdCtrl.text.trim(),
      customerName: _fetchedBill?.customerName ?? '',
      merchantTxnId: _merchantTxnId ?? 'EDU${now.millisecondsSinceEpoch}',
      dateTimeStr: dtStr,
      amount: paidAmt,
      status: isOk ? 'Success' : (isPen ? 'Pending' : 'Failed'),
      billNumber: _fetchedBill?.billNumber,
      dueDate: _fetchedBill?.dueDate,
      billPeriod: _fetchedBill?.billPeriod,
    );

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
          Text((_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(), textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5)),
          const SizedBox(height: 22),
          Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2))),
            child: Column(children: [
              const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryPurple, letterSpacing: 0.5)),
            ])),
          const SizedBox(height: 20),

          // ── Auto-Sent Email & WhatsApp Confirmation ──
          if (isOk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bill receipt has been automatically sent to your registered email & WhatsApp (+91 9880885551)',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ── Download / View Bill Receipt & Share Buttons ──
          if (isOk) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                label: const Text('View & Download Bill Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BbpsInvoicePdfService.shareToWhatsApp(receipt),
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BbpsInvoicePdfService.shareViaEmail(receipt),
                    icon: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
                    label: const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity, height: 48,
            child: TextButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _studentIdCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: TextButton.styleFrom(
                foregroundColor: textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Pay Another Fee', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ])));
  }

  Widget _buildAssurance() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [BoxShadow(color: accentNavy.withValues(alpha: 0.03), blurRadius: 18, offset: const Offset(0, 6))]),
    child: InkWell(
      onTap: () => setState(() => _expandedIdx = _expandedIdx == 0 ? null : 0),
      borderRadius: BorderRadius.circular(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: accentOrange, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Instant Processing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
            SizedBox(height: 3),
            Text('Your payment will be processed instantly and receipt will be sent to you.',
                style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.35)),
          ])),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: chipLavender, shape: BoxShape.circle),
            child: Icon(
              _expandedIdx == 0 ? Icons.keyboard_arrow_up_rounded : Icons.arrow_forward_rounded,
              color: primaryPurple, size: 18,
            ),
          ),
        ]),
        if (_expandedIdx == 0) ...[
          const SizedBox(height: 12),
          _tile(1, Icons.shield_rounded, const Color(0xFF10B981), '100% BBPS Secure', 'Encrypted via BBPS network', '🛡️ 256-bit SSL encrypted payment authorized by NPCI.'),
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
          _tile(2, Icons.receipt_long_rounded, primaryPurple, 'Instant Receipt', 'Official fee payment proof', '🧾 Download official BBPS receipt after payment.'),
        ],
      ]),
    ),
  );

  Widget _buildSecurityFooter() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _footerBadge(Icons.shield_rounded, '100% Secure\nPayments'),
      _footerBadge(Icons.lock_rounded, 'Encrypted\n& Safe'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipLavender,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: const Column(children: [
          Text('BBPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: primaryPurple, letterSpacing: 0.5)),
          Text('Bharat BillPay', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: textMuted)),
        ]),
      ),
    ],
  );

  Widget _footerBadge(IconData icon, String label) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: primaryPurple, size: 18),
    const SizedBox(height: 4),
    Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted, height: 1.2)),
  ]);

  Widget _tile(int idx, IconData icon, Color color, String title, String sub, String detail) {
    final isExp = _expandedIdx == idx;
    return InkWell(onTap: () => setState(() => _expandedIdx = isExp ? null : idx),
      borderRadius: BorderRadius.circular(28),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
            Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 22),
          ]),
          if (isExp) ...[
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: chipLavender.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.15))),
              child: Text(detail, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryPurpleDeep, height: 1.35))),
          ],
        ])));
  }
}



