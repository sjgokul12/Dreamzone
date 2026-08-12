import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _step = 1;
  bool _loading = false;
  String? _errorMsg;

  void _sendOtp() async {
    if (_emailController.text.isEmpty) return;
    setState(() { _loading = true; _errorMsg = null; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.forgotPassword(_emailController.text.trim());
    setState(() => _loading = false);
    if (result['success'] == true) {
      setState(() => _step = 2);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent! Check backend terminal'), backgroundColor: Colors.green));
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _step = 3);
  }

  void _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) { setState(() => _errorMsg = 'Passwords do not match'); return; }
    if (_newPasswordController.text.length < 6) { setState(() => _errorMsg = 'Min 6 characters'); return; }
    setState(() { _loading = true; _errorMsg = null; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.resetPassword(_emailController.text.trim(), _otpController.text.trim(), _newPasswordController.text.trim());
    setState(() => _loading = false);
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset! Please login'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        Icon(Icons.lock_reset, size: 80, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16),
        if (_errorMsg != null) Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Text(_errorMsg!, style: const TextStyle(color: Colors.red))),
        if (_step == 1) ...[
          const Text('Enter your email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _loading ? null : _sendOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
        if (_step == 2) ...[
          const Text('Enter OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
          TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, letterSpacing: 6), decoration: InputDecoration(hintText: '000000', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
        if (_step == 3) ...[
          const Text('Set New Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
          TextField(controller: _newPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 14),
          TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _loading ? null : _resetPassword, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ]))),
    );
  }
}