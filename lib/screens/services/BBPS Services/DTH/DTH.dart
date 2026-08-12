import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';

/// Convenient alias so both `DTH` and `DTHScreen` can be used.
typedef DTH = DTHScreen;

/// Responsive, modern DTH Recharge & Bill Payment Screen.
/// All operator data is fetched from the backend API — no hardcoded data.
class DTHScreen extends StatefulWidget {
  const DTHScreen({super.key});

  @override
  State<DTHScreen> createState() => _DTHScreenState();
}

class _DTHScreenState extends State<DTHScreen> with TickerProviderStateMixin {
  // Money Transfer Reference Teal & Orange Theme Palette
  static const Color primaryPurple = Color(0xFF00A896);
  static const Color primaryDark = Color(0xFF028090);
  static const Color accentViolet = Color(0xFF028090);
  static const Color accentRed = Color(0xFFFF6B00);
  static const Color bgGradientEnd = Color(0xFFF4FBF7);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE9D5FF);
  static const Color inputFill = Color(0xFFFAF5FF);

  // Form Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _customerIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  // Track expanded assurance tile
  int? _expandedAssuranceIndex;

  // ─── API-driven Operators ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _operators = [];
  bool _operatorsLoading = true;
  String? _operatorsError;

  /// Selected operator — null means "none selected yet"
  Map<String, dynamic>? _selectedOperator;

  // ─── Submission State ──────────────────────────────────────────────────────
  bool _submitting = false;
  String? _resultStatus;   // 'success' | 'failed' | 'pending'
  String? _resultMessage;
  String? _merchantTxnId;

  // ─── Operator icon mapping by code / label keywords ────────────────────────
  static IconData _iconForOperator(String code, String label) {
    final key = '${code}_$label'.toLowerCase();
    if (key.contains('airtel')) return Icons.tv_rounded;
    if (key.contains('dish')) return Icons.satellite_alt_rounded;
    if (key.contains('sun')) return Icons.wb_sunny_rounded;
    if (key.contains('tata') || key.contains('sky') || key.contains('play')) {
      return Icons.live_tv_rounded;
    }
    if (key.contains('videocon') || key.contains('d2h')) {
      return Icons.connected_tv_rounded;
    }
    return Icons.tv_rounded;
  }

  static Color _colorForOperator(String code, String label) {
    final key = '${code}_$label'.toLowerCase();
    if (key.contains('airtel')) return const Color(0xFFE11D48);
    if (key.contains('dish')) return const Color(0xFF0284C7);
    if (key.contains('sun')) return const Color(0xFFF59E0B);
    if (key.contains('tata') || key.contains('sky') || key.contains('play')) {
      return const Color(0xFF7C3AED);
    }
    if (key.contains('videocon') || key.contains('d2h')) {
      return const Color(0xFF10B981);
    }
    return primaryPurple;
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchOperators();
  }

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    setState(() {
      _operatorsLoading = true;
      _operatorsError = null;
    });
    try {
      final res = await ApiService.fetchApi('/dth/operators');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['operators'] != null) {
        final rawList = (data['operators'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _operators = rawList;
            _operatorsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _operatorsError =
                data['message']?.toString() ?? 'Failed to load DTH operators';
            _operatorsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _operatorsError = 'Failed to connect to server. Tap Retry.';
          _operatorsLoading = false;
        });
      }
    }
  }

  // ─── API: Submit Recharge ──────────────────────────────────────────────────
  Future<void> _handleProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOperator == null) {
      _showSnackBar('Please select a DTH operator', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      _showSnackBar('Please login to recharge', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _resultStatus = null;
    });

    try {
      final res = await ApiService.postApi('/dth/pay', {
        'user_id': auth.userId,
        'customer_id': _customerIdCtrl.text.trim(),
        'operator_id': _selectedOperator!['spkey']?.toString() ??
            _selectedOperator!['id']?.toString() ?? '',
        'operator_name': _selectedOperator!['label']?.toString() ??
            _selectedOperator!['name']?.toString() ?? '',
        'amount': _amountCtrl.text.trim(),
      });

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = data['success'] == true
              ? (data['status']?.toString() ?? 'success')
              : 'failed';
          _resultMessage = data['message']?.toString() ??
              (_resultStatus == 'success'
                  ? 'DTH Recharge submitted successfully!'
                  : 'DTH Recharge failed. Please try again.');
          _merchantTxnId = data['merchant_txn_id']?.toString() ??
              'DTH${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _resultStatus = 'pending';
          _resultMessage =
              "Couldn't confirm the recharge status right now. Please check status in a moment.";
          _merchantTxnId = 'DTH${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Bottom Sheet: Operator Brand Grid Picker ──────────────────────────────
  void _openOperatorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select DTH Operator',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap your TV provider to continue',
                          style: TextStyle(fontSize: 12, color: textMuted),
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
                    child: const Icon(Icons.connected_tv_rounded, color: primaryPurple, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Loading / Error / Grid ────────────────────────────────────
              if (_operatorsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
                        SizedBox(height: 14),
                        Text('Loading operators…', style: TextStyle(color: textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else if (_operatorsError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      // ── Fixed: clamped to 4 lines to prevent overflow ──
                      Text(
                        _operatorsError!,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textMuted, fontSize: 12, height: 1.4),
                      ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_operators.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No operators available', style: TextStyle(color: textMuted)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.3,
                  ),
                  itemCount: _operators.length,
                  itemBuilder: (context, index) {
                    final op = _operators[index];
                    final isSelected = _selectedOperator != null &&
                        op['spkey']?.toString() == _selectedOperator!['spkey']?.toString();
                    final code = op['code']?.toString() ?? '';
                    final label = op['label']?.toString() ?? op['name']?.toString() ?? '';
                    final Color brandColor = _colorForOperator(code, label);
                    final IconData brandIcon = _iconForOperator(code, label);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOperator = op;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? brandColor.withValues(alpha: 0.12) : inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? brandColor : borderColor,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(brandIcon, color: brandColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSelected ? 'Active ✓' : 'Tap to select',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? brandColor : textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _resultStatus != null
                    ? _buildResultView()
                    : Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildIntegratedTopHeader(context),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18),
                                  _buildQuickPillsRow(),
                                  const SizedBox(height: 20),
                                  _buildFormCard(),
                                  const SizedBox(height: 24),
                                  _buildSubmitButton(),
                                  const SizedBox(height: 24),
                                  _buildAssuranceListCard(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Header ────────────────────────────────────────────────────────────
  Widget _buildIntegratedTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, primaryDark, accentViolet],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'BBPS Assured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      TextSpan(
                        text: 'RECHARGE YOUR ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: '(DTH)',
                        style: TextStyle(color: Color(0xFFFFD1D1), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DTH Service Portal',
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tell us your number and we will figure out the rest !',
                              style: TextStyle(
                                fontSize: 13,
                                color: textDark,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.satellite_alt_rounded,
                          color: primaryPurple,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Pills ────────────────────────────────────────────────────────────
  Widget _buildQuickPillsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPillItem(Icons.badge_rounded, 'Customer ID'),
          _buildPillItem(Icons.grid_view_rounded, 'Operators'),
          _buildPillItem(Icons.bolt_rounded, 'Instant'),
          _buildPillItem(Icons.verified_user_rounded, 'Secured'),
        ],
      ),
    );
  }

  Widget _buildPillItem(IconData icon, String label) {
    return Column(
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
  }

  // ─── Form Card ─────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    final selectedLabel = _selectedOperator != null
        ? (_selectedOperator!['label']?.toString() ??
            _selectedOperator!['name']?.toString() ??
            'Unknown')
        : null;

    final selectedCode = _selectedOperator?['code']?.toString() ?? '';
    final Color selectedColor = _selectedOperator != null
        ? _colorForOperator(selectedCode, selectedLabel ?? '')
        : const Color(0xFF94A3B8);
    final IconData selectedIcon = _selectedOperator != null
        ? _iconForOperator(selectedCode, selectedLabel ?? '')
        : Icons.tv_off_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. CUSTOMER ID FIELD ──────────────────────────────────────────
          const Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                'Customer ID',
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
            controller: _customerIdCtrl,
            keyboardType: TextInputType.text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
              LengthLimitingTextInputFormatter(18),
            ],
            decoration: InputDecoration(
              hintText: 'Enter your DTH Customer ID',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.subtitles_rounded, color: primaryPurple, size: 20),
              suffixIcon: _customerIdCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 18),
                      onPressed: () {
                        setState(() {
                          _customerIdCtrl.clear();
                        });
                      },
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2.0),
              ),
            ),
            onChanged: (val) {
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your Customer ID';
              }
              if (value.trim().length < 5) {
                return 'Please enter a valid Customer ID';
              }
              return null;
            },
          ),

          const SizedBox(height: 22),

          // ── 2. OPERATORS BRAND GRID FIELD ─────────────────────────────────
          const Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: primaryPurple),
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

          // Operator selector box
          InkWell(
            onTap: _operatorsLoading ? null : _openOperatorPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: _operatorsLoading
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading operators…',
                            style: TextStyle(color: textMuted, fontSize: 14)),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(selectedIcon, color: selectedColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedLabel ?? 'Select Operator',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selectedLabel == null ? FontWeight.w400 : FontWeight.w700,
                              color: selectedLabel == null ? const Color(0xFF94A3B8) : textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _operatorsError != null ? 'Retry' : 'Choose',
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

          // Error hint under operator selector
          if (_operatorsError != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _fetchOperators,
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded, size: 14, color: accentRed),
                  const SizedBox(width: 4),
                  Text(
                    _operatorsError!,
                    style: const TextStyle(fontSize: 11, color: accentRed),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ── 3. AMOUNT FIELD ───────────────────────────────────────────────
          const Row(
            children: [
              Icon(Icons.currency_rupee_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                'Recharge Amount (₹)',
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter amount e.g. 299',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.currency_rupee, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryPurple, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: accentRed, width: 2.0),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the recharge amount';
              }
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Quick amount chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [199, 299, 399, 499, 649, 999].map((amt) {
              return InkWell(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryPurple.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '₹$amt',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryPurple),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Submit Button ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          shadowColor: primaryPurple.withValues(alpha: 0.35),
        ),
        onPressed: _submitting ? null : _handleProceed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _submitting
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [const Color(0xFFFF6B00), const Color(0xFFE65100)],
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
                      Text(
                        'Proceed to Pay Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Result View (replaces form after submission) ───────────────────────────
  Widget _buildResultView() {
    final isSuccess = _resultStatus == 'success';
    final isPending = _resultStatus == 'pending';
    final Color statusColor = isSuccess
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    final IconData statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.cancel_rounded;
    final String statusTitle = isSuccess
        ? 'Recharge Successful!'
        : isPending
            ? 'Processing…'
            : 'Recharge Failed';

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
            // Status Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _resultMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 22),
            // Transaction ID
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Transaction Reference ID',
                    style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
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
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _resultStatus = null;
                    _resultMessage = null;
                    _merchantTxnId = null;
                    _customerIdCtrl.clear();
                    _amountCtrl.clear();
                    _selectedOperator = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'New Recharge',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Assurance Card ─────────────────────────────────────────────────────────
  Widget _buildAssuranceListCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildClickableAssuranceTile(
            index: 0,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Instant Processing',
            subtitle: 'Instant TV channel activation in real-time',
            detailText:
                '⚡ Real-time direct bill settlement and immediate TV signal refresh with your DTH provider.',
          ),
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
          _buildClickableAssuranceTile(
            index: 1,
            icon: Icons.shield_rounded,
            color: const Color(0xFF10B981),
            title: '100% BBPS Secure Payment',
            subtitle: 'Encrypted transactions protected by BBPS',
            detailText:
                '🛡️ End-to-end 256-bit SSL encrypted transaction authorized by National Payments Corporation of India.',
          ),
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
          _buildClickableAssuranceTile(
            index: 2,
            icon: Icons.receipt_long_rounded,
            color: primaryPurple,
            title: 'Instant Digital Receipt',
            subtitle: 'Official digital proof of DTH recharge',
            detailText:
                '🧾 Download official BBPS bill receipt instantly after successful payment.',
          ),
        ],
      ),
    );
  }

  Widget _buildClickableAssuranceTile({
    required int index,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String detailText,
  }) {
    final isExpanded = _expandedAssuranceIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedAssuranceIndex = isExpanded ? null : index;
        });
      },
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: primaryPurple,
                  size: 22,
                ),
              ],
            ),
            if (isExpanded) ...[
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
                  detailText,
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
