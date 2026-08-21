import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/money_transfer_service.dart';

class RemitterRegistrationCard extends StatefulWidget {
  final String initialMobile;
  final String referenceKey;
  final VoidCallback onRegistrationSuccess;

  const RemitterRegistrationCard({
    super.key,
    required this.initialMobile,
    this.referenceKey = '',
    required this.onRegistrationSuccess,
  });

  @override
  State<RemitterRegistrationCard> createState() => _RemitterRegistrationCardState();
}

class _RemitterRegistrationCardState extends State<RemitterRegistrationCard> {
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderCol = Color(0xFFE2E8F0);
  static const Color dangerRed = Color(0xFFEF4444);

  late final TextEditingController _regMobileCtrl;
  final TextEditingController _regAadhaarCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _regMobileCtrl = TextEditingController(text: widget.initialMobile);
  }

  @override
  void didUpdateWidget(covariant RemitterRegistrationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMobile != widget.initialMobile) {
      _regMobileCtrl.text = widget.initialMobile;
    }
  }

  @override
  void dispose() {
    _regMobileCtrl.dispose();
    _regAadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    final mobile = _regMobileCtrl.text.trim();
    final aadhaar = _regAadhaarCtrl.text.trim();

    if (mobile.length != 10) {
      _showToast('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }
    if (aadhaar.length != 12) {
      _showToast('Please enter a valid 12-digit Aadhaar Number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final res = await MoneyTransferService.registerRemitter(
      mobileNumber: mobile,
      encryptedAadhaar: aadhaar,
      referenceKey: widget.referenceKey,
    );

    setState(() => _isLoading = false);

    final refKey = (res['data']?['referenceKey'] ?? res['data']?['otpReference'] ?? widget.referenceKey).toString();
    _showOtpDialog(
      title: 'Remitter Registration OTP',
      subtitle: 'Enter OTP sent to +91 $mobile',
      onVerify: (otp) async {
        _showLoadingOverlay();
        final verifyRes = await MoneyTransferService.verifyRemitterRegistration(
          mobileNumber: mobile,
          otp: otp,
          referenceKey: refKey,
        );
        _hideLoadingOverlay();
        if (verifyRes['statuscode'] == 'TXN' || verifyRes['status'] == 'Success' || verifyRes['status'] == 'Transaction Successful') {
          widget.onRegistrationSuccess();
        } else {
          _showToast(verifyRes['status'] ?? 'OTP verification failed', isError: true);
        }
      },
    );
  }

  void _showOtpDialog({
    required String title,
    required String subtitle,
    required Function(String otp) onVerify,
  }) {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: primaryPurple, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: textMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 6),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        final otp = otpCtrl.text.trim();
                        if (otp.length < 4) {
                          _showToast('Please enter valid OTP', isError: true);
                          return;
                        }
                        Navigator.pop(ctx);
                        onVerify(otp);
                      },
                      child: const Text('VERIFY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? dangerRed : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: primaryPurple),
      ),
    );
  }

  void _hideLoadingOverlay() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remitter Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text('Enter Aadhaar number to register', style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _regMobileCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: primaryPurple),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Aadhaar Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _regAadhaarCtrl,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter 12-digit Aadhaar Number',
              hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8), letterSpacing: 0),
              filled: true,
              fillColor: const Color(0xFFFAFAFC),
              prefixIcon: const Icon(Icons.fingerprint_rounded, color: primaryPurple),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                elevation: 4,
                shadowColor: const Color(0xFFD97706).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
