import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() async {
    final result = await _api.getAnnouncements();
    if (result['success'] == true && mounted) {
      setState(() {
        _announcements = List<Map<String, dynamic>>.from(result['announcements']);
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'offer': return Icons.local_offer;
      case 'alert': return Icons.warning_amber;
      case 'update': return Icons.update;
      default: return Icons.campaign;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'offer': return const Color(0xFF2E7D32);
      case 'alert': return const Color(0xFFC62828);
      case 'update': return const Color(0xFF1565C0);
      default: return const Color(0xFF1A237E);
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return '${diff.inDays ~/ 7} weeks ago';
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Color(0xFF1A237E))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAnnouncements(),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
            : _announcements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No notifications yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final a = _announcements[index];
                      final type = a['type'] as String?;
                      final title = (a['title'] ?? '').toString();
                      final message = (a['message'] ?? '').toString();
                      final date = a['created_at'] as String?;
                      final color = _typeColor(type);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(_typeIcon(type), color: color, size: 24),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_timeAgo(date), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                            ],
                          ),
                          trailing: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}