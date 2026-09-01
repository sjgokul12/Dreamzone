import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../core/payment/razorpay_service.dart';
import '../../../../services/metro_api_service.dart';
import '../../../../services/bbps_invoice_pdf_service.dart';
import '../bbps_receipt_screen.dart';

typedef MetroCard = MetroCardScreen;
typedef Metro     = MetroCardScreen;

class MetroCardScreen extends StatefulWidget {
  const MetroCardScreen({super.key});

  @override
  State<MetroCardScreen> createState() => _MetroCardScreenState();
}

class _MetroCardScreenState extends State<MetroCardScreen> with SingleTickerProviderStateMixin {
  // App Theme Color Palette (Matches Aadhaar Card)
  static const Color primaryPurple      = Color(0xFF8B5CF6);
  static const Color headerGradientStart= Color(0xFF9333EA);
  static const Color headerGradientEnd  = Color(0xFFC084FC);
  static const Color textDarkHeading    = Color(0xFF1E293B);
  static const Color textLabelDark      = Color(0xFF334155);
  static const Color textSubdued        = Color(0xFF64748B);
  static const Color bgCanvas           = Color(0xFFF8FAFC);
  static const Color cardSurface        = Colors.white;

  final _formKey    = GlobalKey<FormState>();
  final _cardNoCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  int?  _expandedIdx;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Operators: fetched dynamically from API ────────────────
  List<Map<String, dynamic>> _operators   = [];
  bool                        _opsLoading = true;
  String?                     _opsError;
  Map<String, dynamic>?       _selectedOp;

  bool    _submitting    = false;
  String? _resultStatus;
  String? _resultMessage;
  String? _merchantTxnId;

  // \u2500\u2500\u2500 Razorpay Service \u2500\u2500\u2500
  final RazorpayService _razorpayService = RazorpayService();

  String get _base => ApiService.baseUrl;
  bool get _canShowAmount => _cardNoCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code) {
    if (code.contains('DELHI'))     return const Color(0xFFF97316);
    if (code.contains('MUMBAI'))    return const Color(0xFF3B82F6);
    if (code.contains('HYDERABAD')) return const Color(0xFF8B5CF6);
    if (code.contains('BENGALURU')) return const Color(0xFF10B981);
    return primaryPurple;
  }

  static IconData _iconFor(String code) {
    if (code.contains('DELHI'))     return Icons.subway_rounded;
    if (code.contains('MUMBAI'))    return Icons.train_rounded;
    if (code.contains('HYDERABAD')) return Icons.directions_subway_rounded;
    if (code.contains('BENGALURU')) return Icons.directions_railway_rounded;
    return Icons.subway_outlined;
  }

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _fetchOperators();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNoCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final data = await MetroApiService.getOperators();
      
      if (data['success'] == true) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) setState(() { _opsError = data['message']?.toString() ?? 'Failed to load metro operators'; _opsLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _opsError = 'Failed to connect. Please check your internet connection.'; _opsLoading = false; });
    }
  }

  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) { _snack('Please select a metro operator', isError: true); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) { _snack('Please login', isError: true); return; }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    _razorpayService.openPaymentGateway(
      amount: amount,
      description: 'Metro Card – ${_selectedOp!['label'] ?? 'Payment'}',
      name: 'DZI Infinity',
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitMetro(auth: auth, razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          _snack('Payment failed: ${response.message ?? "Unknown error"}', isError: true);
        }
      },
    );
  }

  Future<void> _doSubmitMetro({required dynamic auth, required String razorpayPaymentId}) async {
    setState(() { _submitting = true; _resultStatus = null; });
    try {
      final data = await MetroApiService.pay({
          'user_id':             auth.userId,
          'card_number':         _cardNoCtrl.text.trim(),
          'operator_id':         _selectedOp!['spkey']?.toString() ?? '',
          'operator_name':       _selectedOp!['label']?.toString() ?? '',
          'amount':              _amountCtrl.text.trim(),
          'razorpay_payment_id': razorpayPaymentId,
          'payment_status':      'paid',
        });
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus = data['success'] == true ? 'success' : 'failed';
          _resultMessage = (data['message']?.toString() ?? (_resultStatus == 'success' ? 'Metro card recharged!' : 'Recharge failed')).replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim();
          _merchantTxnId = data['merchant_txn_id']?.toString() ?? 'MTR${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false; _resultStatus = 'pending';
          _resultMessage = "Couldn't confirm recharge. Check history.";
          _merchantTxnId = 'MTR${DateTime.now().millisecondsSinceEpoch}';
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
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
            final city  = (op['city'] ?? '').toString().toLowerCase();
            return label.contains(q) || city.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.70),
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Container(width: 44, height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Select Metro Operator',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkHeading)),
                    Text(_opsLoading ? 'Loading…' : '${_operators.length} operators available',
                        style: const TextStyle(fontSize: 12, color: textSubdued)),
                  ])),
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.subway_rounded, color: primaryPurple, size: 20)),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: _opsLoading
                    ? const Padding(padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('Loading metro operators…', style: TextStyle(color: textSubdued)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ]))
                        : filtered.isEmpty
                            ? const Padding(padding: EdgeInsets.all(32),
                                child: Text('No operators match', style: TextStyle(color: textSubdued)))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) {
                                  final op    = filtered[i];
                                  final label = op['label']?.toString() ?? '';
                                  final code  = op['code']?.toString() ?? '';
                                  final city  = op['city']?.toString() ?? '';
                                  final col   = _colorFor(code);
                                  final icon  = _iconFor(code);
                                  final isSel = _selectedOp != null &&
                                      op['spkey']?.toString() == _selectedOp!['spkey']?.toString();
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    tileColor: isSel ? col.withValues(alpha: 0.07) : null,
                                    leading: Container(padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), shape: BoxShape.circle),
                                      child: Icon(icon, color: col, size: 22)),
                                    title: Text(label, style: TextStyle(fontSize: 14,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: textDarkHeading)),
                                    subtitle: city.isNotEmpty
                                        ? Text(city, style: const TextStyle(fontSize: 11, color: textSubdued))
                                        : null,
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
    final screenSize = MediaQuery.of(context).size;
    
    double horizontalPadding = screenSize.width > 1100
        ? (screenSize.width - 920) / 2
        : (screenSize.width > 700 ? 24.0 : 12.0);

    return Scaffold(
      backgroundColor: bgCanvas,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _resultStatus != null ? _buildResult() : FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHero(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                    child: Form(key: _formKey, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildAssurance(),
                        const SizedBox(height: 30),
                      ],
                    )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 14,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: textDarkHeading, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Metro ',
                            style: TextStyle(
                              color: primaryPurple,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Card',
                            style: TextStyle(
                              color: textDarkHeading,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Recharge your Metro smart card instantly to keep your journey uninterrupted.',
                      style: TextStyle(
                        color: textSubdued,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/Metro.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [headerGradientStart, headerGradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final selLabel = _selectedOp?['label']?.toString();
    final selCode  = _selectedOp?['code']?.toString() ?? '';
    final selColor = _selectedOp != null ? _colorFor(selCode) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selCode) : Icons.subway_outlined;

    return Container(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner('1. Metro Details', Icons.credit_card),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInput(
                  'Metro Card Number *',
                  _cardNoCtrl,
                  placeholder: 'Enter Smart Card Number',
                  prefixIcon: Icons.subway_rounded,
                  maxLength: 20,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Metro Card Number' : null,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                ),
                const SizedBox(height: 20),
                const Text.rich(
                  TextSpan(
                    text: 'Operators',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading),
                    children: [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: selColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: _opsLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2))
                              : Icon(selIcon, color: selColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _opsLoading ? 'Loading operators…' : selLabel ?? 'Select Metro Operator',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: (selLabel == null || _opsLoading) ? FontWeight.w500 : FontWeight.w700,
                              color: (selLabel == null || _opsLoading) ? const Color(0xFF94A3B8) : textDarkHeading,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            _opsError != null ? 'Retry' : 'Choose',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryPurple),
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
                        const Icon(Icons.refresh_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _opsError!,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (_canShowAmount) ...[
            _buildHeaderBanner('2. Payment', Icons.payment_outlined),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInput(
                    'Recharge Amount (₹) *',
                    _amountCtrl,
                    placeholder: 'Enter recharge amount e.g. 200',
                    prefixIcon: Icons.currency_rupee,
                    isNum: true,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter recharge amount';
                      if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [100, 200, 300, 500, 1000].map((amt) => InkWell(
                      onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryPurple.withValues(alpha: 0.25)),
                        ),
                        child: Text('₹$amt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryPurple)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _handleProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isNum = false,
    int? maxLength,
    String? placeholder,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: cleanLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkHeading),
            children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          maxLength: maxLength,
          inputFormatters: formatters,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: Colors.white,
            filled: true,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 22) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
          ),
          onChanged: (_) => setState(() {}),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final isOk  = _resultStatus == 'success';
    final isPen = _resultStatus == 'pending';
    final col   = isOk ? const Color(0xFF10B981) : isPen ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final icon  = isOk ? Icons.check_circle_rounded : isPen ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final title = isOk ? 'Metro Card Recharged!' : isPen ? 'Processing…' : 'Recharge Failed';
    final double paidAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dtStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final receipt = BbpsReceiptModel(
      serviceCategory: 'Metro Card Recharge',
      operatorName: _selectedOp?['name']?.toString() ?? 'Metro Rail Authority',
      accountNumber: _cardNoCtrl.text.trim(),
      customerName: '',
      merchantTxnId: _merchantTxnId ?? 'MET${now.millisecondsSinceEpoch}',
      dateTimeStr: dtStr,
      amount: paidAmt,
      status: isOk ? 'Success' : (isPen ? 'Pending' : 'Failed'),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(26.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: col),
              ),
              const SizedBox(height: 8),
              Text(
                (_resultMessage ?? '').replaceAll('(TEST MODE)', '').replaceAll('(TEST MODE - no real money moved)', '').trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Transaction Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _merchantTxnId ?? '—',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryPurple, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Download / View Bill Receipt & Share Buttons ──
              if (isOk) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BbpsReceiptScreen(receipt: receipt)),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: const Text('View & Download Bill Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => BbpsInvoicePdfService.shareToWhatsApp(receipt),
                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => BbpsInvoicePdfService.shareViaEmail(receipt),
                        icon: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
                        label: const Text('Email', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryPurple,
                          side: const BorderSide(color: primaryPurple),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => setState(() {
                    _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                    _cardNoCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: textSubdued,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Recharge Another Card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssurance() => Container(
    decoration: BoxDecoration(
      color: cardSurface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(
      children: [
        _tile(0, Icons.bolt_rounded, const Color(0xFFF59E0B), 'Instant Recharge', 'Direct top-up with Metro Rail network', '⚡ Real-time smart card top-up directly credited to your metro card.'),
        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
        _tile(1, Icons.shield_rounded, const Color(0xFF10B981), '100% BBPS Secure', 'Encrypted via BBPS network', '🛡️ 256-bit SSL encrypted payment authorized by NPCI.'),
        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
        _tile(2, Icons.receipt_long_rounded, primaryPurple, 'Instant Receipt', 'Official Metro card recharge proof', '🧾 Download official BBPS receipt after recharge.'),
      ],
    ),
  );

  Widget _tile(int idx, IconData icon, Color color, String title, String sub, String detail) {
    final isExp = _expandedIdx == idx;
    return InkWell(
      onTap: () => setState(() => _expandedIdx = isExp ? null : idx),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDarkHeading)),
                      Text(sub, style: const TextStyle(fontSize: 12, color: textSubdued)),
                    ],
                  ),
                ),
                Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 22),
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
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
                ),
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textLabelDark, height: 1.35),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



