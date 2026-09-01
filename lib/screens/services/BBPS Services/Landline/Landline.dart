import 'dart:async';
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

typedef Landline = LandlineScreen;

class LandlineScreen extends StatefulWidget {
  const LandlineScreen({super.key});

  @override
  State<LandlineScreen> createState() => _LandlineScreenState();
}

class _LandlineScreenState extends State<LandlineScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color accentNavy = Color(0xFF0F172A);
  static const Color bgEnd = Color(0xFFF4FBF7);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE9D5FF);
  static const Color inputFill = Color(0xFFFBF7FF);

  final _formKey = GlobalKey<FormState>();
  final _landlineCtrl = TextEditingController();
  final _stdCodeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  int? _expandedIdx;

  // ─── Operators: pre-fetched on initState → INSTANT picker ────────────────
  List<Map<String, dynamic>> _operators = [];
  bool _opsLoading = true;
  String? _opsError;
  Map<String, dynamic>? _selectedOp;

  // ─── BBPS Fetch Bill State ────────────────────────────────────────────────
  BbpsBillDetails? _fetchedBill;
  bool _isFetchingBill = false;

  bool _submitting = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  // ─── Razorpay Service ───
  final RazorpayService _razorpayService = RazorpayService();

  bool get _canShowAmount =>
      _landlineCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('airtel')) return const Color(0xFFE11D48);
    if (k.contains('bsnl')) return const Color(0xFF0284C7);
    if (k.contains('mtnl')) return const Color(0xFF7C3AED);
    if (k.contains('tata')) return const Color(0xFF059669);
    return primaryPurple;
  }

  static IconData _iconFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('corporate') || k.contains('lease')) {
      return Icons.business_rounded;
    }
    return Icons.phone_in_talk_rounded;
  }

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _fetchOperators(); // ✅ Pre-fetch on screen open → INSTANT picker
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _landlineCtrl.dispose();
    _stdCodeCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  
  Future<void> _fetchOperators() async {
    if (mounted) {
      setState(() {
        _opsLoading = true;
        _opsError = null;
      });
    }
    try {
      final res = await ApiService.fetchApi('/landline/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null && (data['operators'] as List).isNotEmpty) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _operators = list;
            _opsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _opsError = data['message']?.toString() ?? 'Failed to load operators';
            _opsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _opsError = 'Failed to load operators';
          _opsLoading = false;
        });
      }
    }
  }

  Future<void> _onFetchBill() async {
    FocusScope.of(context).unfocus();
    final account = '${_stdCodeCtrl.text.trim()}${_landlineCtrl.text.trim()}';
    if (account.isEmpty) {
      _snack('Please enter your landline number', isError: true);
      return;
    }
    if (_selectedOp == null) {
      _snack('Please select an operator', isError: true);
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
          _snack('Bill fetched successfully! Amount: ₹${bill.dueAmount.toStringAsFixed(2)}');
        } else if (!bill.isSuccess) {
          _snack(bill.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingBill = false);
        _snack('Error fetching bill: $e', isError: true);
      }
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) {
      _snack('Please select a landline operator', isError: true);
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _snack('Please login', isError: true);
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Landline Bill – ${_selectedOp!['label'] ?? 'Payment'}',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitLandline(auth: auth, razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _snack('Payment failed: ${response.message ?? "Unknown error"}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitLandline({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() {
      _submitting = true;
      _resultStatus = null;
    });
    try {
      final res = await ApiService.postApi('/landline/pay', {
        'user_id':             auth.userId,
        'landline_number':     _landlineCtrl.text.trim(),
        'std_code':            _stdCodeCtrl.text.trim(),
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
          _submitting = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage =
              (data['message']?.toString() ??
              (_resultStatus == 'success'
                  ? 'Landline bill paid!'
                  : 'Payment failed')).replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim();
          _merchantTxnId =
              data['merchant_txn_id']?.toString() ??
              'LL${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'pending';
          _resultMessage = "Couldn't confirm payment. Check history.";
          _merchantTxnId = 'LL${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade700
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openPicker() {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final q = _searchCtrl.text.toLowerCase();
          final filtered = _operators.where((op) {
            final label = (op['label'] ?? op['name'] ?? '')
                .toString()
                .toLowerCase();
            return label.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Landline Operator',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                              ),
                            ),
                            Text(
                              _opsLoading
                                  ? 'Loading…'
                                  : '${_operators.length} operators available',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: primaryPurple,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setModal(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search operator name…',
                      hintStyle: const TextStyle(
                        color: textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryPurple,
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: textMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setModal(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Flexible(
                  child: _opsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: primaryPurple,
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Loading operators…',
                                style: TextStyle(color: textMuted),
                              ),
                            ],
                          ),
                        )
                      : _opsError != null
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _opsError!,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _fetchOperators();
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No operators match your search',
                            style: TextStyle(color: textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (_, i) {
                            final op = filtered[i];
                            final label = op['label']?.toString() ?? '';
                            final code = op['code']?.toString() ?? '';
                            final col = _colorFor(code, label);
                            final icon = _iconFor(code, label);
                            final isSel =
                                _selectedOp != null &&
                                op['spkey']?.toString() ==
                                    _selectedOp!['spkey']?.toString();
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: isSel
                                  ? col.withValues(alpha: 0.07)
                                  : null,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: col, size: 20),
                              ),
                              title: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSel
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              trailing: isSel
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryPurple,
                                      size: 22,
                                    )
                                  : const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF94A3B8),
                                    ),
                              onTap: () {
                                setState(() => _selectedOp = op);
                                Navigator.pop(ctx);
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
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E8FF), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: _resultStatus != null
              ? _buildResult()
              : _buildFormBody(isDesktop, screenSize),
        ),
      ),
    );
  }

  Widget _buildFormBody(bool isDesktop, Size screenSize) {
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 920) / 2
        : (screenSize.width > 700 ? 24.0 : 12.0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E1B4B),
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                _buildHero(),
                const SizedBox(height: 24),
                _buildPills(),
                const SizedBox(height: 24),
                Form(key: _formKey, child: _buildFormCard()),
                if (_canShowAmount) ...[
                  const SizedBox(height: 24),
                  _buildSubmitBtn(),
                ],
                const SizedBox(height: 24),
                _buildAssurance(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(ctx),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textDark,
              size: 18,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: primaryPurple, size: 18),
              SizedBox(width: 6),
              Text(
                'BBPS Assured',
                style: TextStyle(
                  color: primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildHero() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Landline ',
                    style: const TextStyle(
                      color: primaryPurple,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const TextSpan(
                    text: 'Payment',
                    style: TextStyle(
                      color: Color(0xFF1E1B4B),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your details below to fetch and pay your bill securely via BBPS.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 3,
        child: Align(
          alignment: Alignment.centerRight,
          child: Image.asset(
            'assets/Landlines.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ],
  );

  Widget _buildPills() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _pill(Icons.phone_in_talk_rounded, 'Phone No.'),
        _pill(Icons.cell_tower_rounded, 'Operators'),
        _pill(Icons.bolt_rounded, 'Instant'),
        _pill(Icons.security_rounded, 'Secured'),
      ],
    ),
  );

  Widget _pill(IconData icon, String label) => Column(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryPurple.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryPurple, size: 20),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
      ),
    ],
  );

  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selCode = _selectedOp?['code']?.toString() ?? '';
    final selColor = _selectedOp != null
        ? _colorFor(selCode, selLabel!)
        : const Color(0xFF94A3B8);
    final selIcon = _selectedOp != null
        ? _iconFor(selCode, selLabel!)
        : Icons.business_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Landline Phone Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.phone_in_talk_outlined,
                    size: 16,
                    color: primaryPurple,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Landline Number',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _landlineCtrl,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter Landline Phone Number with STD',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: primaryPurple,
                    size: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryPurple,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter Landline Number'
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Operators
          const Row(
            children: [
              Icon(Icons.cell_tower_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                'Operators',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: _opsLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(selIcon, color: selColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _opsLoading
                          ? 'Loading operators…'
                          : selLabel ?? 'Select Landline Operator',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (selLabel == null || _opsLoading)
                            ? FontWeight.w400
                            : FontWeight.w700,
                        color: (selLabel == null || _opsLoading)
                            ? const Color(0xFF94A3B8)
                            : textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _opsError != null ? 'Retry' : 'Choose',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_opsError != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _fetchOperators,
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _opsError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── BBPS Get Bill / Fetch Bill Button & Card ───
          if (_landlineCtrl.text.trim().isNotEmpty && _selectedOp != null) ...[
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
            const Row(
              children: [
                Icon(
                  Icons.currency_rupee_rounded,
                  size: 18,
                  color: primaryPurple,
                ),
                SizedBox(width: 8),
                Text(
                  'Bill Amount (₹)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter bill amount e.g. 499',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: primaryPurple,
                  size: 20,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: primaryPurple,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter bill amount';
                if (double.tryParse(v.trim()) == null ||
                    double.parse(v.trim()) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [299, 499, 799, 999, 1499]
                  .map(
                    (amt) => InkWell(
                      onTap: () =>
                          setState(() => _amountCtrl.text = amt.toString()),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryPurple.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '₹$amt',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBtn() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        shadowColor: primaryPurple.withValues(alpha: 0.35),
      ),
      onPressed: _submitting ? null : _handleProceed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _submitting
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [primaryPurple, primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Fetch Bill & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _buildResult() {
    final isOk = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col = isOk
        ? const Color(0xFF10B981)
        : isPen
        ? const Color(0xFFF59E0B)
        : Colors.redAccent;
    final icon = isOk
        ? Icons.check_circle_rounded
        : isPen
        ? Icons.hourglass_top_rounded
        : Icons.cancel_rounded;
    final title = isOk
        ? 'Landline Bill Paid!'
        : isPen
        ? 'Processing…'
        : 'Payment Failed';
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? (_fetchedBill?.dueAmount ?? 0.0);

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'Landline Bill',
      operatorName: _selectedOp?['label']?.toString() ?? 'Landline Operator',
      accountNumber: _landlineCtrl.text.trim(),
      customerName: _fetchedBill?.customerName ?? '',
      merchantTxnId: _merchantTxnId ?? 'LL${now.millisecondsSinceEpoch}',
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: col, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: col,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Transaction Reference ID',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _merchantTxnId ?? '—',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => setState(() {
                  _resultStatus = null;
                  _resultMessage = null;
                  _merchantTxnId = null;
                  _landlineCtrl.clear();
                  _stdCodeCtrl.clear();
                  _amountCtrl.clear();
                  _selectedOp = null;
                }),
                style: TextButton.styleFrom(
                  foregroundColor: textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Pay Another Bill',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssurance() => Container(
    decoration: BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        _tile(
          0,
          Icons.bolt_rounded,
          const Color(0xFFF59E0B),
          'Instant Settlement',
          'Direct settlement with landline provider',
          '⚡ Real-time landline bill payment credited directly to account.',
        ),
        const Divider(
          height: 1,
          indent: 64,
          endIndent: 20,
          color: Color(0xFFF1F5F9),
        ),
        _tile(
          1,
          Icons.shield_rounded,
          const Color(0xFF10B981),
          '100% BBPS Secure',
          'Encrypted via BBPS network',
          '🛡️ 256-bit SSL encrypted payment authorized by NPCI.',
        ),
        const Divider(
          height: 1,
          indent: 64,
          endIndent: 20,
          color: Color(0xFFF1F5F9),
        ),
        _tile(
          2,
          Icons.receipt_long_rounded,
          primaryPurple,
          'Instant Receipt',
          'Official landline payment receipt',
          '🧾 Download official BBPS receipt after bill payment.',
        ),
      ],
    ),
  );

  Widget _tile(
    int idx,
    IconData icon,
    Color color,
    String title,
    String sub,
    String detail,
  ) {
    final isExp = _expandedIdx == idx;
    return InkWell(
      onTap: () => setState(() => _expandedIdx = isExp ? null : idx),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      Text(
                        sub,
                        style: const TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExp
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: primaryPurple,
                  size: 22,
                ),
              ],
            ),
            if (isExp) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryPurple.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryDark,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



