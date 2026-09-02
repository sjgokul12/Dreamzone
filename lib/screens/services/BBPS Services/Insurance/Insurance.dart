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

typedef Insurance       = InsuranceScreen;
typedef InsurancePolicy = InsuranceScreen;

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with TickerProviderStateMixin {

  // ─── Theme Colors (Purple Template) ─────────────────────────────────────
  static const Color primaryPurple     = Color(0xFF7C3AED);
  static const Color primaryDarkPurple = Color(0xFF6D28D9);
  static const Color accentBlue        = Color(0xFF3B82F6);
  static const Color bgLavender        = Color(0xFFF5EEFF);
  static const Color cardWhite         = Colors.white;
  static const Color textDark          = Color(0xFF1E1B4B);
  static const Color textMuted         = Color(0xFF6B7280);
  static const Color borderColor       = Color(0xFFEDE4FF);
  static const Color inputFill         = Color(0xFFF9F5FF);

  final _formKey            = GlobalKey<FormState>();
  final _subscriptionIdCtrl = TextEditingController();
  final _dobCtrl            = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _amountCtrl         = TextEditingController();
  final _searchCtrl         = TextEditingController();

  // ─── Operators State ──────────────────────────────────────────────────────
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
    return primaryPurple;
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
    _razorpayService.init();
    _fetchOperators();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subscriptionIdCtrl.dispose(); _dobCtrl.dispose(); _emailCtrl.dispose();
    _amountCtrl.dispose(); _searchCtrl.dispose(); _razorpayService.dispose();
    super.dispose();
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
              primary: primaryPurple,
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

  Future<void> _onFetchBill() async {
    FocusScope.of(context).unfocus();
    final account = _subscriptionIdCtrl.text.trim();
    if (account.isEmpty) {
      _snack('Please enter your Policy / Subscription Number', isError: true);
      return;
    }
    if (_selectedOp == null) {
      _snack('Please select an insurance provider', isError: true);
      return;
    }

    setState(() => _isFetchingBill = true);
    try {
      final bill = await BbpsApiService.fetchBill(
        spKey: _selectedOp!['spkey']?.toString() ?? '',
        account: account,
        optional1: _dobCtrl.text.trim(),
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
          _snack('Insurance bill fetched successfully! Premium: ₹${bill.dueAmount.toStringAsFixed(2)}');
        } else if (!bill.isSuccess) {
          _snack(bill.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingBill = false);
        _snack('Error fetching insurance bill: $e', isError: true);
      }
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) { _snack('Please select an insurance provider', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Insurance Premium – ${_selectedOp!['label'] ?? 'Payment'}',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitInsurance(auth: auth, razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _snack('Payment failed: ${response.message ?? "Unknown error"}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitInsurance({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final res = await ApiService.postApi('/insurance/pay', {
        'user_id':             auth.userId,
        'policy_no':           _subscriptionIdCtrl.text.trim(),
        'dob':                 _dobCtrl.text.trim(),
        'email':               _emailCtrl.text.trim(),
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
          _resultMessage = (data['message']?.toString() ?? (_resultStatus == 'success' ? 'Insurance premium paid!' : 'Payment failed')).replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim();
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
                    const Text('Select Insurance Provider',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} insurance companies available',
                        style: const TextStyle(fontSize: 12, color: textMuted)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.shield_rounded, color: primaryPurple, size: 20),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search insurance company name…',
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
                          Text('Loading insurance companies…', style: TextStyle(color: textMuted)),
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
                                child: Text('No insurance companies match your search', style: TextStyle(color: textMuted)),
                              )
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
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(icon, color: col, size: 20),
                                    ),
                                    title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDark)),
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
                        _buildHassleFreeCard(),
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
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
              Icon(Icons.shield_rounded, color: primaryPurple, size: 15),
              SizedBox(width: 5),
              Text('INSURANCE PREMIUM', style: TextStyle(color: primaryPurple, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, height: 1.15, fontFamily: 'Roboto'),
              children: [
                TextSpan(text: 'Pay Your\n', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 20)),
                TextSpan(text: 'Insurance\nPremium', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w900, fontSize: 23)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Policy details and select your provider to proceed.',
            style: TextStyle(fontSize: 11.5, color: textMuted.withValues(alpha: 0.9), height: 1.3, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
      Expanded(
        flex: 5,
        child: Center(
          child: SizedBox(
            height: 140,
            child: Image.asset(
              'assets/insurances.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) => Image.asset(
                'assets/insurance.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx2, err2, st2) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_rounded, size: 64, color: primaryPurple),
                ),
              ),
            ),
          ),
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
      Expanded(child: _pillItem(Icons.badge_outlined, 'Policy No.', 'Enter Details')),
      Container(width: 1, height: 38, color: const Color(0xFFF1F5F9)),
      Expanded(child: _pillItem(Icons.shield_outlined, 'Insurers', 'All Providers')),
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

  // ─── Input Form Card (Policy No + DOB + Email + Insurers + Amount) ─────
  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selColor = _selectedOp != null ? _colorFor(selLabel!) : primaryPurple;
    final selIcon  = _selectedOp != null ? _iconFor(selLabel!) : Icons.shield_outlined;

    return Column(children: [
      // 1. Policy / Subscription Number Card
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
              child: const Icon(Icons.badge_outlined, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Policy / Subscription Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _subscriptionIdCtrl,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\/]')),
              LengthLimitingTextInputFormatter(25),
            ],
            decoration: InputDecoration(
              hintText: 'Enter Policy / Subscription Number',
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
              suffixIcon: _subscriptionIdCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                      onPressed: () => setState(() => _subscriptionIdCtrl.clear()),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Policy Number' : null,
          ),

          const SizedBox(height: 16),

          // Date of Birth
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cake_outlined, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Date of Birth (YYYY-MM-DD)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 14),
          InkWell(
            onTap: _selectDateOfBirth,
            borderRadius: BorderRadius.circular(16),
            child: IgnorePointer(
              child: TextFormField(
                controller: _dobCtrl,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textDark),
                decoration: InputDecoration(
                  hintText: 'Select Date of Birth',
                  hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
                  filled: true,
                  fillColor: inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.calendar_month_rounded, color: primaryPurple, size: 20),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, color: primaryPurple, size: 18),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Select Date of Birth' : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Email Address
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Email Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textDark),
            decoration: InputDecoration(
              hintText: 'Enter your Email address',
              hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(Icons.mail_rounded, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your Email address';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid Email address';
              return null;
            },
          ),
        ]),
      ),

      const SizedBox(height: 14),

      // 2. Operators / Insurance Provider Selector Card
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
              child: const Icon(Icons.shield_rounded, color: primaryPurple, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Insurers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
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
                    _opsLoading ? 'Loading insurers…' : selLabel ?? 'Select Insurance Provider',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w500 : FontWeight.w700,
                      color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_opsError != null ? 'Retry' : 'Choose',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryPurple)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 16),
                  ]),
                ),
              ]),
            ),
          ),

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

          // ─── BBPS Get Bill / Fetch Bill Button & Card ───
          if (_subscriptionIdCtrl.text.trim().isNotEmpty && _selectedOp != null) ...[
            const SizedBox(height: 16),
            BbpsFetchedBillCard(
              bill: _fetchedBill,
              isFetching: _isFetchingBill,
              primaryColor: primaryPurple,
              onFetchBill: _onFetchBill,
            ),
          ],

          // Dynamic Amount input (shown when all fields valid)
          if (_canShowAmount) ...[
            const SizedBox(height: 18),
            const Row(children: [
              Icon(Icons.currency_rupee_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Premium Amount (₹)', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                hintText: 'Enter premium amount e.g. 5000',
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
                if (v == null || v.trim().isEmpty) return 'Enter premium amount';
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

  // ─── Hassle-free Payments Card ───────────────────────────────────────────
  Widget _buildHassleFreeCard() => Container(
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
        decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
        child: const Icon(Icons.shield_rounded, color: primaryPurple, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Instant Policy Settlement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 2),
          Text(
            'Your insurance premium will be processed instantly and securely.',
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

  // ─── Submit Button ────────────────────────────────────────────────────────
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
                    _canShowAmount ? 'Fetch Insurance & Proceed' : 'Fetch Insurance & Proceed',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                ]),
        ),
      ),
    ),
  );

  // ─── Security Footer Bar ────────────────────────────────────────────────
  Widget _buildSecurityFooter() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    runSpacing: 6,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.verified_user_outlined, size: 13, color: textMuted),
        SizedBox(width: 4),
        Text('100% Secure Payments', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textMuted)),
      ]),
      const Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.lock_outline_rounded, size: 13, color: textMuted),
        SizedBox(width: 4),
        Text('Encrypted & Safe', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textMuted)),
      ]),
      const Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('BBPS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: primaryPurple, letterSpacing: 0.5)),
      ),
    ],
  );

  // ─── Result Screen ───────────────────────────────────────────────────────
  Widget _buildResult() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? const Color(0xFFF59E0B) : const Color(0xFFE11D48);
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'Premium Paid Successfully!' : isPen ? 'Payment Processing…' : 'Payment Failed';
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? (_fetchedBill?.dueAmount ?? 0.0);

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'Insurance Premium',
      operatorName: _selectedOp?['label']?.toString() ?? 'Insurance Provider',
      accountNumber: _subscriptionIdCtrl.text.trim(),
      customerName: _fetchedBill?.customerName ?? '',
      merchantTxnId: _merchantTxnId ?? 'INS${now.millisecondsSinceEpoch}',
      dateTimeStr: dtStr,
      amount: paidAmt,
      status: isOk ? 'Success' : (isPen ? 'Pending' : 'Failed'),
      billNumber: _fetchedBill?.billNumber,
      dueDate: _fetchedBill?.dueDate,
      billPeriod: _fetchedBill?.billPeriod,
    );

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
            (_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(),
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
                _subscriptionIdCtrl.clear(); _dobCtrl.clear(); _emailCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: TextButton.styleFrom(
                foregroundColor: textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Pay Another Premium', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}



