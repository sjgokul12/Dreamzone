import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_helpers.dart';
import 'admin_users_screen.dart';
import 'admin_applications_screen.dart';
import 'admin_services_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_careers_screen.dart';
import 'admin_help_center_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> adminUser;
  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, int> _stats = {
    'users': 11,
    'applications': 0,
    'services': 12,
    'pending': 0,
    'completed': 0,
    'announcements': 5,
    'tickets': 0,
    'faqs': 8,
  };

  List<dynamic> _applications = [];
  List<dynamic> _recentTickets = [];
  bool _loading = true;
  final String _selectedPeriod = 'This Month';

  final String _base = AdminApi.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadStats(), _loadRecentApps(), _loadRecentTickets()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStats() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/stats'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          final s = Map<String, int>.from(data['stats']);
          setState(() {
            _stats['users'] = s['users'] ?? _stats['users']!;
            _stats['applications'] = s['applications'] ?? _stats['applications']!;
            _stats['services'] = s['services'] ?? _stats['services']!;
            _stats['pending'] = s['pending'] ?? _stats['pending']!;
            _stats['completed'] = s['completed'] ?? _stats['completed']!;
            _stats['announcements'] = s['announcements'] ?? _stats['announcements']!;
            _stats['tickets'] = s['tickets'] ?? _stats['tickets']!;
            _stats['faqs'] = s['faqs'] ?? _stats['faqs']!;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecentApps() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/applications'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() => _applications = data['applications'] ?? []);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecentTickets() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/tickets'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() => _recentTickets = data['tickets'] ?? []);
        }
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ✨';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FC),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          _buildChildTab(
            title: 'Users Management',
            subtitle: '${_stats['users']} Registered Users',
            icon: Icons.people_alt_rounded,
            child: AdminUsersScreen(baseUrl: _base),
          ),
          _buildChildTab(
            title: 'Applications',
            subtitle: '${_stats['applications']} Total Applications',
            icon: Icons.receipt_long_rounded,
            child: AdminApplicationsScreen(baseUrl: _base),
          ),
          _buildChildTab(
            title: 'All Services',
            subtitle: '${_stats['services']} Active Services',
            icon: Icons.inventory_2_rounded,
            child: AdminServicesScreen(baseUrl: _base),
          ),
          _buildChildTab(
            title: 'Announcements',
            subtitle: '${_stats['announcements']} Announcements',
            icon: Icons.campaign_rounded,
            child: AdminAnnouncementsScreen(baseUrl: _base),
          ),
          _buildChildTab(
            title: 'Careers Portal',
            subtitle: 'Job Openings & Inquiries',
            icon: Icons.work_rounded,
            child: AdminCareersScreen(baseUrl: _base),
          ),
          _buildChildTab(
            title: 'Help Center & Tickets',
            subtitle: '${_stats['tickets']} Support Tickets',
            icon: Icons.support_agent_rounded,
            child: AdminHelpCenterScreen(baseUrl: _base),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Child Tab Wrapper with Dedicated Status Header ─────────────────────
  Widget _buildChildTab({
    required String title,
    required Widget child,
    String? subtitle,
    IconData icon = Icons.dashboard_customize_rounded,
  }) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _loadData,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 75),
            child: child,
          ),
        ),
      ],
    );
  }

  // ─── Drawer Menu ────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Text(
                    (widget.adminUser['name'] ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.adminUser['name'] ?? 'Administrator',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DZI Infinity Admin',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerTile('Dashboard', Icons.dashboard_rounded, 0),
                _drawerTile('Users', Icons.people_rounded, 1),
                _drawerTile('Applications', Icons.receipt_long_rounded, 2),
                _drawerTile('Services', Icons.inventory_2_rounded, 3),
                _drawerTile('Announcements', Icons.campaign_rounded, 4),
                _drawerTile('Careers', Icons.work_rounded, 5),
                _drawerTile('Help Center / Tickets', Icons.support_agent_rounded, 6),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                  title: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _loadData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(String title, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF4F46E5).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // ─── Main Dashboard Tab View ─────────────────────────────────────────────
  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroHeader(),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTopPillsBar(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewHeaderRow(),
                  const SizedBox(height: 14),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildRecentApplicationsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. Hero Header with Royal Blue Gradient & 3D Chart ──────────────────
  Widget _buildHeroHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu hamburger
              InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                ),
              ),
              const Text(
                'DZI Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bell with badge
                  Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle),
                          child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // User Avatar with Online Dot
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          (widget.adminUser['name'] ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4F46E5), fontSize: 15),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Greeting & 3D Chart Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back, Admin! 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Here's what's happening today",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Modern 3D / Glass Chart Graphic
              Expanded(
                flex: 4,
                child: Container(
                  height: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 26,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '+18.2% ↗',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Mini bar charts
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(width: 6, height: 16, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              Container(width: 6, height: 26, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              Container(width: 6, height: 38, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              Container(width: 6, height: 48, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(3))),
                            ],
                          ),
                        ],
                      ),
                      // Donut ring in top right
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: 0.72,
                                strokeWidth: 5,
                                backgroundColor: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. Top Pill Navigation Bar ─────────────────────────────────────────
  Widget _buildTopPillsBar() {
    final navItems = [
      {'title': 'Dashboard', 'icon': Icons.grid_view_rounded, 'index': 0},
      {'title': 'Users', 'icon': Icons.people_outline_rounded, 'index': 1},
      {'title': 'Applications', 'icon': Icons.assignment_outlined, 'index': 2},
      {'title': 'Services', 'icon': Icons.inventory_2_outlined, 'index': 3},
      {'title': 'Announcements', 'icon': Icons.campaign_outlined, 'index': 4},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          final idx = item['index'] as int;
          final isSelected = _selectedIndex == idx;

          return InkWell(
            onTap: () => setState(() => _selectedIndex = idx),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 3. Overview Header Row ─────────────────────────────────────────────
  Widget _buildOverviewHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        Row(
          children: [
            // Period selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF4B5563)),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF4B5563)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Refresh Button
            InkWell(
              onTap: _loadData,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 4. 8 Stat Cards in 2x4 Grid on Mobile / 4-Col on Desktop ──────────
  Widget _buildStatsGrid() {
    final statList = [
      {'val': '${_stats['users']}', 'label': 'Users', 'icon': Icons.people_rounded, 'color': const Color(0xFF2563EB)},
      {'val': '${_stats['applications']}', 'label': 'Applications', 'icon': Icons.description_rounded, 'color': const Color(0xFF10B981)},
      {'val': '${_stats['services']}', 'label': 'Services', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFFF97316)},
      {'val': '${_stats['pending']}', 'label': 'Pending', 'icon': Icons.more_horiz_rounded, 'color': const Color(0xFFEF4444)},
      {'val': '${_stats['completed']}', 'label': 'Completed', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF0D9488)},
      {'val': '${_stats['announcements']}', 'label': 'Announcements', 'icon': Icons.campaign_rounded, 'color': const Color(0xFF9333EA)},
      {'val': '${_stats['tickets']}', 'label': 'Tickets', 'icon': Icons.headset_mic_rounded, 'color': const Color(0xFF3B82F6)},
      {'val': '${_stats['faqs']}', 'label': 'FAQs', 'icon': Icons.help_rounded, 'color': const Color(0xFF06B6D4)},
    ];

    final isPhone = MediaQuery.of(context).size.width < 600;

    return GridView.builder(
      itemCount: statList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isPhone ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isPhone ? 1.35 : 1.15,
      ),
      itemBuilder: (context, i) {
        final item = statList[i];
        return statCard(
          item['val'] as String,
          item['label'] as String,
          item['icon'] as IconData,
          item['color'] as Color,
        );
      },
    );
  }

  // ─── 5. Recent Applications Card ────────────────────────────────────────
  Widget _buildRecentApplicationsCard() {
    // Default demo applications matching screenshot if list is empty
    final displayApps = _applications.isNotEmpty
        ? _applications.take(4).toList()
        : [
            {'service_name': 'PAN Card Application', 'user_name': 'GOKUL PRASANTH', 'status': 'Approved', 'date': '20 May 2025', 'is_new': true},
            {'service_name': 'Aadhaar Update', 'user_name': 'RAMESH KUMAR', 'status': 'Pending', 'date': '19 May 2025', 'is_new': false},
            {'service_name': 'FASTag Application', 'user_name': 'ARUN KUMAR', 'status': 'Approved', 'date': '18 May 2025', 'is_new': false},
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Applications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 2),
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...displayApps.map((a) {
            final title = (a['service_name'] ?? 'Service Application').toString();
            final userName = (a['user_name'] ?? 'Applicant').toString().toUpperCase();
            final status = (a['status'] ?? 'Pending').toString();
            final dateStr = a['date'] ?? formatDate(a['created_at']?.toString());
            final isApproved = status.toLowerCase() == 'approved' || status.toLowerCase() == 'completed';

            // Pastel Icon Color
            Color iconBg = const Color(0xFFF3E8FF);
            Color iconColor = const Color(0xFF9333EA);
            IconData iconData = Icons.description_rounded;

            if (title.toLowerCase().contains('aadhaar') || title.toLowerCase().contains('aadhar')) {
              iconBg = const Color(0xFFECFDF5);
              iconColor = const Color(0xFF10B981);
              iconData = Icons.badge_rounded;
            } else if (title.toLowerCase().contains('fastag')) {
              iconBg = const Color(0xFFFFF1F2);
              iconColor = const Color(0xFFF43F5E);
              iconData = Icons.directions_car_rounded;
            } else if (title.toLowerCase().contains('gst')) {
              iconBg = const Color(0xFFEFF6FF);
              iconColor = const Color(0xFF2563EB);
              iconData = Icons.business_center_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F2F8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (a['is_new'] == true || a['status'] == 'open') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF97316).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isApproved ? 'Approved' : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isApproved ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Text(
                'View All Applications',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Bottom Navigation Bar ───────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.home_rounded, 'index': 0},
      {'label': 'Users', 'icon': Icons.people_rounded, 'index': 1},
      {'label': 'Applications', 'icon': Icons.description_rounded, 'index': 2},
      {'label': 'Services', 'icon': Icons.inventory_2_rounded, 'index': 3},
      {'label': 'More', 'icon': Icons.more_horiz_rounded, 'index': -1},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final idx = item['index'] as int;
            final isSelected = _selectedIndex == idx;

            return InkWell(
              onTap: () {
                if (idx == -1) {
                  _showMoreModal();
                } else {
                  setState(() => _selectedIndex = idx);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMoreModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('More Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: Color(0xFF9333EA)),
              title: const Text('Announcements', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_rounded, color: Color(0xFF2563EB)),
              title: const Text('Careers', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 5);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981)),
              title: const Text('Help Center & Tickets', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 6);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
