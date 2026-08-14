import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Premium Project Purple Palette
  static const Color primaryTeal = Color(0xFF7F00FF);
  static const Color secondaryTeal = Color(0xFFE100FF);
  static const Color headerGradientStart = Color(0xFF7F00FF);
  static const Color headerGradientEnd = Color(0xFFE100FF);
  Color get textDarkHeading => const Color(0xFF0F172A);
  Color get textSubdued => const Color(0xFF64748B);
  Color get bgCanvas => const Color(0xFFF1F5F9);
  Color get cardSurface => Colors.white;
  static const Color dangerRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      auth.loadSettings();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: dangerRed.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: dangerRed,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDarkHeading,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to logout from DZI Infinity?',
                style: TextStyle(color: textSubdued, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSubdued,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    bool deleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: dangerRed.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: dangerRed,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDarkHeading,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This action is permanent. All your profile data, applications, and saved documents will be deleted.',
                  style: TextStyle(
                    color: textSubdued,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: TextStyle(color: textDarkHeading, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Enter password to confirm',
                    labelStyle: TextStyle(color: textSubdued, fontSize: 12),
                    prefixIcon: Icon(Icons.lock_outline, color: dangerRed, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dangerRed, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSubdued,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: deleting
                            ? null
                            : () async {
                                if (passwordCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter your password'),
                                      backgroundColor: dangerRed,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() => deleting = true);
                                final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final result = await auth.deleteAccount(
                                  passwordCtrl.text.trim(),
                                );
                                setDialogState(() => deleting = false);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  if (result['success'] == true && mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(isGuest: true),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dangerRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: deleting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = !auth.isLoggedIn;
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 800 ? (screenSize.width - 680) / 2 : 16.0;

    return Scaffold(
      backgroundColor: bgCanvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Curved Hero Container
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerGradientStart, headerGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Icon(Icons.settings_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage account preferences & application settings',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Settings Content Body
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                  child: Column(
                    children: [
                      // Profile Card
                      _buildProfileCard(auth, isGuest),

                      if (!isGuest) ...[
                        SizedBox(height: 22),

                        // Notifications Section
                        _buildSectionHeader('Notifications', Icons.notifications_outlined),
                        _buildTileGroup([
                          _buildSwitchTile(
                            title: 'Push Notifications',
                            subtitle: 'Receive instant status updates & alerts',
                            value: auth.notificationsEnabled,
                            onChanged: (v) => auth.setNotifications(v),
                            icon: Icons.notifications_active_outlined,
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            title: 'Email Alerts',
                            subtitle: 'Get official application receipts via email',
                            value: auth.emailAlertsEnabled,
                            onChanged: (v) => auth.setEmailAlerts(v),
                            icon: Icons.email_outlined,
                          ),
                        ]),
                        SizedBox(height: 22),

                        // Account Section
                        _buildSectionHeader('Account', Icons.person_outline),
                        _buildTileGroup([
                          _buildActionTile(
                            title: 'Logout',
                            subtitle: 'Sign out from your DZI Infinity account',
                            icon: Icons.logout_rounded,
                            color: primaryTeal,
                            onTap: _showLogoutDialog,
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            title: 'Delete Account',
                            subtitle: 'Permanently remove your profile & data',
                            icon: Icons.delete_forever_rounded,
                            color: dangerRed,
                            onTap: _showDeleteAccountDialog,
                          ),
                        ]),
                      ],

                      SizedBox(height: 22),

                      // About Section
                      _buildSectionHeader('About', Icons.info_outline),
                      _buildTileGroup([
                        _buildInfoTile(
                          title: 'App Version',
                          subtitle: '1.0.0',
                          icon: Icons.system_update_outlined,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          title: 'Developer',
                          subtitle: 'DreamZone India Infinity Services',
                          icon: Icons.business_outlined,
                        ),
                      ]),

                      SizedBox(height: 32),

                      // App Footer Tagline
                      Center(
                        child: Text(
                          'DZI Infinity',
                          style: TextStyle(
                            color: textDarkHeading,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Center(
                        child: Text(
                          'All Services. One App.',
                          style: TextStyle(color: textSubdued, fontSize: 11.5),
                        ),
                      ),
                      SizedBox(height: 24),
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

  Widget _buildProfileCard(AuthProvider auth, bool isGuest) {
    final name = isGuest ? 'Guest User' : (auth.userName ?? 'User');
    final email = isGuest ? 'Sign in to access all features' : (auth.userEmail ?? '');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryTeal,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryTeal,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDarkHeading,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: textSubdued),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isGuest) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryTeal.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: primaryTeal, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Verified Member',
                          style: TextStyle(
                            color: primaryTeal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: textDarkHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: textSubdued),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTeal.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryTeal, size: 18),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: primaryTeal.withAlpha(60),
      activeThumbColor: primaryTeal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: textSubdued),
      ),
      trailing: Icon(Icons.chevron_right, color: color, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTeal.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryTeal, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: textDarkHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: textSubdued),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60, endIndent: 14, color: Color(0xFFF1F5F9));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Icon(icon, size: 16, color: primaryTeal),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: textDarkHeading,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileGroup(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tiles,
      ),
    );
  }
}
