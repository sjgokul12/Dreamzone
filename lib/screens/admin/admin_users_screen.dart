import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'admin_helpers.dart';

class AdminUsersScreen extends StatefulWidget {
  final String baseUrl;
  const AdminUsersScreen({super.key, required this.baseUrl});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  bool get isPhone => MediaQuery.of(context).size.width < 600;

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/users'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _users = data['users']);
      }
    } catch (e) {
      /* ignore */
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final mobile = (u['mobile'] ?? '').toString();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          mobile.contains(query);
    }).toList();
  }

  // ==================== DOCUMENT VIEWING FUNCTIONS ====================

  Future<void> _viewDocument(String filePath, String fileName) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final viewUrl = '${widget.baseUrl}/admin/view-file/$encodedPath';
      final uri = Uri.parse(viewUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) showSnackBar(context, 'Cannot open file', success: false);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening file: $e', success: false);
      }
    }
  }

  Future<void> _downloadDocument(String filePath, String fileName) async {
    try {
      if (mounted) showSnackBar(context, 'Downloading $fileName...');

      final encodedPath = Uri.encodeComponent(filePath);
      final downloadUrl = '${widget.baseUrl}/admin/download-file/$encodedPath';
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) showSnackBar(context, 'Download started: $fileName');
      } else {
        if (mounted) showSnackBar(context, 'Download failed', success: false);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Download error: $e', success: false);
    }
  }

  // ==================== VIEW USER DETAILS ====================

  void _viewUserDetails(Map<String, dynamic> user) async {
    final userId = user['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1A237E).withAlpha(20),
                child: Text(
                  (user['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user['name'] ?? 'User Details',
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 16,
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
            height: MediaQuery.of(context).size.height * 0.75,
            child: FutureBuilder(
              future: Future.wait([
                http.get(
                  Uri.parse('${ApiService.baseUrl}/user/$userId/saved-details'),
                ),
                http.get(
                  Uri.parse('${ApiService.baseUrl}/user/$userId/documents'),
                ),
                http.get(Uri.parse('${widget.baseUrl}/applications')),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }

                Map<String, dynamic> savedDetails = {};
                List<dynamic> documents = [];
                List<dynamic> applications = [];

                try {
                  final detailsData = jsonDecode((snapshot.data![0]).body);
                  savedDetails = detailsData['details'] ?? {};

                  final docsData = jsonDecode((snapshot.data![1]).body);
                  documents = docsData['documents'] ?? [];

                  final appsData = jsonDecode((snapshot.data![2]).body);
                  final allApps = appsData['applications'] ?? [];
                  applications = allApps
                      .where((a) => a['user_id'] == userId)
                      .toList();
                } catch (e) {
                  /* ignore */
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _sectionTitle('Basic Information'),
                      _infoCard([
                        _infoItem(Icons.email, 'Email', user['email'] ?? 'N/A'),
                        _infoItem(
                          Icons.phone,
                          'Mobile',
                          user['mobile'] ?? 'N/A',
                        ),
                        _infoItem(
                          Icons.calendar_today,
                          'Joined',
                          (user['created_at'] ?? '').toString().substring(
                            0,
                            10,
                          ),
                        ),
                        _infoItem(
                          Icons.verified_user,
                          'Status',
                          user['is_verified'] == 1 ? 'Active' : 'Suspended',
                          color: user['is_verified'] == 1
                              ? Colors.green
                              : Colors.red,
                        ),
                      ]),

                      // Saved Details
                      if (savedDetails.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionTitle('Saved Details'),
                        _infoCard([
                          if (savedDetails['full_name'] != null &&
                              savedDetails['full_name'].toString().isNotEmpty)
                            _infoItem(
                              Icons.person,
                              'Full Name',
                              savedDetails['full_name'].toString(),
                            ),
                          if (savedDetails['father_name'] != null &&
                              savedDetails['father_name'].toString().isNotEmpty)
                            _infoItem(
                              Icons.person_outline,
                              'Father Name',
                              savedDetails['father_name'].toString(),
                            ),
                          if (savedDetails['mother_name'] != null &&
                              savedDetails['mother_name'].toString().isNotEmpty)
                            _infoItem(
                              Icons.person_outline,
                              'Mother Name',
                              savedDetails['mother_name'].toString(),
                            ),
                          if (savedDetails['dob'] != null &&
                              savedDetails['dob'].toString().isNotEmpty)
                            _infoItem(
                              Icons.cake,
                              'Date of Birth',
                              savedDetails['dob'].toString(),
                            ),
                          if (savedDetails['gender'] != null &&
                              savedDetails['gender'].toString().isNotEmpty)
                            _infoItem(
                              Icons.people,
                              'Gender',
                              savedDetails['gender'].toString(),
                            ),
                          if (savedDetails['aadhaar_number'] != null &&
                              savedDetails['aadhaar_number']
                                  .toString()
                                  .isNotEmpty)
                            _infoItem(
                              Icons.fingerprint,
                              'Aadhaar',
                              savedDetails['aadhaar_number'].toString(),
                            ),
                          if (savedDetails['pan_number'] != null &&
                              savedDetails['pan_number'].toString().isNotEmpty)
                            _infoItem(
                              Icons.credit_card,
                              'PAN',
                              savedDetails['pan_number'].toString(),
                            ),
                        ]),

                        // Address
                        if (savedDetails['address_line1'] != null &&
                            savedDetails['address_line1']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionTitle('Address'),
                          _infoCard([
                            _infoItem(
                              Icons.home,
                              'Address',
                              '${savedDetails['address_line1'] ?? ''}${savedDetails['address_line2'] != null && savedDetails['address_line2'].toString().isNotEmpty ? ', ${savedDetails['address_line2']}' : ''}, ${savedDetails['city'] ?? ''}, ${savedDetails['state'] ?? ''} - ${savedDetails['pincode'] ?? ''}',
                            ),
                          ]),
                        ],
                      ],

                      // Uploaded Documents - WITH VIEW/DOWNLOAD
                      const SizedBox(height: 16),
                      _sectionTitle('Uploaded Documents (${documents.length})'),
                      if (documents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No documents uploaded',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...documents.map((doc) => _buildDocumentTile(doc)),

                      // Applications
                      const SizedBox(height: 16),
                      _sectionTitle('Applications (${applications.length})'),
                      if (applications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No applications',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...applications.map(
                          (app) => ListTile(
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: statusColor(app['status']).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.receipt,
                                color: statusColor(app['status']),
                                size: 16,
                              ),
                            ),
                            title: Text(
                              app['service_name'] ?? 'Service',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${app['tracking_id']} • ${(app['status'] ?? '').toString().toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DOCUMENT TILE ====================

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final docType = doc['doc_type'] ?? '';
    final docName = doc['doc_name'] ?? doc['file_name'] ?? 'Unknown';
    final filePath = doc['file_path'] ?? '';
    final isImage =
        docName.endsWith('.jpg') ||
        docName.endsWith('.jpeg') ||
        docName.endsWith('.png');
    final isPdf = docName.endsWith('.pdf');

    IconData icon = _getDocIcon(docType);
    Color color = const Color(0xFF1A237E);

    if (isPdf) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (isImage) {
      icon = Icons.image;
      color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDocLabel(docType),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  docName,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (filePath.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
              onPressed: () => _viewDocument(filePath, docName),
              tooltip: 'View Document',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 18, color: Colors.green),
              onPressed: () => _downloadDocument(filePath, docName),
              tooltip: 'Download',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _getDocLabel(String type) {
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

  IconData _getDocIcon(String type) {
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

  // ==================== USER MANAGEMENT DIALOGS ====================

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add User',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
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
                      await http.post(
                        Uri.parse('${widget.baseUrl}/users/add'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'mobile': mobileCtrl.text,
                          'password': passCtrl.text,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadUsers();
                      if (mounted) showSnackBar(context, 'User added');
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

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    final mobileCtrl = TextEditingController(text: user['mobile']);
    final passCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Edit User',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (leave blank)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
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
                        Uri.parse('${widget.baseUrl}/users/${user['id']}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'mobile': mobileCtrl.text,
                          'password': passCtrl.text,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadUsers();
                      if (mounted) showSnackBar(context, 'User updated');
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
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
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
      await http.delete(Uri.parse('${widget.baseUrl}/users/$userId'));
      _loadUsers();
      if (mounted) showSnackBar(context, 'User deleted');
    }
  }

  void _suspendUser(int userId, bool isSuspended) async {
    final action = isSuspended ? 'reactivate' : 'suspend';
    await http.put(
      Uri.parse('${widget.baseUrl}/users/$userId/suspend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': action}),
    );
    _loadUsers();
    if (mounted) {
      showSnackBar(
        context,
        isSuspended ? 'User reactivated' : 'User suspended',
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${_users.length} Users',
                    style: TextStyle(
                      fontSize: isPhone ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  if (!isPhone)
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.person_add,
                        color: Color(0xFF1A237E),
                      ),
                      onPressed: _showAddUserDialog,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                )
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 16),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final u = filtered[i];
                    final isSuspended = u['is_verified'] == 0;
                    final date = (u['created_at'] ?? '').toString();
                    final joinDate = date.length >= 10
                        ? date.substring(0, 10)
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuspended
                              ? Colors.red.withAlpha(30)
                              : Colors.green.withAlpha(30),
                          radius: isPhone ? 18 : 22,
                          child: Icon(
                            isSuspended ? Icons.block : Icons.person,
                            color: isSuspended ? Colors.red : Colors.green,
                            size: isPhone ? 18 : 22,
                          ),
                        ),
                        title: Text(
                          u['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 13 : 14,
                            color: isSuspended ? Colors.red : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['email'] ?? '',
                              style: TextStyle(fontSize: isPhone ? 10 : 11),
                            ),
                            Text(
                              '${u['mobile']} • Joined: $joinDate',
                              style: TextStyle(
                                fontSize: isPhone ? 9 : 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _viewUserDetails(u),
                        trailing: isPhone
                            ? PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _showEditUserDialog(u);
                                  if (action == 'delete') _deleteUser(u['id']);
                                  if (action == 'suspend') {
                                    _suspendUser(u['id'], isSuspended);
                                  }
                                  if (action == 'view') _viewUserDetails(u);
                                },
                                itemBuilder: (c) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
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
                                    value: 'suspend',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSuspended
                                              ? Icons.check_circle
                                              : Icons.block,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          isSuspended
                                              ? 'Reactivate'
                                              : 'Suspend',
                                          style: TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
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
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _viewUserDetails(u),
                                    tooltip: 'View Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _showEditUserDialog(u),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isSuspended
                                          ? Icons.check_circle
                                          : Icons.block,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _suspendUser(u['id'], isSuspended),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteUser(u['id']),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
