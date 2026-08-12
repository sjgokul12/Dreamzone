import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  final bool showBackButton;
  const MyApplicationsScreen({super.key, this.showBackButton = true});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _allApplications = [];
  List<Map<String, dynamic>> _serviceApps = [];
  List<Map<String, dynamic>> _careerApps = [];
  bool _loading = true;
  bool _isGuest = false;

  // App Theme Palette (Matching Home Screen)
  static const Color primaryTeal = Color(0xFF8B5CF6);
  static const Color secondaryTeal = Color(0xFF9333EA);
  static const Color headerGradientStart = Color(0xFFF3E8FF);
  static const Color headerGradientEnd = Color(0xFFEADDFF);
  static const Color textDarkHeading = Color(0xFF1E293B);
  static const Color textSubdued = Color(0xFF64748B);
  static const Color bgCanvas = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAuthAndLoad() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      setState(() {
        _isGuest = true;
        _loading = false;
      });
      return;
    }
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.userId == null) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _api.getUserAllApplications(auth.userId!);
      if (mounted) {
        if (result['success'] == true) {
          final all = List<Map<String, dynamic>>.from(result['applications']);
          setState(() {
            _allApplications = all;
            _serviceApps = all
                .where((a) => a['app_type'] == 'service')
                .toList();
            _careerApps = all.where((a) => a['app_type'] == 'career').toList();
            _loading = false;
            _isGuest = false;
          });
        } else {
          setState(() {
            _loading = false;
            _allApplications = [];
            _serviceApps = [];
            _careerApps = [];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _allApplications = [];
          _serviceApps = [];
          _careerApps = [];
        });
      }
    }
  }

  String _statusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status ?? 'Submitted';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return accentGold;
      case 'processing':
        return secondaryTeal;
      case 'completed':
      case 'approved':
        return successGreen;
      case 'rejected':
        return dangerRed;
      default:
        return primaryTeal;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}m ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5EEFF), Color(0xFFEADDFF)],
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
                      if (widget.showBackButton)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.assignment_rounded, color: Color(0xFF8B5CF6), size: 28),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'My Service Requests',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Track live status & details of your\nsubmitted applications',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset('assets/Service.png', height: 120, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: _loading
                  ? _buildLoadingState()
                  : _isGuest
                      ? _buildGuestState()
                      : Column(
                          children: [
                            if (_allApplications.isNotEmpty) _buildStatsBar(),

                            const SizedBox(height: 16),

                            // TabBar Filter
                            if (!_isGuest && _allApplications.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: cardSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicator: BoxDecoration(
                                    color: primaryTeal,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: textSubdued,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                  tabs: [
                                    Tab(text: 'All (${_allApplications.length})'),
                                    Tab(text: 'Services (${_serviceApps.length})'),
                                    Tab(text: 'Career (${_careerApps.length})'),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            _allApplications.isEmpty
                                ? _buildEmptyState()
                                : SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.55,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildApplicationList(_allApplications),
                                        _buildApplicationList(_serviceApps),
                                        _buildApplicationList(_careerApps),
                                      ],
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

  Widget _buildStatsBar() {
    final pending = _allApplications.where((a) => a['status'] == 'pending').length;
    final completed = _allApplications.where((a) => a['status'] == 'completed' || a['status'] == 'approved').length;
    final rejected = _allApplications.where((a) => a['status'] == 'rejected').length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', _allApplications.length, primaryTeal, Icons.assignment_outlined),
          _statItem('Pending', pending, accentGold, Icons.hourglass_empty_rounded),
          _statItem('Approved', completed, successGreen, Icons.check_circle_outline_rounded),
          _statItem('Rejected', rejected, dangerRed, Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDarkHeading),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: textSubdued, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildApplicationList(List<Map<String, dynamic>> apps) {
    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text('No requests in this view', style: TextStyle(color: textSubdued, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = apps[index];
        final serviceName = item['service_name'] ?? item['job_title'] ?? item['title'] ?? 'Service Application';
        final status = (item['status'] ?? 'submitted').toString();
        final color = _statusColor(status);
        final date = _timeAgo(item['created_at']?.toString());
        final refId = item['application_no'] ?? item['id'] ?? 'DZI-${index + 100}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryTeal.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, color: primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDarkHeading),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: $refId',
                          style: const TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText(status),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: textSubdued),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(fontSize: 11, color: textSubdued)),
                    const Spacer(),
                    const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                    const Icon(Icons.chevron_right, size: 16, color: primaryTeal),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5EEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_outlined, size: 40, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 10),
              const Text(
                'No Requests Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your submitted service requests will appear here',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Image.asset('assets/Empty.png', height: 140, fit: BoxFit.contain),
            ],
          ),
        ),
        
        // Secure & Reliable Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                child: const Icon(Icons.security, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure & Reliable', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6), fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Your data and transactions are always safe with us', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: primaryTeal),
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryTeal.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: primaryTeal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign In Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDarkHeading),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please sign in to track your service requests',
              style: TextStyle(color: textSubdued, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen(isGuest: true)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
