import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _allApplications = [];
  bool _loadingApps = true;

  Map<String, dynamic>? _savedDetails;
  bool _loadingDetails = false;

  List<dynamic> _userDocuments = [];
  bool _loadingDocs = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Money Transfer Reference Teal & Orange Theme Palette
  static const Color primaryOrange = Color(0xFF8B5CF6);
  static const Color deepOrange = Color(0xFF9333EA);
  static const Color warmBrown = Color(0xFF8B5CF6);
  static const Color lightBrown = Color(0xFFC084FC);
  Color get bgCream => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF8FAFC);
  Color get cardWhite => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get textDark => Provider.of<AuthProvider>(context).isDarkMode ? Colors.white : const Color(0xFF1A0D08);
  Color get textMedium => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[300]! : const Color(0xFF5D4037);
  Color get textLight => Provider.of<AuthProvider>(context).isDarkMode ? Colors.grey[400]! : const Color(0xFF8D6E63);
  static const Color accentGold = Color(0xFFFF6B00);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color dangerRed = Color(0xFFE74C3C);
  Color get softOrange => Provider.of<AuthProvider>(context).isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0F2F1);
  static const Color infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadApplications(),
      _loadSavedDetails(),
      _loadUserDocuments(),
    ]);
  }

  Future<void> _loadApplications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn && auth.userId != null) {
      final result = await _api.getUserAllApplications(auth.userId!);
      if (result['success'] == true && mounted) {
        setState(() {
          _allApplications = List<Map<String, dynamic>>.from(
            result['applications'],
          );
          _loadingApps = false;
        });
      } else {
        if (mounted) setState(() => _loadingApps = false);
      }
    } else {
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  Future<void> _loadSavedDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      setState(() => _loadingDetails = false);
      return;
    }
    setState(() => _loadingDetails = true);
    final result = await _api.getUserSavedDetails(auth.userId!);
    if (mounted) {
      setState(() {
        _savedDetails = result['details'];
        _loadingDetails = false;
      });
    }
  }

  Future<void> _loadUserDocuments() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      setState(() => _loadingDocs = false);
      return;
    }
    setState(() => _loadingDocs = true);
    final result = await _api.getUserDocuments(auth.userId!);
    if (mounted) {
      setState(() {
        _userDocuments = result['documents'] ?? [];
        _loadingDocs = false;
      });
    }
  }

  Future<void> _viewDocument(String filePath, String fileName) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final viewUrl = '${ApiService.baseUrl}/admin/view-file/$encodedPath';
      final uri = Uri.parse(viewUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open file'),
              backgroundColor: dangerRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _downloadDocument(String filePath, String fileName) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $fileName...'),
            backgroundColor: infoBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      final encodedPath = Uri.encodeComponent(filePath);
      final downloadUrl =
          '${ApiService.baseUrl}/admin/download-file/$encodedPath';
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download started: $fileName'),
              backgroundColor: successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.bytes != null) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.userId == null) return;

        final uploadResult = await _api.uploadUserDocument(
          auth.userId!,
          docType,
          result.files.first.bytes!,
          result.files.first.name,
        );
        if (mounted) {
          if (uploadResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_getDocTypeLabel(docType)} uploaded'),
                backgroundColor: successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            _loadUserDocuments();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadResult['message'] ?? 'Upload failed'),
                backgroundColor: dangerRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed'),
            backgroundColor: dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(int docId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) return;
    await _api.deleteUserDocument(auth.userId!, docId);
    _loadUserDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document deleted'),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _getDocTypeLabel(String type) {
    switch (type) {
      case 'aadhaar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'photo':
        return 'Passport Photo';
      case 'signature':
        return 'Signature';
      case 'bank':
        return 'Bank Proof';
      case 'address':
        return 'Address Proof';
      default:
        return type;
    }
  }

  IconData _getDocTypeIcon(String type) {
    switch (type) {
      case 'aadhaar':
        return Icons.fingerprint;
      case 'pan':
        return Icons.credit_card;
      case 'photo':
        return Icons.photo;
      case 'signature':
        return Icons.draw;
      case 'bank':
        return Icons.account_balance;
      case 'address':
        return Icons.home;
      default:
        return Icons.description;
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

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final docType = doc['doc_type'] ?? '';
    final docName = doc['doc_name'] ?? doc['file_name'] ?? 'Unknown';
    final filePath = doc['file_path'] ?? '';
    final isImage =
        docName.endsWith('.jpg') ||
        docName.endsWith('.jpeg') ||
        docName.endsWith('.png');
    final isPdf = docName.endsWith('.pdf');

    IconData icon = _getDocTypeIcon(docType);
    Color color = primaryOrange;

    if (isPdf) {
      icon = Icons.picture_as_pdf;
      color = dangerRed;
    } else if (isImage) {
      icon = Icons.image;
      color = successGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDocTypeLabel(docType),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                Text(
                  docName,
                  style: TextStyle(fontSize: 11, color: textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (filePath.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                size: 20,
                color: infoBlue,
              ),
              onPressed: () => _viewDocument(filePath, docName),
              tooltip: 'View',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: Icon(
                Icons.download_outlined,
                size: 20,
                color: successGreen,
              ),
              onPressed: () => _downloadDocument(filePath, docName),
              tooltip: 'Download',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: dangerRed,
              ),
              onPressed: () => _deleteDocument(doc['id']),
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ],
      ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fallback
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          'Profile',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textDark),
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const SettingsScreen(),
                transitionsBuilder: (_, animation, _, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEFCF8), Color(0xFFF3F0FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
            color: primaryOrange,
            backgroundColor: cardWhite,
            onRefresh: _loadAllData,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // Profile Header
                  _buildProfileHeader(auth, isGuest),

                  // Stats
                  if (!isGuest) ...[
                    SizedBox(height: 20),
                    _buildStatsRow(),
                  ],

                  SizedBox(height: 24),

                  // My Details Section
                  if (!isGuest) ...[
                    _buildSectionHeader(
                      'My Details',
                      Icons.person_outline,
                      onEdit: _showEditDetailsDialog,
                    ),
                    _buildDetailsCard(),
                    SizedBox(height: 16),

                  ],

                  // Admin Panel
                  if (isAdmin) ...[
                    _buildAdminCard(),
                    SizedBox(height: 16),
                  ],

                  // Menu Items
                  _buildMenuSection(isGuest),
                  SizedBox(height: 16),

                  // Logout
                  if (!isGuest) _buildLogoutButton(auth),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProfileHeader(auth, bool isGuest) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFFF8FAFC),
              child: Text(
                isGuest ? 'G' : (auth.userName?.isNotEmpty == true ? auth.userName![0].toUpperCase() : 'U'),
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            isGuest ? 'Guest User' : (auth.userName ?? 'User'),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 4),
          Text(
            isGuest ? 'Sign in to access features' : (auth.userEmail ?? ''),
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (!isGuest) ...[
            SizedBox(height: 4),
            Text(
              'User · ${auth.userMobile ?? ''}',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showEditProfileDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
          if (isGuest) ...[
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a, b) => const LoginScreen(),
                  transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Login / Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(
            '${_allApplications.length}',
            'Total',
            Icons.receipt_long_outlined,
            primaryOrange,
          ),
          SizedBox(width: 10),
          _statCard(
            '$done',
            'Completed',
            Icons.check_circle_outline,
            successGreen,
          ),
          SizedBox(width: 10),
          _statCard('$active', 'Active', Icons.pending_actions, accentGold),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, child) {
          return Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animValue)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withAlpha(40), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    SizedBox(height: 10),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _loadingDetails
          ? Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: primaryOrange),
              ),
            )
          : _savedDetails == null || _savedDetails!.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
                  SizedBox(height: 12),
                  Text(
                    'No details saved yet',
                    style: TextStyle(color: textLight),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showEditDetailsDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Your Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  if (_savedDetails!['full_name']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.person,
                      'Full Name',
                      _savedDetails!['full_name'].toString(),
                    ),
                  if (_savedDetails!['father_name']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.person_outline,
                      'Father',
                      _savedDetails!['father_name'].toString(),
                    ),
                  if (_savedDetails!['mother_name']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.person_outline,
                      'Mother',
                      _savedDetails!['mother_name'].toString(),
                    ),
                  if (_savedDetails!['dob']?.toString().isNotEmpty == true)
                    _detailRow(
                      Icons.calendar_today,
                      'Date of Birth',
                      _savedDetails!['dob'].toString(),
                    ),
                  if (_savedDetails!['gender']?.toString().isNotEmpty == true)
                    _detailRow(
                      Icons.people,
                      'Gender',
                      _savedDetails!['gender'].toString(),
                    ),
                  if (_savedDetails!['aadhaar_number']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.fingerprint,
                      'Aadhaar',
                      _savedDetails!['aadhaar_number'].toString(),
                    ),
                  if (_savedDetails!['pan_number']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.credit_card,
                      'PAN',
                      _savedDetails!['pan_number'].toString(),
                    ),
                  if (_savedDetails!['address_line1']?.toString().isNotEmpty ==
                      true)
                    _detailRow(
                      Icons.home,
                      'Address',
                      '${_savedDetails!['address_line1']}${_savedDetails!['address_line2']?.toString().isNotEmpty == true ? ', ${_savedDetails!['address_line2']}' : ''}, ${_savedDetails!['city'] ?? ''}, ${_savedDetails!['state'] ?? ''} - ${_savedDetails!['pincode'] ?? ''}',
                    ),
                  SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                           setState(() {
                             _savedDetails = null;
                           });
                        },
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: dangerRed),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showEditDetailsDialog,
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Edit Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _docUploadTile('aadhaar', 'Aadhaar'),
              _docUploadTile('pan', 'PAN Card'),
              _docUploadTile('photo', 'Photo'),
              _docUploadTile('signature', 'Signature'),
              _docUploadTile('bank', 'Bank Proof'),
              _docUploadTile('address', 'Address'),
            ],
          ),
          if (_userDocuments.isNotEmpty) ...[
            SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            ..._userDocuments.map(
              (doc) => _buildDocumentTile(doc as Map<String, dynamic>),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryOrange.withAlpha(20),
            accentGold.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryOrange.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryOrange, deepOrange],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 26,
          ),
        ),
        title: Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: textDark,
          ),
        ),
        subtitle: Text(
          'Manage services, users & applications',
          style: TextStyle(fontSize: 12, color: textMedium),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryOrange, deepOrange],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 10,
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
            transitionsBuilder: (_, animation, _, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(bool isGuest) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.receipt_long_outlined,
            title: 'My Applications',
            subtitle: '${_allApplications.length} applications',
            onTap: () {
              if (isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please login first'),
                    backgroundColor: primaryOrange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a, b) => const MyApplicationsScreen(),
                  transitionsBuilder: (_, animation, _, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
            subtitle: 'App preferences',
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const SettingsScreen(),
                transitionsBuilder: (_, animation, _, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
          _menuItem(
            icon: Icons.info_outline,
            title: 'About DZI Infinity',
            subtitle: 'Version 1.0.0',
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const AboutScreen(),
                transitionsBuilder: (_, animation, _, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
        onTap: onTap,
      ),
    );
  }

  Widget _menuDivider() {
    return SizedBox(height: 0);
  }

  Widget _buildLogoutButton(auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            auth.logout();
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, b) => const LoginScreen(),
                transitionsBuilder: (_, animation, _, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
              (route) => false,
            );
          },
          icon: Icon(Icons.logout_rounded, color: dangerRed, size: 20),
          label: Text(
            'Logout',
            style: TextStyle(
              color: dangerRed,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: dangerRed, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: dangerRed.withAlpha(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryOrange, deepOrange],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Icon(icon, size: 20, color: primaryOrange),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const Spacer(),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: primaryOrange),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _docUploadTile(String docType, String label) {
    final uploaded = _userDocuments.any((d) => d['doc_type'] == docType);
    return InkWell(
      onTap: () => _uploadDocument(docType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: uploaded ? successGreen.withAlpha(15) : bgCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: uploaded ? successGreen : const Color(0xFFE2E8F0),
            width: uploaded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: uploaded ? successGreen : textLight,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: uploaded ? FontWeight.w700 : FontWeight.w600,
                color: uploaded ? successGreen : textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: softOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: primaryOrange),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
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
