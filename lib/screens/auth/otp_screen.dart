import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isRegistration;
  const OtpScreen({super.key, required this.email, this.isRegistration = false});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

void _verifyOtp() async {
    if (_otpController.text.length != 6) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // isRegistration true -> verify the registration OTP.
    // isRegistration false -> this screen was being misused to call
    // login() with the OTP as a "password", which is wrong. If this
    // screen is ever reused for a forgot-password flow, it should call
    // a dedicated resetPassword/verify method instead — not login().
    if (!widget.isRegistration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This screen only supports registration OTP verification.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final result = await auth.verifyRegisterOtp(widget.email, _otpController.text.trim());
    if (result['success'] == true && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen(isGuest: false)), (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Invalid OTP'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.mark_email_read, size: 80, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16),
        const Text('Enter OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        Text('Sent to ${widget.email}', style: TextStyle(color: Colors.grey[600])), const SizedBox(height: 28),
        TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 8), decoration: InputDecoration(hintText: '000000', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      ]))),
    );
  }
}