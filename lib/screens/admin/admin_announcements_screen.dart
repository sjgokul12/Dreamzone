import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_helpers.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  final String baseUrl;
  const AdminAnnouncementsScreen({super.key, required this.baseUrl});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  bool get isPhone => MediaQuery.of(context).size.width < 600;

  Future<void> _loadAnnouncements() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/announcements'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _announcements = data['announcements']);
      }
    } catch (e) {
      /* ignore */
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filteredAnnouncements {
    if (_searchQuery.isEmpty) return _announcements;
    return _announcements.where((a) {
      final title = (a['title'] ?? '').toString().toLowerCase();
      final msg = (a['message'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || msg.contains(query);
    }).toList();
  }

  void _createAnnouncement(String title, String message, String type) async {
    if (title.isEmpty || message.isEmpty) {
      if (mounted) {
        showSnackBar(context, 'Title and message required', success: false);
      }
      return;
    }
    await http.post(
      Uri.parse('${widget.baseUrl}/announcements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'message': message, 'type': type}),
    );
    _loadAnnouncements();
    if (mounted) showSnackBar(context, 'Announcement created');
  }

  void _toggleAnnouncement(int annId) async {
    await http.put(Uri.parse('${widget.baseUrl}/announcements/$annId/toggle'));
    _loadAnnouncements();
  }

  void _deleteAnnouncement(int annId) async {
    await http.delete(Uri.parse('${widget.baseUrl}/announcements/$annId'));
    _loadAnnouncements();
    if (mounted) showSnackBar(context, 'Announcement deleted');
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String type = 'general';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Create Announcement',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: ['general', 'offer', 'alert', 'update']
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? 'general'),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createAnnouncement(titleCtrl.text, msgCtrl.text, type);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String? t) {
    switch (t) {
      case 'alert':
        return Colors.red;
      case 'offer':
        return Colors.green;
      case 'update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String? t) {
    switch (t) {
      case 'alert':
        return Icons.warning_amber;
      case 'offer':
        return Icons.local_offer;
      case 'update':
        return Icons.update;
      default:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAnnouncements;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: isPhone ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_announcements.length} total',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: Icon(Icons.add, size: isPhone ? 14 : 16),
                    label: Text(isPhone ? 'New' : 'Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 8 : 12,
                        vertical: isPhone ? 4 : 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? loadingState()
              : filtered.isEmpty
              ? emptyState('No announcements')
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 16),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final a = filtered[i];
                    final isActive = a['is_active'] == 1;
                    final color = _typeColor(a['type']);
                    final icon = _typeIcon(a['type']);
                    final date = (a['created_at'] ?? '').toString();
                    final dateStr = date.length >= 10
                        ? date.substring(0, 10)
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: isPhone ? 36 : 44,
                          height: isPhone ? 36 : 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withAlpha(30)
                                : Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: isActive ? color : Colors.grey,
                            size: isPhone ? 18 : 22,
                          ),
                        ),
                        title: Text(
                          a['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 13 : 15,
                          ),
                        ),
                        subtitle: Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (a['type'] ?? 'general').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (v) => _toggleAnnouncement(a['id']),
                              activeThumbColor: Colors.green,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteAnnouncement(a['id']),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              a['message'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isPhone ? 12 : 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
