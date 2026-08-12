import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'admin_helpers.dart';

class AdminCareersScreen extends StatefulWidget {
  final String baseUrl;
  const AdminCareersScreen({super.key, required this.baseUrl});

  @override
  State<AdminCareersScreen> createState() => _AdminCareersScreenState();
}

class _AdminCareersScreenState extends State<AdminCareersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _jobs = [];
  List<dynamic> _applications = [];
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
    await Future.wait([_loadJobs(), _loadApplications()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadJobs() async {
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/career-jobs'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _jobs = data['jobs']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadApplications() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/career-applications'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _applications = data['applications']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ==================== RESUME VIEWING FUNCTIONS (FIXED) ====================

  Future<void> _viewResume(String? path) async {
    if (path == null || path.isEmpty) {
      if (mounted) showSnackBar(context, 'No resume uploaded', success: false);
      return;
    }
    try {
      // Try multiple URL patterns to find the file
      final encodedPath = Uri.encodeComponent(path);
      final urls = [
        '${widget.baseUrl}/admin/view-file/$encodedPath',
        '${widget.baseUrl}/view-file/$encodedPath',
        '${widget.baseUrl}/uploads/career_documents/${path.split('/').last}',
        '${widget.baseUrl}/uploads/${path.split('/').last}',
      ];

      bool opened = false;
      for (var url in urls) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          opened = true;
          break;
        }
      }

      if (!opened && mounted) {
        showSnackBar(context, 'Cannot open resume', success: false);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening resume: $e', success: false);
      }
    }
  }

  Future<void> _downloadResume(String? path) async {
    if (path == null || path.isEmpty) {
      if (mounted) showSnackBar(context, 'No resume uploaded', success: false);
      return;
    }
    try {
      if (mounted) showSnackBar(context, 'Downloading resume...');

      final encodedPath = Uri.encodeComponent(path);
      final urls = [
        '${widget.baseUrl}/admin/download-file/$encodedPath',
        '${widget.baseUrl}/download-file/$encodedPath',
        '${widget.baseUrl}/uploads/career_documents/${path.split('/').last}',
      ];

      bool downloaded = false;
      for (var url in urls) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          downloaded = true;
          if (mounted) showSnackBar(context, 'Download started');
          break;
        }
      }

      if (!downloaded && mounted) {
        showSnackBar(context, 'Download failed', success: false);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Download error: $e', success: false);
    }
  }

  // Helper: Get file icon and color for a resume
  Map<String, dynamic> _getFileInfo(String? fileName) {
    if (fileName == null) {
      return {'icon': Icons.insert_drive_file, 'color': Colors.grey};
    }
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      return {'icon': Icons.picture_as_pdf, 'color': Colors.red};
    }
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return {'icon': Icons.image, 'color': Colors.green};
    }
    if (['doc', 'docx'].contains(ext)) {
      return {'icon': Icons.description, 'color': Colors.blue};
    }
    return {'icon': Icons.insert_drive_file, 'color': Colors.grey};
  }

  // ==================== JOB MANAGEMENT ====================

  void _showAddJobDialog() {
    final titleCtrl = TextEditingController();
    final qualCtrl = TextEditingController(text: 'No Qualification Required');
    final expCtrl = TextEditingController(text: '1 - 5 years');
    final skillsCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add Job',
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
                    labelText: 'Job Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qualCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Experience',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: skillsCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Skills (One per line)',
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
                      if (titleCtrl.text.isEmpty) return;
                      setDialogState(() => saving = true);
                      await http.post(
                        Uri.parse('${widget.baseUrl}/career-jobs'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'title': titleCtrl.text,
                          'qualification': qualCtrl.text,
                          'experience': expCtrl.text,
                          'skills': skillsCtrl.text,
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
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditJobDialog(Map<String, dynamic> job) {
    final titleCtrl = TextEditingController(text: job['title']);
    final qualCtrl = TextEditingController(text: job['qualification']);
    final expCtrl = TextEditingController(text: job['experience']);
    final skillsCtrl = TextEditingController(text: job['skills']);
    bool isActive = job['is_active'] == 1;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Edit Job',
            style: TextStyle(color: Color(0xFF1A237E)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qualCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Experience',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: skillsCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF1A237E),
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
                        Uri.parse('${widget.baseUrl}/career-jobs/${job['id']}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'title': titleCtrl.text,
                          'qualification': qualCtrl.text,
                          'experience': expCtrl.text,
                          'skills': skillsCtrl.text,
                          'is_active': isActive ? 1 : 0,
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleJob(int jobId) async {
    await http.put(Uri.parse('${widget.baseUrl}/career-jobs/$jobId/toggle'));
    _loadData();
  }

  void _deleteJob(int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('${widget.baseUrl}/career-jobs/$jobId'));
      _loadData();
    }
  }

  void _updateAppStatus(int appId, String status) async {
    await http.put(
      Uri.parse('${widget.baseUrl}/career-applications/$appId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    _loadData();
    if (mounted) showSnackBar(context, 'Status updated');
  }

  void _deleteApplication(int appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(
        Uri.parse('${widget.baseUrl}/career-applications/$appId'),
      );
      _loadData();
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'contacted':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String? s) {
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s ?? '',
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Careers',
                style: TextStyle(
                  fontSize: isPhone ? 16 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const Spacer(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF1A237E),
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontSize: isPhone ? 11 : 13),
                tabs: const [
                  Tab(text: 'Jobs'),
                  Tab(text: 'Applications'),
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
                  children: [_buildJobsTab(), _buildApplicationsTab()],
                ),
        ),
      ],
    );
  }

  Widget _buildJobsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isPhone ? 8 : 12),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddJobDialog,
                icon: Icon(Icons.add, size: isPhone ? 14 : 18),
                label: Text(isPhone ? 'Add' : 'Add Job'),
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
          child: _jobs.isEmpty
              ? emptyState('No jobs posted')
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16),
                  itemCount: _jobs.length,
                  itemBuilder: (c, i) {
                    final j = _jobs[i];
                    final isActive = j['is_active'] == 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: isPhone ? 36 : 44,
                          height: isPhone ? 36 : 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withAlpha(25)
                                : Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.work,
                            color: isActive ? Colors.green : Colors.grey,
                            size: isPhone ? 18 : 22,
                          ),
                        ),
                        title: Text(
                          j['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isPhone ? 13 : 15,
                          ),
                        ),
                        subtitle: Text(
                          '${j['experience']} • ${j['qualification']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (a) {
                            if (a == 'edit') _showEditJobDialog(j);
                            if (a == 'toggle') _toggleJob(j['id']);
                            if (a == 'delete') _deleteJob(j['id']);
                          },
                          itemBuilder: (c) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text(isActive ? 'Deactivate' : 'Activate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(
                                  'Qualification',
                                  j['qualification'] ?? '',
                                ),
                                _infoRow('Experience', j['experience'] ?? ''),
                                if ((j['skills'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Skills',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    j['skills'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
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

  Widget _buildApplicationsTab() {
    if (_applications.isEmpty) return emptyState('No applications yet');

    if (isPhone) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _applications.length,
        itemBuilder: (c, i) {
          final a = _applications[i];
          String? rp = a['resume_path'];
          bool hasResume = rp != null && rp.toString().isNotEmpty;
          String rfn = 'Resume';
          if (hasResume) {
            try {
              rfn = rp.replaceAll('\\', '/').split('/').last;
            } catch (e) {
              /* ignore */
            }
          }

          // Get file info for icon and color
          final fileInfo = hasResume
              ? _getFileInfo(rfn)
              : {'icon': Icons.insert_drive_file, 'color': Colors.grey};
          final IconData fileIcon = fileInfo['icon'] as IconData;
          final Color fileColor = fileInfo['color'] as Color;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(a['status']).withAlpha(30),
                radius: 18,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: _statusColor(a['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                '${a['first_name']} ${a['last_name']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    a['job_title'] ?? 'General',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(a['status']),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Email', a['email'] ?? ''),
                      _infoRow('Mobile', a['mobile'] ?? ''),
                      if (a['organization'] != null &&
                          a['organization'].toString().isNotEmpty)
                        _infoRow('Organization', a['organization']),
                      if (a['message'] != null &&
                          a['message'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📝 ${a['message']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],

                      // RESUME SECTION (improved UI)
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasResume
                                    ? fileColor.withAlpha(20)
                                    : Colors.grey.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                hasResume ? fileIcon : Icons.cloud_off,
                                color: hasResume ? fileColor : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasResume
                                        ? 'Resume Available'
                                        : 'No Resume',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: hasResume
                                          ? Colors.green[700]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  if (hasResume)
                                    Text(
                                      rfn,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (hasResume) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _viewResume(rp),
                                tooltip: 'View Resume',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                onPressed: () => _downloadResume(rp),
                                tooltip: 'Download',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionBtn(
                            'Contact',
                            Colors.blue,
                            () => _updateAppStatus(a['id'], 'contacted'),
                          ),
                          _actionBtn(
                            'Approve',
                            Colors.green,
                            () => _updateAppStatus(a['id'], 'approved'),
                          ),
                          _actionBtn(
                            'Reject',
                            Colors.red,
                            () => _updateAppStatus(a['id'], 'rejected'),
                          ),
                          _actionBtn(
                            'Delete',
                            const Color(0xFFB71C1C),
                            () => _deleteApplication(a['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Desktop/Tablet view
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF1A237E).withAlpha(15),
          ),
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                '#',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Mobile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Position',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Resume',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: List.generate(_applications.length, (i) {
            final a = _applications[i];
            String? rp = a['resume_path'];
            bool hasResume = rp != null && rp.toString().isNotEmpty;
            String rfn = 'Resume';
            if (hasResume) {
              try {
                rfn = rp.replaceAll('\\', '/').split('/').last;
              } catch (e) {
                /* ignore */
              }
            }
            final fileInfo = hasResume
                ? _getFileInfo(rfn)
                : {'icon': Icons.insert_drive_file, 'color': Colors.grey};
            final IconData fileIcon = fileInfo['icon'] as IconData;
            final Color fileColor = fileInfo['color'] as Color;

            return DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(
                  Text(
                    '${a['first_name']} ${a['last_name']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  SelectableText(
                    a['email'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(Text(a['mobile'] ?? '')),
                DataCell(Text(a['job_title'] ?? 'General')),
                DataCell(
                  hasResume
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: fileColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(fileIcon, size: 14, color: fileColor),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _viewResume(rp),
                              child: Text(
                                rfn,
                                style: const TextStyle(
                                  color: Color(0xFF1A237E),
                                  decoration: TextDecoration.underline,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () => _viewResume(rp),
                              tooltip: 'View',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.download,
                                size: 16,
                                color: Colors.green,
                              ),
                              onPressed: () => _downloadResume(rp),
                              tooltip: 'Download',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                      : const Text('-'),
                ),
                DataCell(_statusChip(a['status'])),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.blue,
                        ),
                        onPressed: () => _updateAppStatus(a['id'], 'contacted'),
                        tooltip: 'Contact',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.green,
                        ),
                        onPressed: () => _updateAppStatus(a['id'], 'approved'),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () => _updateAppStatus(a['id'], 'rejected'),
                        tooltip: 'Reject',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Color(0xFFB71C1C),
                        ),
                        onPressed: () => _deleteApplication(a['id']),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
