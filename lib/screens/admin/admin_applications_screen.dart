import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'admin_helpers.dart';

class AdminApplicationsScreen extends StatefulWidget {
  final String baseUrl;
  const AdminApplicationsScreen({super.key, required this.baseUrl});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  List<dynamic> _applications = [];
  bool _loading = true;
  String _filterStatus = 'All';
  String _searchQuery = '';
  int? _expandedIndex;

  // Cache for section details (fee, time, documents)
  final Map<int, Map<String, dynamic>> _sectionCache = {};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  bool get isPhone => MediaQuery.of(context).size.width < 600;

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/applications'),
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _applications = data['applications'] ?? [];
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading applications: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredApplications {
    return _applications.where((a) {
      final name = '${a['user_name']} ${a['service_name']} ${a['tracking_id']}'
          .toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == 'All' || a['status'] == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _updateStatus(int appId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/applications/$appId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        showSnackBar(context, 'Status updated to $status');
        _loadApplications();
      }
    } catch (e) {
      showSnackBar(context, 'Error updating status', success: false);
    }
  }

  Future<void> _deleteApplication(int appId, String trackingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this application?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(30)),
              ),
              child: Text(
                '⚠️ This will delete: Application #$trackingId, all uploaded documents, and form data',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
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
      setState(() => _loading = true);
      try {
        final res = await http.delete(
          Uri.parse('${widget.baseUrl}/applications/$appId'),
          headers: {'Accept': 'application/json'},
        );
        final data = jsonDecode(res.body);
        if (data['success'] == true && mounted) {
          showSnackBar(context, 'Application deleted');
          _loadApplications();
        } else {
          setState(() => _loading = false);
        }
      } catch (e) {
        setState(() => _loading = false);
        showSnackBar(context, 'Error deleting', success: false);
      }
    }
  }

  // ==================== PARSE FORM DATA ====================

  Map<String, dynamic> _parseFormData(dynamic formData) {
    if (formData == null) return {};
    try {
      if (formData is String) {
        return Map<String, dynamic>.from(jsonDecode(formData));
      }
      if (formData is Map) {
        return Map<String, dynamic>.from(formData);
      }
    } catch (e) {
      /* ignore */
    }
    return {};
  }

  // ==================== FILE VIEWING ====================

  void _viewFiles(int applicationId) async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.folder_open, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Documents',
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: FutureBuilder(
                future: http.get(
                  Uri.parse(
                    '${widget.baseUrl}/applications/$applicationId/files',
                  ),
                  headers: {'Accept': 'application/json'},
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A237E),
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(child: Text('Error loading files'));
                  }
                  try {
                    final data = jsonDecode(snapshot.data!.body);
                    final files = (data['files'] as List?) ?? [];
                    if (files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No documents uploaded',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (c, i) {
                        final file = files[i];
                        final fileName = file['file_name'] ?? 'Unknown';
                        final filePath = file['file_path'] ?? '';
                        final fileSize = file['size_display'] ?? '';
                        final exists = file['exists'] ?? false;
                        final isImage =
                            fileName.endsWith('.jpg') ||
                            fileName.endsWith('.jpeg') ||
                            fileName.endsWith('.png');
                        final isPdf = fileName.endsWith('.pdf');

                        IconData icon = Icons.insert_drive_file;
                        Color color = Colors.grey;
                        if (isPdf) {
                          icon = Icons.picture_as_pdf;
                          color = Colors.red;
                        } else if (isImage) {
                          icon = Icons.image;
                          color = Colors.green;
                        } else if (fileName.endsWith('.doc') ||
                            fileName.endsWith('.docx')) {
                          icon = Icons.description;
                          color = Colors.blue;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              exists ? 'Available • $fileSize' : 'File missing',
                              style: TextStyle(
                                fontSize: 11,
                                color: exists ? Colors.green : Colors.red,
                              ),
                            ),
                            trailing: exists
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _openFile(filePath, fileName),
                                        tooltip: 'View',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _downloadFile(filePath, fileName),
                                        tooltip: 'Download',
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    return Center(child: Text('Error: $e'));
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFile(String filePath, String fileName) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final viewUrl = '${widget.baseUrl}/view-file/$encodedPath';
      final uri = Uri.parse(viewUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showSnackBar(context, 'Cannot open file', success: false);
      }
    } catch (e) {
      showSnackBar(context, 'Error opening file', success: false);
    }
  }

  Future<void> _downloadFile(String filePath, String fileName) async {
    try {
      showSnackBar(context, 'Downloading $fileName...');
      final encodedPath = Uri.encodeComponent(filePath);
      final downloadUrl = '${widget.baseUrl}/download-file/$encodedPath';
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        showSnackBar(context, 'Download started: $fileName');
      } else {
        showSnackBar(context, 'Download failed', success: false);
      }
    } catch (e) {
      showSnackBar(context, 'Download error', success: false);
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApplications;

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_applications.length} total',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name, ID or service...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      underline: const SizedBox(),
                      items:
                          [
                            'All',
                            'pending',
                            'processing',
                            'completed',
                            'rejected',
                          ].map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: s == 'All'
                                      ? const Color(0xFF1A237E)
                                      : statusColor(s),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (v) =>
                          setState(() => _filterStatus = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _loading
              ? loadingState()
              : filtered.isEmpty
              ? emptyState('No applications found')
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final a = filtered[i];
                    final formData = _parseFormData(a['form_data']);
                    final sectionName = formData['selected_section'] ?? 'N/A';
                    final sectionId =
                        formData['selected_section_id']?.toString() ?? 'N/A';
                    final isExpanded = _expandedIndex == i;

                    // Get document count (optional: we could fetch from API, but we'll show from form_data or a placeholder)
                    // For now, we can show a generic "Documents" button with count (0 if none).
                    // Better: we can count the number of file entries in the form data? Not reliable.
                    // We'll just show a generic count from the files API when expanded.

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          // Header
                          ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusColor(a['status']).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: statusColor(a['status']),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              a['service_name'] ?? 'Unknown Service',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a['user_name'] ?? 'Unknown User'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      a['tracking_id'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    statusChip(a['status']),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.folder_open,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () => _viewFiles(a['id']),
                                  tooltip: 'View Files',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _expandedIndex = isExpanded ? null : i;
                                    });
                                  },
                                  tooltip: 'View Details',
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (s) {
                                    if (s == 'delete') {
                                      _deleteApplication(
                                        a['id'],
                                        a['tracking_id'] ?? '',
                                      );
                                    } else {
                                      _updateStatus(a['id'], s);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'pending',
                                      child: Text('Pending'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'processing',
                                      child: Text('Processing'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'completed',
                                      child: Text('Completed'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'rejected',
                                      child: Text('Rejected'),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : i;
                              });
                            },
                          ),

                          // Expanded Details
                          if (isExpanded)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),

                                  // User Info
                                  _sectionHeader('User Information'),
                                  _detailRow(
                                    Icons.person,
                                    'Name',
                                    a['user_name'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    Icons.email,
                                    'Email',
                                    a['user_email'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    Icons.phone,
                                    'Mobile',
                                    a['user_mobile'] ?? 'N/A',
                                  ),

                                  const SizedBox(height: 12),

                                  // Service & Section Info
                                  _sectionHeader('Service Information'),
                                  _detailRow(
                                    Icons.assignment,
                                    'Service',
                                    a['service_name'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    Icons.label,
                                    'Tracking ID',
                                    a['tracking_id'] ?? 'N/A',
                                  ),
                                  _detailRow(
                                    Icons.folder,
                                    'Selected Section',
                                    sectionName,
                                  ),
                                  _detailRow(
                                    Icons.code,
                                    'Section ID',
                                    sectionId,
                                  ),
                                  _detailRow(
                                    Icons.calendar_today,
                                    'Submitted',
                                    _formatDate(a['created_at']),
                                  ),
                                  _detailRow(
                                    Icons.update,
                                    'Last Updated',
                                    _formatDate(a['updated_at']),
                                  ),

                                  const SizedBox(height: 12),

                                  // Form Data (filter out internal fields)
                                  if (formData.isNotEmpty) ...[
                                    _sectionHeader('Form Data'),
                                    ...formData.entries
                                        .where(
                                          (entry) => ![
                                            'selected_section',
                                            'selected_section_id',
                                          ].contains(entry.key),
                                        )
                                        .map((entry) {
                                          return _detailRow(
                                            Icons.info_outline,
                                            _formatLabel(entry.key),
                                            entry.value.toString(),
                                          );
                                        }),
                                    const SizedBox(height: 12),
                                  ],

                                  // Documents
                                  _sectionHeader('Documents'),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _viewFiles(a['id']),
                                        icon: const Icon(
                                          Icons.folder_open,
                                          size: 16,
                                        ),
                                        label: Text('View Files'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF1A237E,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Status Update Buttons
                                      if (a['status'] == 'pending')
                                        _statusActionButton(
                                          'Process',
                                          Colors.blue,
                                          () {
                                            _updateStatus(
                                              a['id'],
                                              'processing',
                                            );
                                          },
                                        ),
                                      if (a['status'] == 'processing')
                                        _statusActionButton(
                                          'Complete',
                                          Colors.green,
                                          () {
                                            _updateStatus(a['id'], 'completed');
                                          },
                                        ),
                                      _statusActionButton(
                                        'Reject',
                                        Colors.red,
                                        () {
                                          _updateStatus(a['id'], 'rejected');
                                        },
                                        isReject: true,
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
                ),
        ),
      ],
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == 'null' || value == 'N/A') {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusActionButton(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isReject = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isReject ? color.withAlpha(15) : color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isReject ? color.withAlpha(60) : color.withAlpha(60),
              width: 1,
            ),
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
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}
