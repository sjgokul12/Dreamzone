import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../admin/admin_login_screen.dart';
import 'settings_screen.dart';
import 'my_applications_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _allApplications = [];
  Map<String, dynamic>? _savedDetails;
  // Theme Palette
  static const Color primaryOrange = Color(0xFF8B5CF6);
  static const Color deepOrange = Color(0xFF9333EA);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color accentGold = Color(0xFFFF6B00);
  Color get bgCream => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF8FAFC);
  Color get textDark => Provider.of<AuthProvider>(context).isDarkMode ? Colors.white : const Color(0xFF1A0D08);
  Color get textMedium => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[300]! : const Color(0xFF5D4037);
  Color get textLight => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[400]! : const Color(0xFF8D6E63);
  Color get softOrange => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0F2F1);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadApplications(),
      _loadSavedDetails(),
    ]);
  }

  Future<void> _loadApplications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn && auth.userId != null) {
      final result = await _api.getUserAllApplications(auth.userId!);
      if (result['success'] == true && mounted) {
        setState(() {
          _allApplications = List<Map<String, dynamic>>.from(
            result['applications'] ?? [],
          );
        });
      }
    }
  }

  Future<void> _loadSavedDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) return;
    final result = await _api.getUserSavedDetails(auth.userId!);
    if (mounted && result['success'] == true) {
      setState(() {
        _savedDetails = result['details'];
      });
    }
  }

  void _showEditDetailsDialog() {
    final nameCtrl = TextEditingController(
      text: _savedDetails?['full_name'] ?? '',
    );
    final fatherCtrl = TextEditingController(
      text: _savedDetails?['father_name'] ?? '',
    );
    final motherCtrl = TextEditingController(
      text: _savedDetails?['mother_name'] ?? '',
    );
    final dobCtrl = TextEditingController(
      text: _savedDetails?['dob']?.toString() ?? '',
    );
    String gender = _savedDetails?['gender'] ?? 'Male';
    final aadhaarCtrl = TextEditingController(
      text: _savedDetails?['aadhaar_number'] ?? '',
    );
    final panCtrl = TextEditingController(
      text: _savedDetails?['pan_number'] ?? '',
    );
    final addr1Ctrl = TextEditingController(
      text: _savedDetails?['address_line1'] ?? '',
    );
    final addr2Ctrl = TextEditingController(
      text: _savedDetails?['address_line2'] ?? '',
    );
    final cityCtrl = TextEditingController(text: _savedDetails?['city'] ?? '');
    final stateCtrl = TextEditingController(
      text: _savedDetails?['state'] ?? '',
    );
    final pinCtrl = TextEditingController(
      text: _savedDetails?['pincode'] ?? '',
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryOrange.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: primaryOrange,
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Edit Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSectionLabel('Personal Information'),
                        SizedBox(height: 10),
                        _buildDialogField(nameCtrl, 'Full Name', Icons.person),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogField(
                                fatherCtrl,
                                'Father Name',
                                Icons.person_outline,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildDialogField(
                                motherCtrl,
                                'Mother Name',
                                Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dobCtrl,
                                readOnly: true,
                                decoration: _dialogInputDecoration(
                                  'Date of Birth',
                                  Icons.calendar_today,
                                ),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime(1990),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) {
                                    setDialogState(() {
                                      dobCtrl.text =
                                          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: gender,
                                decoration: _dialogInputDecoration(
                                  'Gender',
                                  Icons.people,
                                ),
                                items: ['Male', 'Female', 'Other']
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setDialogState(() => gender = v ?? 'Male'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildSectionLabel('Identity Details'),
                        SizedBox(height: 10),
                        _buildDialogField(
                          aadhaarCtrl,
                          'Aadhaar Number',
                          Icons.fingerprint,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                        ),
                        SizedBox(height: 10),
                        _buildDialogField(
                          panCtrl,
                          'PAN Number',
                          Icons.credit_card,
                          maxLength: 10,
                        ),
                        SizedBox(height: 16),
                        _buildSectionLabel('Address'),
                        SizedBox(height: 10),
                        _buildDialogField(
                          addr1Ctrl,
                          'Address Line 1',
                          Icons.home,
                        ),
                        SizedBox(height: 10),
                        _buildDialogField(
                          addr2Ctrl,
                          'Address Line 2',
                          Icons.home_outlined,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogField(
                                cityCtrl,
                                'City',
                                Icons.location_city,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildDialogField(
                                stateCtrl,
                                'State',
                                Icons.map,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildDialogField(
                          pinCtrl,
                          'Pincode',
                          Icons.pin,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMedium,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                if (auth.userId == null) return;
                                setDialogState(() => saving = true);
                                await _api.saveUserDetails(auth.userId!, {
                                  'full_name': nameCtrl.text,
                                  'father_name': fatherCtrl.text,
                                  'mother_name': motherCtrl.text,
                                  'dob': dobCtrl.text,
                                  'gender': gender,
                                  'aadhaar_number': aadhaarCtrl.text,
                                  'pan_number': panCtrl.text,
                                  'address_line1': addr1Ctrl.text,
                                  'address_line2': addr2Ctrl.text,
                                  'city': cityCtrl.text,
                                  'state': stateCtrl.text,
                                  'pincode': pinCtrl.text,
                                });
                                setDialogState(() => saving = false);
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadSavedDetails();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Details saved successfully!',
                                      ),
                                      backgroundColor: successGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: softOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: primaryOrange),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: _dialogInputDecoration(label, icon),
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textLight, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryOrange, size: 18),
      filled: true,
      fillColor: bgCream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      counterText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = !auth.isLoggedIn;
    final userEmail = auth.userEmail ?? '';
    final isAdmin = userEmail == 'dreamzone.infinity@gmail.com';
    final userName = isGuest ? 'Guest User' : (auth.userName?.isNotEmpty == true ? auth.userName! : 'User');
    final userMobile = isGuest ? '9677962941' : (auth.userMobile?.isNotEmpty == true ? auth.userMobile! : '9677962941');
    final userEmailDisplay = isGuest ? 'guest@dziinfinity.com' : (auth.userEmail?.isNotEmpty == true ? auth.userEmail! : 'user@dziinfinity.com');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          backgroundColor: Colors.white,
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. Top Header Row (Title, Subtitle & Settings Icon) ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your account and\ntrack your activity 👏',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                    // Settings Button
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, b) => const SettingsScreen(),
                          transitionsBuilder: (_, animation, _, child) => SlideTransition(
                            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                            ),
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── 2. Main Profile Card (Template Matching) ─────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gradient Avatar with Camera Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF), Color(0xFFEC4899)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // User Info Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.mail_outline_rounded,
                                      size: 14,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        userEmailDisplay,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    const Text(
                                      'User ID',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            userMobile,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: userMobile));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('User ID copied to clipboard'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            child: const Icon(
                                              Icons.copy_rounded,
                                              size: 13,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Edit Profile & QR Code Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: isGuest
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      )
                                  : _showEditProfileDialog,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.edit_note_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isGuest ? 'Login / Register' : 'Edit Profile',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // QR Code Icon Container
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('DZI QR Code Scanner')),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF7C3AED),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── 3. Three Stat Cards (Total, Completed, Active) ────────
                _buildStatsRow(),

                const SizedBox(height: 22),

                // ─── 4. My Details Section ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF7C3AED),
                          size: 21,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My Details',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    if (!isGuest)
                      InkWell(
                        onTap: _showEditDetailsDialog,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF7C3AED),
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // My Details Content Card
                _buildDetailsCard(userName, userEmailDisplay, userMobile),

                const SizedBox(height: 18),

                // ─── 5. Unlock More Features Banner ───────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 3D Diamond Gem Icon Container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Unlock More Features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Explore premium services and get the most out of our platform.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 6. Quick Action Navigation Cards ──────────────────────
                _buildMenuSection(isGuest),

                // ─── 7. Admin Portal Card (If Admin) ───────────────────────
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  _buildAdminCard(),
                ],

                // ─── 8. Logout Button ──────────────────────────────────────
                if (!isGuest) ...[
                  const SizedBox(height: 16),
                  _buildLogoutButton(auth),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== THREE STAT CARDS ====================
  Widget _buildStatsRow() {
    final done = _allApplications
        .where(
          (a) =>
              a['status'] == 'completed' ||
              a['status'] == 'approved' ||
              a['status'] == 'selected',
        )
        .length;
    final active = _allApplications
        .where(
          (a) =>
              a['status'] != 'completed' &&
              a['status'] != 'approved' &&
              a['status'] != 'selected' &&
              a['status'] != 'rejected',
        )
        .length;

    return Row(
      children: [
        _statCard(
          '${_allApplications.length}',
          'Total',
          'All Services',
          Icons.assignment_outlined,
          const Color(0xFF7C3AED),
          const Color(0xFFF3E8FF),
        ),
        const SizedBox(width: 10),
        _statCard(
          '$done',
          'Completed',
          'Successfully done',
          Icons.verified_outlined,
          const Color(0xFF10B981),
          const Color(0xFFDCFCE7),
        ),
        const SizedBox(width: 10),
        _statCard(
          '$active',
          'Active',
          'In progress',
          Icons.calendar_today_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
        ),
      ],
    );
  }

  Widget _statCard(
    String value,
    String label,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MY DETAILS CARD ====================
  Widget _buildDetailsCard(String name, String email, String mobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _detailItemRow(
            Icons.person_outline_rounded,
            'Full Name',
            _savedDetails?['full_name']?.toString() ?? name,
          ),
          const Divider(color: Color(0xFFF8FAFC), height: 16),
          _detailItemRow(
            Icons.mail_outline_rounded,
            'Email Address',
            email,
          ),
          const Divider(color: Color(0xFFF8FAFC), height: 16),
          _detailItemRow(
            Icons.badge_outlined,
            'User ID',
            mobile,
            isCopyable: true,
          ),
          const Divider(color: Color(0xFFF8FAFC), height: 16),
          _detailItemRow(
            Icons.calendar_today_outlined,
            'Member Since',
            'May 2025',
          ),
          if (_savedDetails != null && _savedDetails!['address_line1']?.toString().isNotEmpty == true) ...[
            const Divider(color: Color(0xFFF8FAFC), height: 16),
            _detailItemRow(
              Icons.home_outlined,
              'Address',
              '${_savedDetails!['address_line1']}, ${_savedDetails!['city'] ?? ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItemRow(IconData icon, String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF7C3AED)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryOrange.withAlpha(20),
            accentGold.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryOrange.withAlpha(60), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryOrange, deepOrange],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: const Text(
          'Manage services, users & applications',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryOrange, deepOrange],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, b) => const AdminLoginScreen(),
            transitionsBuilder: (_, animation, _, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(bool isGuest) {
    return Column(
      children: [
        _menuItem(
          icon: Icons.receipt_long_outlined,
          title: 'My Applications',
          subtitle: '${_allApplications.length} submitted applications',
          onTap: () {
            if (isGuest) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login first')),
              );
              return;
            }
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const MyApplicationsScreen(),
                transitionsBuilder: (_, animation, _, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
        ),
        _menuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Account & app preferences',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const SettingsScreen(),
              transitionsBuilder: (_, animation, _, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        _menuItem(
          icon: Icons.headset_mic_outlined,
          title: '24/7 Customer Support',
          subtitle: 'Instant help, FAQs & tickets',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const HelpSupportScreen(),
              transitionsBuilder: (_, animation, _, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        _menuItem(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin Login',
          subtitle: 'Access the admin dashboard',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const AdminLoginScreen(),
              transitionsBuilder: (_, animation, _, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        _menuItem(
          icon: Icons.info_outline_rounded,
          title: 'About DZI Infinity',
          subtitle: 'Version 1.0.0',
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const AboutScreen(),
              transitionsBuilder: (_, animation, _, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          auth.logout();
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const LoginScreen(),
              transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, color: dangerRed, size: 18),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: dangerRed,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: auth.userName ?? '');
    final mobileCtrl = TextEditingController(text: auth.userMobile ?? '');
    final emailCtrl = TextEditingController(text: auth.userEmail ?? '');
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryOrange.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.edit, color: primaryOrange, size: 26),
                ),
                SizedBox(height: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 20),
                _buildDialogField(nameCtrl, 'Name', Icons.person),
                SizedBox(height: 12),
                _buildDialogField(
                  mobileCtrl,
                  'Mobile',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                SizedBox(height: 12),
                _buildDialogField(
                  emailCtrl,
                  'Email',
                  Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMedium,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setDialogState(() => loading = true);
                                final result = await auth.updateProfile(
                                  nameCtrl.text.trim(),
                                  mobileCtrl.text.trim(),
                                  emailCtrl.text.trim(),
                                );
                                setDialogState(() => loading = false);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ?? 'Updated',
                                      ),
                                      backgroundColor: result['success'] == true
                                          ? successGreen
                                          : dangerRed,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
