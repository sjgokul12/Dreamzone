import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

/// Convenient alias so both `Electricity` and `ElectricityScreen` can be used.
typedef Electricity = ElectricityScreen;

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen>
    with TickerProviderStateMixin {
  // ─── Purple / Violet Theme Palette (matches reference design) ─────────────
  static const Color primaryPurple      = Color(0xFF6C5CE7);
  static const Color primaryPurpleDark  = Color(0xFF5B4BD6);
  static const Color primaryPurpleDeep  = Color(0xFF4B3FC2);
  static const Color accentNavy         = Color(0xFF1E1B3A);
  static const Color accentRed          = Color(0xFFFF6B6B);
  static const Color bgGradientStart    = Color(0xFFF3F1FF);
  static const Color bgGradientEnd      = Color(0xFFFAFAFF);
  static const Color cardWhite          = Colors.white;
  static const Color textDark           = Color(0xFF1E1B3A);
  static const Color textMuted          = Color(0xFF6B7280);
  static const Color borderColor        = Color(0xFFE4DFFB);
  static const Color inputFill          = Color(0xFFF6F4FF);
  static const Color chipLavender       = Color(0xFFEDE9FE);

  // Form
  final _formKey            = GlobalKey<FormState>();
  final _subscriptionIdCtrl = TextEditingController();
  final _amountCtrl         = TextEditingController();
  int? _expandedAssuranceIndex;
  bool _instantProcessing   = true;

  // ─── API-driven Operators ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _operators     = [];
  bool                        _opsLoading   = true;
  String?                     _opsError;
  Map<String, dynamic>?       _selectedOp;   // null = nothing selected

  // Search / filter
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ─── Submission State ─────────────────────────────────────────────────────
  bool    _submitting     = false;
  String? _resultStatus;   // 'success' | 'failed' | 'pending'
  String? _resultMessage;
  String? _merchantTxnId;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String get _base => ApiService.baseUrl;

  bool get _canShowAmount =>
      _subscriptionIdCtrl.text.trim().isNotEmpty && _selectedOp != null;

  static Color _colorFor(String code, String label) {
    // Keep every board icon inside the purple family so the palette stays
    // consistent with the new theme, while still giving a touch of
    // variety between different boards.
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('adani') || k.contains('mumbai') || k.contains('best')) {
      return const Color(0xFF6C5CE7);
    }
    if (k.contains('airtel') || k.contains('tata')) return const Color(0xFF8B7CF6);
    if (k.contains('bses') || k.contains('delhi') || k.contains('ndmc') ||
        k.contains('sndl')) {
      return const Color(0xFF7C6FF0);
    }
    if (k.contains('tneb') || k.contains('kerala') || k.contains('kseb')) {
      return const Color(0xFF5B4BD6);
    }
    if (k.contains('gujarat') || k.contains('torrent') || k.contains('dgvcl') ||
        k.contains('mgvcl') || k.contains('ugvcl') || k.contains('pgvcl')) {
      return const Color(0xFF9C8CFB);
    }
    if (k.contains('karnataka') || k.contains('bescom') || k.contains('gescom') ||
        k.contains('hescom') || k.contains('mescom') || k.contains('chamundeshwari')) {
      return const Color(0xFF7C6FF0);
    }
    if (k.contains('rajasthan') || k.contains('jvvnl') || k.contains('avvnl') ||
        k.contains('jdvvnl') || k.contains('kota') || k.contains('bikaner') ||
        k.contains('bharatpur') || k.contains('ajmer')) {
      return const Color(0xFFA78BFA);
    }
    return primaryPurple;
  }

  static IconData _iconFor(String code, String label) {
    final k = '${code}_$label'.toLowerCase();
    if (k.contains('solar')) return Icons.solar_power_rounded;
    if (k.contains('wind')) return Icons.air_rounded;
    if (k.contains('metro') || k.contains('municipal') || k.contains('ndmc')) {
      return Icons.location_city_rounded;
    }
    if (k.contains('rural')) return Icons.agriculture_rounded;
    if (k.contains('goa') || k.contains('daman') || k.contains('diu') ||
        k.contains('dadar') || k.contains('dnh')) {
      return Icons.waves_rounded;
    }
    return Icons.electric_bolt_rounded;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchOperators();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _subscriptionIdCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── API: Fetch Operators ─────────────────────────────────────────────────
  Future<void> _fetchOperators() async {
    if (mounted) setState(() { _opsLoading = true; _opsError = null; });
    try {
      final res = await ApiService.fetchApi('/electricity/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null && (data['operators'] as List).isNotEmpty) {
        final list = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) setState(() { _operators = list; _opsLoading = false; });
      } else {
        if (mounted) {
          setState(() {
            _operators = [];
            _opsLoading = false;
            _opsError = data['message']?.toString() ?? 'No operators available. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _operators = [];
          _opsLoading = false;
          _opsError = 'Failed to load operators. Please check your connection and retry.';
        });
      }
    }
  }

  // ─── API: Submit Bill ─────────────────────────────────────────────────────
  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOp == null) {
      _showSnackBar('Please select an electricity board operator', isError: true);
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnackBar('Please login to pay bill', isError: true);
      return;
    }

    setState(() { _submitting = true; _resultStatus = null; });

    try {
      final res = await ApiService.postApi('/electricity/pay', {
        'user_id':       auth.userId,
        'ca_number':     _subscriptionIdCtrl.text.trim(),
        'operator_id':   _selectedOp!['spkey']?.toString() ?? _selectedOp!['id']?.toString() ?? '',
        'operator_name': _selectedOp!['label']?.toString() ?? _selectedOp!['name']?.toString() ?? '',
        'amount':        _amountCtrl.text.trim(),
      });

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus  = data['success'] == true
              ? (data['status']?.toString() ?? 'success')
              : 'failed';
          _resultMessage = data['message']?.toString() ??
              (_resultStatus == 'success' ? 'Bill paid!' : 'Payment failed');
          _merchantTxnId = data['merchant_txn_id']?.toString() ??
              'ELEC${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting    = false;
          _resultStatus  = 'pending';
          _resultMessage = "Couldn't confirm payment status. Check history shortly.";
          _merchantTxnId = 'ELEC${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ]),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Operator Picker Bottom Sheet ─────────────────────────────────────────
  void _openOperatorPicker() {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query    = _searchCtrl.text.toLowerCase();
          final filtered = _operators.where((op) {
            final label = (op['label'] ?? op['name'] ?? '').toString().toLowerCase();
            final state = (op['state'] ?? '').toString().toLowerCase();
            return label.contains(query) || state.contains(query);
          }).toList();

          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Electricity Board',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w900, color: textDark)),
                        const SizedBox(height: 3),
                        Text('${_operators.length} boards available',
                            style: const TextStyle(fontSize: 12, color: textMuted)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.electric_bolt_rounded,
                          color: primaryPurple, size: 20),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by board name or state…',
                      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: primaryPurple, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: textMuted, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setModalState(() {});
                              })
                          : null,
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Flexible(
                  child: _opsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                            SizedBox(height: 14),
                            Text('Loading electricity boards…',
                                style: TextStyle(color: textMuted, fontSize: 13)),
                          ]),
                        )
                      : _opsError != null
                          ? Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.cloud_off_rounded,
                                    size: 48, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(_opsError!,
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: textMuted, fontSize: 12, height: 1.4)),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _fetchOperators();
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ]),
                            )
                          : filtered.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No boards match your search',
                                      style: TextStyle(color: textMuted)))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  itemBuilder: (_, i) {
                                    final op     = filtered[i];
                                    final label  = op['label']?.toString() ?? op['name']?.toString() ?? '';
                                    final state  = op['state']?.toString() ?? '';
                                    final code   = op['code']?.toString() ?? '';
                                    final color  = _colorFor(code, label);
                                    final icon   = _iconFor(code, label);
                                    final isSel  = _selectedOp != null &&
                                        op['spkey']?.toString() ==
                                            _selectedOp!['spkey']?.toString();

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      tileColor: isSel
                                          ? color.withValues(alpha: 0.07)
                                          : null,
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 20),
                                      ),
                                      title: Text(label,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSel
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: textDark)),
                                      subtitle: state.isNotEmpty
                                          ? Text(state,
                                              style: const TextStyle(
                                                  fontSize: 11, color: textMuted))
                                          : null,
                                      trailing: isSel
                                          ? const Icon(Icons.check_circle_rounded,
                                              color: primaryPurple, size: 22)
                                          : const Icon(Icons.chevron_right_rounded,
                                              color: Color(0xFF94A3B8)),
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

  // ─── Build ────────────────────────────────────────────────────────────────
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
                child: _resultStatus != null
                    ? _buildResultView()
                    : Column(children: [
                        _buildCustomAppBar(context),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeroHeadline(),
                                  const SizedBox(height: 20),
                                  _buildInstantPayCard(),
                                  const SizedBox(height: 18),
                                  _buildQuickPillsRow(),
                                  const SizedBox(height: 20),
                                  _buildFormCard(),
                                  if (_canShowAmount) ...[
                                    const SizedBox(height: 24),
                                    _buildSubmitButton(),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: primaryPurple, size: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipLavender,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(children: [
              Icon(Icons.shield_rounded, color: primaryPurple, size: 18),
              SizedBox(width: 6),
              Text('BBPS Assured',
                  style: TextStyle(color: primaryPurple, fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Hero Headline + Bulb Illustration ────────────────────────────────────
  Widget _buildHeroHeadline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft decorative glow circle behind the bulb illustration
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPurple.withValues(alpha: 0.07),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900,
                            height: 1.15, fontFamily: 'Roboto'),
                        children: [
                          TextSpan(text: 'Recharge Your\n',
                              style: TextStyle(color: textDark)),
                          TextSpan(text: 'Electricity Bill',
                              style: TextStyle(color: primaryPurple,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Tell us your number and\nwe will figure out the rest!',
                        style: TextStyle(fontSize: 13.5,
                            color: textMuted, height: 1.4)),
                  ],
                ),
              ),
              // ── Bulb + Meter illustration (assets/bulp.png) ──────────────
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'assets/bulp.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryPurple.withValues(alpha: 0.08),
                      ),
                      child: const Icon(Icons.lightbulb_rounded,
                          color: primaryPurple, size: 56),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── "Pay Smart. Live Easy." Instant Pay Card ─────────────────────────────
  Widget _buildInstantPayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: chipLavender.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.bolt_rounded, color: primaryPurple, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [primaryPurple, primaryPurpleDark]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('INSTANT PAY',
                    style: TextStyle(color: Colors.white, fontSize: 9.5,
                        fontWeight: FontWeight.w800, letterSpacing: 0.6)),
              ),
              const SizedBox(height: 6),
              const Text('Pay Smart. Live Easy.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: textDark)),
              const SizedBox(height: 2),
              Text('Quick, secure and hassle-free\nelectricity bill payments.',
                  style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.3)),
            ],
          ),
        ),
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_rounded, color: primaryPurple, size: 18),
        ),
      ]),
    );
  }

  // ─── Quick Pills ──────────────────────────────────────────────────────────
  Widget _buildQuickPillsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF1E1B3A).withValues(alpha: 0.03),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(child: _buildPillItem(Icons.credit_card_rounded, 'CA Number')),
        _pillDivider(),
        Expanded(child: _buildPillItem(Icons.grid_view_rounded, 'Operators')),
        _pillDivider(),
        Expanded(child: _buildPillItem(Icons.bolt_rounded, 'Instant')),
        _pillDivider(),
        Expanded(child: _buildPillItem(Icons.shield_rounded, 'Secured')),
      ]),
    );
  }

  Widget _pillDivider() => Container(width: 1, height: 34, color: const Color(0xFFEEF0F5));

  Widget _buildPillItem(IconData icon, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: chipLavender, shape: BoxShape.circle),
        child: Icon(icon, color: primaryPurple, size: 20),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: textDark)),
    ]);
  }

  // ─── Form Card ────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    final selLabel = _selectedOp != null
        ? (_selectedOp!['label']?.toString() ?? _selectedOp!['name']?.toString() ?? '')
        : null;
    final selCode  = _selectedOp?['code']?.toString() ?? '';
    final selColor = _selectedOp != null ? _colorFor(selCode, selLabel!) : const Color(0xFF94A3B8);
    final selIcon  = _selectedOp != null ? _iconFor(selCode, selLabel!) : Icons.electric_bolt_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: const Color(0xFF1E1B3A).withValues(alpha: 0.04),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── 1. CA / Consumer Number ──────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.credit_card_rounded, size: 16, color: primaryPurple),
          ),
          const SizedBox(width: 10),
          const Text('Consumer / CA Number',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _subscriptionIdCtrl,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your CA / Consumer Number',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true, fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.tag_rounded, color: primaryPurple, size: 20),
            suffixIcon: _subscriptionIdCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: Color(0xFFCBD5E1), size: 18),
                    onPressed: () => setState(() => _subscriptionIdCtrl.clear()))
                : null,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your CA/Consumer Number';
            if (v.trim().length < 4) return 'Please enter a valid Consumer Number';
            return null;
          },
        ),

        const SizedBox(height: 22),

        // ── 2. Operators (API) ────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bolt_rounded, size: 16, color: primaryPurple),
          ),
          const SizedBox(width: 10),
          const Text('Operators',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
        ]),
        const SizedBox(height: 10),

        InkWell(
          onTap: _opsLoading ? null : _openOperatorPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: _opsLoading
                ? const Row(children: [
                    SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Loading operators…',
                        style: TextStyle(color: textMuted, fontSize: 14)),
                  ])
                : Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(selIcon, color: selColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selLabel ?? 'Select Electricity Board',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selLabel == null ? FontWeight.w400 : FontWeight.w700,
                          color: selLabel == null ? const Color(0xFF9CA3AF) : textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipLavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_opsError != null ? 'Retry' : 'Choose',
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w800, color: primaryPurple)),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: primaryPurple, size: 16),
                      ]),
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
              Expanded(child: Text(_opsError!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: accentRed))),
            ]),
          ),
        ],

        // ── Instant Processing toggle (matches reference design) ──────────────
        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFF1EFFB)),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bolt_rounded, color: primaryPurple, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instant Processing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                SizedBox(height: 2),
                Text('Direct settlement with state\nelectricity board',
                    style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.3)),
              ],
            ),
          ),
          Switch(
            value: _instantProcessing,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryPurple,
            onChanged: (v) => setState(() => _instantProcessing = v),
          ),
        ]),

        // ── 3. Amount (shown once CA + operator selected) ─────────────────────
        if (_canShowAmount) ...[
          const SizedBox(height: 18),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: chipLavender, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.currency_rupee_rounded, size: 16, color: primaryPurple),
            ),
            const SizedBox(width: 10),
            const Text('Bill Amount (₹)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter bill amount e.g. 850',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              filled: true, fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryPurple, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: accentRed, width: 1.2)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: accentRed, width: 2)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter the bill amount';
              final p = double.tryParse(v.trim());
              if (p == null || p <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: [500, 750, 1000, 1500, 2000, 3000].map((amt) {
              return InkWell(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipLavender,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                  ),
                  child: Text('₹$amt',
                      style: const TextStyle(fontSize: 11.5,
                          fontWeight: FontWeight.bold, color: primaryPurple)),
                ),
              );
            }).toList(),
          ),
        ],

        // ── 100% Secure Payments strip (matches reference design) ─────────────
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: chipLavender.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryPurple, primaryPurpleDark]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('100% Secure Payments',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800,
                          color: primaryPurple)),
                  SizedBox(height: 2),
                  Text('Your transactions are protected\nwith bank-level security',
                      style: TextStyle(fontSize: 11, color: textMuted, height: 1.3)),
                ],
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: primaryPurple, size: 16),
            ),
          ]),
        ),
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
          elevation: 6,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
        ),
        onPressed: _submitting ? null : _handleProceed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _submitting
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [primaryPurple, primaryPurpleDeep],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Proceed to Pay Bill',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.white, letterSpacing: 0.3)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ])),
        ),
      ),
    );
  }

  // ─── Result View ──────────────────────────────────────────────────────────
  Widget _buildResultView() {
    final isSuccess = _resultStatus == 'success';
    final isPending = _resultStatus == 'pending';
    final Color sc = isSuccess ? const Color(0xFF10B981)
        : isPending ? const Color(0xFFF59E0B) : Colors.redAccent;
    final IconData si = isSuccess ? Icons.check_circle_rounded
        : isPending ? Icons.hourglass_top_rounded : Icons.cancel_rounded;
    final String title = isSuccess ? 'Bill Paid!' : isPending ? 'Processing…' : 'Payment Failed';

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
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(si, color: sc, size: 48),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w900, color: sc)),
          const SizedBox(height: 10),
          Text(_resultMessage ?? '', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5)),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: chipLavender,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              const Text('Transaction Reference ID',
                  style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(_merchantTxnId ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: primaryPurple, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _resultStatus = null; _resultMessage = null; _merchantTxnId = null;
                _subscriptionIdCtrl.clear(); _amountCtrl.clear(); _selectedOp = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple, foregroundColor: Colors.white,
                elevation: 3,
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
}