import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoneyTransferScreen extends StatefulWidget {
  const MoneyTransferScreen({super.key});

  @override
  State<MoneyTransferScreen> createState() => _MoneyTransferScreenState();
}

class _MoneyTransferScreenState extends State<MoneyTransferScreen> {
  // Theme Palette (Purple / Violet Theme)
  static const Color primaryPurple     = Color(0xFF7C3AED);
  static const Color primaryDarkPurple = Color(0xFF6D28D9);
  static const Color accentIndigo      = Color(0xFF4F46E5);
  static const Color bgLavender        = Color(0xFFF5EEFF);
  static const Color cardWhite         = Colors.white;
  static const Color textDark          = Color(0xFF1E1B4B);
  static const Color textMuted         = Color(0xFF6B7280);
  static const Color borderColor       = Color(0xFFEDE4FF);
  static const Color inputFill         = Color(0xFFF9F5FF);

  // Button Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkButtonGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF0F172A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final _formKey = GlobalKey<FormState>();

  // Flow Flags
  bool _isMobileSearched = false;
  bool _deviceConnected = false;

  // Controllers
  final TextEditingController _findMobileCtrl = TextEditingController();
  final TextEditingController _regMobileCtrl  = TextEditingController();
  final TextEditingController _regAadhaarCtrl = TextEditingController();
  final TextEditingController _ekycMobileCtrl = TextEditingController();

  String _searchedMobile = '';

  @override
  void dispose() {
    _findMobileCtrl.dispose();
    _regMobileCtrl.dispose();
    _regAadhaarCtrl.dispose();
    _ekycMobileCtrl.dispose();
    super.dispose();
  }

  void _handleSearchRemitter() {
    FocusScope.of(context).unfocus();
    final num = _findMobileCtrl.text.trim();
    if (num.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit Mobile Number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _searchedMobile = num;
      _regMobileCtrl.text = num;
      _ekycMobileCtrl.text = num;
      _isMobileSearched = true;
    });
  }

  void _handleRegisterRemitter() {
    FocusScope.of(context).unfocus();
    if (_regAadhaarCtrl.text.trim().length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 12-digit Aadhaar Number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _showOtpPopupDialog();
  }

  /// OTP Popup Dialog
  void _showOtpPopupDialog() {
    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 48).clamp(280.0, 420.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: dialogWidth,
              padding: EdgeInsets.all(media.size.width < 360 ? 16 : 22),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.3), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F7C3AED),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(dialogContext),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgLavender,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: primaryPurple, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 82,
                        decoration: BoxDecoration(
                          color: bgLavender,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryPurple, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 4,
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryPurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '••••••••',
                                style: TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: -4,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryPurple, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_outlined, color: primaryPurple, size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'Enter the verification code sent to\nyour mobile number ($_searchedMobile)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 38,
                          height: 46,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: bgLavender,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryPurple.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty && index < 5) {
                                  FocusScope.of(dialogContext).nextFocus();
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('A new verification code has been sent.'),
                          backgroundColor: primaryPurple,
                        ),
                      );
                    },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primaryPurple,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP Verified Successfully!'),
                              backgroundColor: primaryPurple,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'VERIFY CODE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleCheckLoginStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outlet 2FA Login Status Checked.'),
        backgroundColor: primaryPurple,
      ),
    );
  }

  void _handleCheckDevice() {
    setState(() {
      _deviceConnected = !_deviceConnected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _deviceConnected ? 'Biometric device connected successfully!' : 'Device disconnected.',
        ),
        backgroundColor: _deviceConnected ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width > 768;

    return Scaffold(
      backgroundColor: bgLavender,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : 550),
              child: Column(
                children: [
                  _buildHeaderBanner(context, media),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 1. Find Remitter Card
                            _buildFindRemitterCard(),

                            // 2. Remitter Registration Card (Revealed after searching mobile)
                            if (_isMobileSearched) ...[
                              const SizedBox(height: 16),
                              _buildRegisterRemitterCard(),
                            ],

                            // 3. Outlet Login Status Card (AEPS 2FA Card - Screenshot 2)
                            const SizedBox(height: 16),
                            _buildOutletLoginStatusCard(),

                            // 4. Merchant Biometric KYC Card (AEPS Biometric Card - Screenshot 3)
                            const SizedBox(height: 16),
                            _buildMerchantBiometricKycCard(),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Gradient Header Banner ──────────────────────────────────────────
  Widget _buildHeaderBanner(BuildContext ctx, MediaQueryData media) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF6D28D9), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: primaryDarkPurple.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.maybePop(ctx),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.amberAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'PAYMENT SERVICES',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Money Transfer',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Domestic Money Transfer & Remitter Portal',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox(
                    height: 90,
                    child: Image.asset(
                      'assets/Money Transfer.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, size: 48, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Card 1: Find Remitter ────────────────────────────────────────────────
  Widget _buildFindRemitterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded, color: primaryPurple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find Remitter',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 70,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter the mobile number to fetch remitter details',
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          Row(
            children: const [
              Icon(Icons.phone_iphone_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Mobile Number', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _findMobileCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter Mobile Number',
              hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(Icons.smartphone_rounded, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 5,
                shadowColor: primaryPurple.withValues(alpha: 0.35),
              ),
              onPressed: _handleSearchRemitter,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Search Remitter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: primaryPurple, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card 2: Remitter Registration ───────────────────────────────────────
  Widget _buildRegisterRemitterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, color: primaryPurple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remitter Registration',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 80,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Complete registration to activate money transfer',
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          Row(
            children: const [
              Icon(Icons.phone_iphone_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Mobile Number', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _regMobileCtrl,
            readOnly: true,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(Icons.smartphone_rounded, color: primaryPurple, size: 20),
              suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: const [
              Icon(Icons.fingerprint_rounded, size: 18, color: primaryPurple),
              SizedBox(width: 8),
              Text('Aadhaar Number', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textDark)),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _regAadhaarCtrl,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter your 12 digit Aadhaar number',
              hintStyle: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13.5),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(Icons.fingerprint_rounded, color: primaryPurple, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderColor, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 5,
                shadowColor: primaryPurple.withValues(alpha: 0.35),
              ),
              onPressed: _handleRegisterRemitter,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Register Remitter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: primaryPurple, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card 3: Outlet Login Status 🔐 (AEPS Card - Screenshot 2) ────────────
  Widget _buildOutletLoginStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/AEPS.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/AePS logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx2, err2, st2) => Container(
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 54, color: primaryPurple),
                        SizedBox(height: 8),
                        Text('Aadhaar Merchant Outlet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Outlet Login Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
              ),
              SizedBox(width: 6),
              Text('🔐', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 6),

          const Text(
            'Check if the merchant has completed mandatory 2FA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: accentIndigo.withValues(alpha: 0.3),
              ),
              onPressed: _handleCheckLoginStatus,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: darkButtonGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Check Login Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card 4: Merchant Biometric KYC (AEPS Card - Screenshot 3) ───────────
  Widget _buildMerchantBiometricKycCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Merchant Biometric KYC',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect biometric device & capture fingerprint',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: accentIndigo.withValues(alpha: 0.3),
              ),
              onPressed: _handleCheckDevice,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: darkButtonGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.power_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Check Device Connection',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_deviceConnected) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biometric Device Connected Successfully.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
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
}
