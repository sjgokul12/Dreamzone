import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoneyTransferScreen extends StatefulWidget {
  const MoneyTransferScreen({super.key});

  @override
  State<MoneyTransferScreen> createState() => _MoneyTransferScreenState();
}

class _MoneyTransferScreenState extends State<MoneyTransferScreen> {
  // App UI Teal Theme Palette
  static const Color primaryTeal = Color(0xFF00A896);
  static const Color accentTeal = Color(0xFF028090);
  static const Color lightTealBg = Color(0xFFE0F2F1);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color inputBg = Color(0xFFF8FAFC);

  // App UI Button Gradient
  static const LinearGradient tealBtnGradient = LinearGradient(
    colors: [primaryTeal, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _formKey = GlobalKey<FormState>();

  // Flow Flags
  bool _isMobileSearched = false;
  bool _isOtpVerified = false;
  bool _deviceConnected = false;

  // Controllers
  final TextEditingController _findMobileCtrl = TextEditingController();
  final TextEditingController _regMobileCtrl = TextEditingController();
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
      _isOtpVerified = false; // Reset so eKYC is hidden!
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

    // Launch Teal-Themed OTP Popup Dialog
    _showOtpPopupDialog();
  }

  /// Responsive App UI Teal-Themed OTP Popup Dialog (100% Overflow Free)
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
                border: Border.all(color: primaryTeal.withValues(alpha: 0.3), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F00A896),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(dialogContext),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightTealBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: primaryTeal, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone + Teal Shield Illustration
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 82,
                        decoration: BoxDecoration(
                          color: lightTealBg.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryTeal, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.1),
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
                                color: primaryTeal.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryTeal,
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
                            border: Border.all(color: primaryTeal, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_outlined, color: primaryTeal, size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title: Verify Code
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

                  // Subtitle
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

                  // Dynamic Overflow-Proof 6-Digit OTP Box Row
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
                            color: lightTealBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryTeal.withValues(alpha: 0.5),
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

                  // Underlined Resend Code Link (Teal Theme)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('A new verification code has been sent.'),
                          backgroundColor: primaryTeal,
                        ),
                      );
                    },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // VERIFY CODE Button with App UI Teal Gradient
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: tealBtnGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // 1st: Close OTP Popup
                          setState(() {
                            _isOtpVerified = true; // 2nd: Reveal Remitter eKYC card below!
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP Verified Successfully! Loading Remitter eKYC...'),
                              backgroundColor: primaryTeal,
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

  void _handleCheckDevice() {
    setState(() {
      _deviceConnected = !_deviceConnected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _deviceConnected ? 'Device connected successfully!' : 'Device disconnected.',
        ),
        backgroundColor: _deviceConnected ? primaryTeal : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final cardPadding = media.size.width < 380 ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Column(
                  children: [
                    // Top Teal Wave Header
                    _buildTealHeader(media),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.size.width < 360 ? 12.0 : 18.0,
                        vertical: 20.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 1. Find Remitter Card (Always Visible at Top)
                            _buildFindRemitterCard(cardPadding),

                            // 2. Remitter Registration Card (Revealed Below after searching Mobile Number)
                            if (_isMobileSearched) ...[
                              const SizedBox(height: 20),
                              _buildRegisterRemitterCard(cardPadding),
                            ],

                            // 3. Remitter eKYC Card (ONLY Revealed Below after OTP Verification in Popup)
                            if (_isOtpVerified) ...[
                              const SizedBox(height: 20),
                              _buildEkycCard(cardPadding),
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Teal Header matching App UI Theme
  Widget _buildTealHeader(MediaQueryData media) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: media.padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, accentTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300A896),
            blurRadius: 20,
            offset: Offset(0, 8),
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
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/Money Transfer.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PAYMENT SERVICES',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Money Transfer',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Domestic Money Transfer & Remitter Portal',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Card 1: Find Remitter Card (Always Visible at Top)
  Widget _buildFindRemitterCard(double cardPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: primaryTeal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),

          // Header Icon & Title
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryTeal, accentTeal],
                  ).createShader(bounds),
                  child: const Text(
                    'Find Remitter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Enter the mobile number to fetch remitter details',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),

          // Mobile Number Input Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _findMobileCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter Mobile Number',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  fillColor: lightTealBg.withValues(alpha: 0.5),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryTeal, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Remitter Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: tealBtnGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleSearchRemitter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Search Remitter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
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

  /// Card 2: Remitter Registration Card (Revealed Below after searching Mobile Number - 100% Responsive)
  Widget _buildRegisterRemitterCard(double cardPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: primaryTeal.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryTeal, accentTeal],
                  ).createShader(bounds),
                  child: const Text(
                    'Remitter Registration',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete registration to activate money transfer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Mobile Number Field (Pre-filled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _regMobileCtrl,
                keyboardType: TextInputType.phone,
                readOnly: true,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                decoration: InputDecoration(
                  fillColor: lightTealBg.withValues(alpha: 0.6),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  suffixIcon: const Icon(Icons.check_circle_rounded, color: primaryTeal, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Aadhaar Number Field
              const Text(
                'Aadhaar Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _regAadhaarCtrl,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 12 digit Aadhaar number',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  fillColor: inputBg,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryTeal, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Register Remitter Button (Triggers OTP Popup - Overflow Free)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: tealBtnGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleRegisterRemitter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Register Remitter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
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

  /// Card 3: Remitter eKYC Card (ONLY Revealed BELOW after OTP Verification - 100% Overflow Free)
  Widget _buildEkycCard(double cardPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: primaryTeal.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),

          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Remitter eKYC',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            'Connect biometric device & capture fingerprint',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Mobile Number Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ekycMobileCtrl,
                readOnly: true,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                decoration: InputDecoration(
                  fillColor: lightTealBg.withValues(alpha: 0.6),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Check Device Connection Button (100% Overflow Free with FittedBox)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: tealBtnGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleCheckDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Check Device Connection',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Device Connection Status Alert Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _deviceConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _deviceConnected ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _deviceConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _deviceConnected ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _deviceConnected
                        ? 'Biometric Device Connected Successfully.'
                        : '❌ Device Not Detected. Please connect the device.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _deviceConnected ? const Color(0xFF166534) : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
