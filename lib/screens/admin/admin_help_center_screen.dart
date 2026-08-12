import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_helpers.dart';

class AdminHelpCenterScreen extends StatefulWidget {
  final String baseUrl;
  const AdminHelpCenterScreen({super.key, required this.baseUrl});

  @override
  State<AdminHelpCenterScreen> createState() => _AdminHelpCenterScreenState();
}

class _AdminHelpCenterScreenState extends State<AdminHelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _faqs = [];
  List<dynamic> _categories = [];
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get isPhone => MediaQuery.of(context).size.width < 600;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadFaqs(), _loadCategories(), _loadTickets()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFaqs() async {
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/faqs'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _faqs = data['faqs']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/faq-categories'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _categories = data['categories']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadTickets() async {
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/tickets'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _tickets = data['tickets']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showAddFaqDialog() {
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    int? selectedCategoryId;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add FAQ',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: null,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map<DropdownMenuItem<int>>(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text((c['name'] ?? '').toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedCategoryId = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
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
              onPressed: saving
                  ? null
                  : () async {
                      if (selectedCategoryId == null ||
                          questionCtrl.text.isEmpty ||
                          answerCtrl.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => saving = true);
                      await http.post(
                        Uri.parse('${widget.baseUrl}/faqs'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'category_id': selectedCategoryId,
                          'question': questionCtrl.text,
                          'answer': answerCtrl.text,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Add FAQ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyTicketDialog(Map<String, dynamic> ticket) {
    final replyCtrl = TextEditingController();
    String status = 'resolved';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Reply to Ticket',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${ticket['user_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subject: ${ticket['subject']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ticket['message'] ?? ''),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: replyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Your Reply',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: ['resolved', 'in_progress', 'closed']
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s.replaceAll('_', ' ').toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => status = v ?? 'resolved',
                  decoration: const InputDecoration(
                    labelText: 'Status',
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
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      await http.put(
                        Uri.parse(
                          '${widget.baseUrl}/tickets/${ticket['id']}/reply',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'reply': replyCtrl.text,
                          'status': status,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Reply'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFaq(int faqId) async {
    await http.put(Uri.parse('${widget.baseUrl}/faqs/$faqId/toggle'));
    _loadData();
  }

  void _deleteFaq(int faqId) async {
    await http.delete(Uri.parse('${widget.baseUrl}/faqs/$faqId'));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 4),
            ],
          ),
          child: Row(
            children: [
              Text(
                'Help Center',
                style: TextStyle(
                  fontSize: isPhone ? 16 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const Spacer(),
              if (isPhone)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF1A237E),
                  labelColor: const Color(0xFF1A237E),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'FAQs'),
                    Tab(text: 'Tickets'),
                  ],
                )
              else
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF1A237E),
                  labelColor: const Color(0xFF1A237E),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'FAQs'),
                    Tab(text: 'Support Tickets'),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? loadingState()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildFaqsTab(), _buildTicketsTab()],
                ),
        ),
      ],
    );
  }

  Widget _buildFaqsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isPhone ? 8 : 12),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddFaqDialog,
                icon: Icon(Icons.add, size: isPhone ? 14 : 18),
                label: Text(isPhone ? 'Add' : 'Add FAQ'),
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
        ),
        Expanded(
          child: _faqs.isEmpty
              ? emptyState('No FAQs yet')
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16),
                  itemCount: _faqs.length,
                  itemBuilder: (c, i) {
                    final f = _faqs[i];
                    final isActive = f['is_active'] == 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: isPhone ? 30 : 36,
                          height: isPhone ? 30 : 36,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withAlpha(30)
                                : Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isActive ? Icons.check_circle : Icons.block,
                            color: isActive ? Colors.green : Colors.grey,
                            size: isPhone ? 16 : 18,
                          ),
                        ),
                        title: Text(
                          f['question'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 12 : 14,
                          ),
                        ),
                        subtitle: Text(
                          'Category: ${f['category_name']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'toggle') _toggleFaq(f['id'] as int);
                            if (action == 'delete') _deleteFaq(f['id'] as int);
                          },
                          itemBuilder: (c) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                isActive ? 'Deactivate' : 'Activate',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              f['answer'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isPhone ? 11 : 13,
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

  Widget _buildTicketsTab() {
    return _tickets.isEmpty
        ? emptyState('No support tickets')
        : ListView.builder(
            padding: EdgeInsets.all(isPhone ? 8 : 16),
            itemCount: _tickets.length,
            itemBuilder: (c, i) {
              final t = _tickets[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor(t['status']).withAlpha(30),
                    radius: isPhone ? 16 : 20,
                    child: Icon(
                      Icons.support_agent,
                      color: statusColor(t['status']),
                      size: isPhone ? 16 : 20,
                    ),
                  ),
                  title: Text(
                    t['subject'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isPhone ? 12 : 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t['user_name']} • ${t['message']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isPhone ? 10 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          statusChip(t['status']),
                          const SizedBox(width: 6),
                          _priorityChip(t['priority']),
                        ],
                      ),
                    ],
                  ),
                  trailing: t['admin_reply'] == null
                      ? ElevatedButton(
                          onPressed: () => _showReplyTicketDialog(t),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 8 : 12,
                            ),
                          ),
                          child: Text(
                            'Reply',
                            style: TextStyle(fontSize: isPhone ? 10 : 11),
                          ),
                        )
                      : Icon(
                          Icons.check_circle,
                          color: Colors.green[400],
                          size: isPhone ? 18 : 22,
                        ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _priorityChip(String? p) {
    Color c = Colors.grey;
    if (p == 'urgent') c = Colors.red;
    if (p == 'high') c = Colors.orange;
    if (p == 'medium') c = Colors.blue;
    if (p == 'low') c = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        p?.toUpperCase() ?? '',
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: c),
      ),
    );
  }
}
