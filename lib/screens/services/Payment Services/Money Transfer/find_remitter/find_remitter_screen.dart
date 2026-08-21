import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/money_transfer_service.dart';
import '../remitter_registration/remitter_registration_screen.dart';
import '../Main Money Transfer.dart';

class FindRemitterScreen extends StatefulWidget {
  const FindRemitterScreen({super.key});

  @override
  State<FindRemitterScreen> createState() => _FindRemitterScreenState();
}

class _FindRemitterScreenState extends State<FindRemitterScreen> {
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color bgSoft = Color(0xFFF4F6FA);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderCol = Color(0xFFE2E8F0);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  final TextEditingController _findMobileCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showRegistrationCard = false;
  String _searchedMobile = '';
  String _referenceKey = '';

  // Local cache of registered remitters in current session
  final Set<String> _registeredMobiles = {};

  @override
  void dispose() {
    _findMobileCtrl.dispose();
    super.dispose();
  }

  // ─── Search Remitter ──────────────────────────────────────────────────────
  Future<void> _handleSearchRemitter() async {
    FocusScope.of(context).unfocus();
    final mobile = _findMobileCtrl.text.trim();

    if (mobile.length != 10) {
      _showToast('Please enter a valid 10-digit Mobile Number', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _searchedMobile = mobile;
    });

    // Call Live API
    final response = await MoneyTransferService.fetchRemitterProfile(mobile);

    setState(() => _isLoading = false);

    if (response['statuscode'] == 'TXN' && response['data'] != null) {
      // Registered Remitter Found -> Directly open Main Money Transfer Screen
      final data = response['data'] as Map<String, dynamic>;
      final benList = (data['beneficiaries'] as List?)?.map((b) => Map<String, dynamic>.from(b)).toList() ?? [];

      setState(() => _showRegistrationCard = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainMoneyTransferScreen(
              remitterData: data,
              initialBeneficiaries: benList,
              referenceKey: (data['referenceKey'] ?? '').toString(),
            ),
          ),
        );
      }
    } else if (_registeredMobiles.contains(mobile)) {
      // Just registered in this session -> Open Main Money Transfer Screen
      setState(() => _showRegistrationCard = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainMoneyTransferScreen(
              remitterData: {
                'firstName': 'P',
                'lastName': 'KRISHNAN',
                'mobileNumber': mobile,
                'limitTotal': '25000.00',
                'limitAvailable': '25000.00',
              },
            ),
          ),
        );
      }
    } else {
      // Remitter Not Found -> Show Remitter Registration Card below Find Remitter
      _referenceKey = (response['data']?['referenceKey'] ?? response['referenceKey'] ?? '').toString();
      setState(() {
        _showRegistrationCard = true;
      });
      _showToast(response['status'] ?? 'Remitter not registered. Please register below.', isError: false);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? dangerRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Money Transfer',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildFindRemitterCard(),
              if (_showRegistrationCard) ...[
                const SizedBox(height: 20),
                RemitterRegistrationCard(
                  initialMobile: _searchedMobile,
                  referenceKey: _referenceKey,
                  onRegistrationSuccess: () {
                    // Registration Success -> Record mobile, hide registration card, show Find Remitter card
                    setState(() {
                      _registeredMobiles.add(_searchedMobile);
                      _showRegistrationCard = false;
                      _findMobileCtrl.text = _searchedMobile;
                    });
                    _showToast('🎉 Remitter Registered Successfully! Tap "Search Remitter" to open.');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindRemitterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
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
                  color: primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_search_rounded, color: primaryPurple, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find Remitter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                    Text('Enter 10-digit mobile number to search', style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _findMobileCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark, letterSpacing: 1),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter Mobile Number',
              hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: primaryPurple),
              filled: true,
              fillColor: const Color(0xFFFAFAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                backgroundColor: primaryPurple,
                elevation: 4,
                shadowColor: primaryPurple.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _handleSearchRemitter,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Search Remitter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
