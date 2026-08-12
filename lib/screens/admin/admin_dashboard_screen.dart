import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_sidebar.dart';
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
  Map<String, int> _stats = {
    'users': 0, 'applications': 0, 'services': 0,
    'pending': 0, 'completed': 0, 'announcements': 0,
    'tickets': 0, 'faqs': 0
  };
  List<dynamic> _applications = [];
  List<dynamic> _recentTickets = [];
  bool _loading = true;

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
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() => _stats = Map<String, int>.from(data['stats']));
        }
      }
    } catch (e) { print('Stats error: $e'); }
  }

  Future<void> _loadRecentApps() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/applications'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() => _applications = data['applications'] ?? []);
        }
      }
    } catch (e) { print('Apps error: $e'); }
  }

  Future<void> _loadRecentTickets() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/tickets'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() => _recentTickets = data['tickets'] ?? []);
        }
      }
    } catch (e) { print('Tickets error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPhone ? 'DZI Admin' : 'DZI Infinity Admin',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        actions: [
          if (!isPhone) ...[
            _quickStatPill('${_stats['users']}', 'Users', Icons.people, Colors.blue),
            const SizedBox(width: 8),
            _quickStatPill('${_stats['pending']}', 'Pending', Icons.pending, Colors.orange),
            const SizedBox(width: 8),
            _quickStatPill('${_stats['applications']}', 'Apps', Icons.receipt_long, Colors.green),
            const SizedBox(width: 16),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(
                (widget.adminUser['name'] ?? 'A')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: isPhone || isTablet ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(children: [
      AdminSidebar(
        selectedIndex: _selectedIndex,
        adminUser: widget.adminUser,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
        onLogout: () => Navigator.pop(context),
      ),
      Expanded(
        child: _loading
            ? loadingState()
            : IndexedStack(index: _selectedIndex, children: [
                _buildDashboardTab(isMobile: true),
                AdminUsersScreen(baseUrl: _base),
                AdminApplicationsScreen(baseUrl: _base),
                AdminServicesScreen(baseUrl: _base),
                AdminAnnouncementsScreen(baseUrl: _base),
                AdminCareersScreen(baseUrl: _base),
                AdminHelpCenterScreen(baseUrl: _base),
              ]),
      ),
    ]);
  }

  Widget _buildDesktopLayout() {
    return Row(children: [
      AdminSidebar(
        selectedIndex: _selectedIndex,
        adminUser: widget.adminUser,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
        onLogout: () => Navigator.pop(context),
      ),
      Container(width: 1, color: Colors.grey[200]),
      Expanded(
        child: _loading
            ? loadingState()
            : IndexedStack(index: _selectedIndex, children: [
                _buildDashboardTab(),
                AdminUsersScreen(baseUrl: _base),
                AdminApplicationsScreen(baseUrl: _base),
                AdminServicesScreen(baseUrl: _base),
                AdminAnnouncementsScreen(baseUrl: _base),
                AdminCareersScreen(baseUrl: _base),
                AdminHelpCenterScreen(baseUrl: _base),
              ]),
      ),
    ]);
  }

  Widget _quickStatPill(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildDashboardTab({bool isMobile = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dashboard Overview',
                style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            const SizedBox(height: 4),
            Text('Welcome back, ${widget.adminUser['name']}',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ]),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1A237E).withAlpha(15)),
          ),
        ]),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: isMobile ? 8 : 16,
          crossAxisSpacing: isMobile ? 8 : 16,
          childAspectRatio: isMobile ? 1.8 : 2.2,
          children: [
            statCard('${_stats['users']}',        'Users',         Icons.people,                Colors.blue),
            statCard('${_stats['applications']}', 'Applications',  Icons.receipt_long,          Colors.green),
            statCard('${_stats['services']}',     'Services',      Icons.miscellaneous_services, Colors.orange),
            statCard('${_stats['pending']}',      'Pending',       Icons.pending,               Colors.red),
            statCard('${_stats['completed']}',    'Completed',     Icons.check_circle,          Colors.teal),
            statCard('${_stats['announcements']}','Announcements', Icons.campaign,              Colors.purple),
            statCard('${_stats['tickets']}',      'Tickets',       Icons.support_agent,         Colors.indigo),
            statCard('${_stats['faqs']}',         'FAQs',          Icons.help,                  Colors.cyan),
          ],
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildRecentAppsCard(),
          const SizedBox(height: 16),
          _buildRecentTicketsCard(),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _buildRecentAppsCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildRecentTicketsCard()),
          ]),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildRecentAppsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Recent Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(onPressed: () => setState(() => _selectedIndex = 2), child: const Text('View All')),
          ]),
          const Divider(),
          if (_applications.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No applications yet'))
          else
            ..._applications.take(5).map((a) => ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor(a['status']).withAlpha(30),
                radius: 16,
                child: Icon(Icons.receipt, color: statusColor(a['status']), size: 16),
              ),
              title: Text('${a['user_name']} - ${a['service_name']}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              subtitle: Text('ID: ${a['tracking_id']}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              trailing: statusChip(a['status']),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        ]),
      ),
    );
  }

  Widget _buildRecentTicketsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(onPressed: () => setState(() => _selectedIndex = 6), child: const Text('View All')),
          ]),
          const Divider(),
          if (_recentTickets.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No tickets'))
          else
            ..._recentTickets.take(5).map((t) => ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor(t['status']).withAlpha(30),
                radius: 16,
                child: Icon(Icons.support_agent, color: statusColor(t['status']), size: 16),
              ),
              title: Text(t['subject'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              subtitle: Text('${t['user_name']}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              trailing: statusChip(t['status']),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        ]),
      ),
    );
  }
}