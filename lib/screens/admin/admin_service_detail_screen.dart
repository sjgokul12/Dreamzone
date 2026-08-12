import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'admin_helpers.dart';

class AdminServiceDetailScreen extends StatefulWidget {
  final String baseUrl;
  final int serviceId;
  final String serviceName;
  const AdminServiceDetailScreen({
    super.key,
    required this.baseUrl,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<AdminServiceDetailScreen> createState() =>
      _AdminServiceDetailScreenState();
}

class _AdminServiceDetailScreenState extends State<AdminServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _service = {};
  List<dynamic> _forms = [];
  List<dynamic> _applications = [];
  List<dynamic> _sections = [];
  bool _loading = true;
  int? _selectedFormId;

  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _benefitsCtrl = TextEditingController();
  final _eligibilityCtrl = TextEditingController();
  final _processCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _detailCtrl.dispose();
    _benefitsCtrl.dispose();
    _eligibilityCtrl.dispose();
    _processCtrl.dispose();
    _iconCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  bool get isPhone => MediaQuery.of(context).size.width < 600;

  String _imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return '';
    String path = relativePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final root = widget.baseUrl.endsWith('/api')
        ? widget.baseUrl.substring(0, widget.baseUrl.length - 4)
        : widget.baseUrl;
    if (path.startsWith('/')) path = path.substring(1);
    return '$root/$path';
  }

  // ==================== OPTION HELPERS (NEW) ====================
  // Splits a comma-separated options string into a clean, trimmed list.
  // Used EVERYWHERE options are parsed so admin (parent picker) and
  // public app (dropdown values) always agree on the exact same strings.
  List<String> _parseOptions(String? raw) {
    if (raw == null) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Re-joins a raw, possibly messy "a, b ,c" string into a clean
  // "a,b,c" string before saving to the backend.
  String _normalizeOptionsForSave(String raw) {
    return _parseOptions(raw).join(',');
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/services/${widget.serviceId}/full'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _service = data['service'];
          _forms = data['service']['forms'] ?? [];
          _populateControllers();
          if (_forms.isNotEmpty && _selectedFormId == null) {
            _selectedFormId = _forms.first['id'] as int;
            _loadSections(_selectedFormId!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadApplications() async {
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/applications'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _applications = (data['applications'] as List)
              .where((app) => app['service_id'] == widget.serviceId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadSections(int formId) async {
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/form-fields/$formId/sections'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _sections = data['sections']);
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  void _populateControllers() {
    _nameCtrl.text = _service['name'] ?? '';
    _categoryCtrl.text = _service['category'] ?? '';
    _descCtrl.text = _service['description'] ?? '';
    _detailCtrl.text = _service['detail_content'] ?? '';
    _benefitsCtrl.text = _service['benefits'] ?? '';
    _eligibilityCtrl.text = _service['eligibility'] ?? '';
    _processCtrl.text = _service['process_steps'] ?? '';
    _iconCtrl.text = _service['icon'] ?? '';
    _colorCtrl.text = _service['color'] ?? '';
  }

  Future<void> _saveContent() async {
    final res = await http.put(
      Uri.parse('${widget.baseUrl}/services/${widget.serviceId}/content'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'detail_content': _detailCtrl.text,
        'benefits': _benefitsCtrl.text,
        'eligibility': _eligibilityCtrl.text,
        'process_steps': _processCtrl.text,
        'icon': _iconCtrl.text,
        'color': _colorCtrl.text,
      }),
    );
    final data = jsonDecode(res.body);
    if (mounted) showSnackBar(context, data['message'] ?? 'Saved!');
  }

  // ==================== SERVICE IMAGE UPLOAD ====================
  Future<void> _pickAndUploadServiceImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Uploading image...'),
            ],
          ),
        ),
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${widget.baseUrl}/services/${widget.serviceId}/upload-image',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', file.bytes!, filename: file.name),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (mounted) Navigator.pop(context);

      if (data['success'] == true) {
        setState(() => _service['image_url'] = data['image_url']);
        if (mounted) showSnackBar(context, 'Service image updated');
      } else {
        if (mounted) {
          showSnackBar(
            context,
            data['message'] ?? 'Upload failed',
            success: false,
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) showSnackBar(context, 'Upload error: $e', success: false);
    }
  }

  // ==================== AGE VALIDATION ====================
  // CHANGED: age validation used to only ever be added to the FIRST
  // section of a form. Since each section is a separate "application
  // type" with its own fields, that meant only one section actually
  // asked for DOB / showed parent-guardian fields for minors. This is
  // now applied to EVERY section in the form in one click, and skips
  // any section that already has its own 'date_of_birth' field so
  // clicking the button again is safe (no duplicates).

  bool _sectionHasDobField(Map<String, dynamic> section) {
    for (var f in (section['fields'] ?? [])) {
      if ((f['field_name'] ?? '').toString().toLowerCase() == 'date_of_birth') {
        return true;
      }
    }
    return false;
  }

  Future<void> _addAgeValidationForWholeForm(int formId) async {
    final targetSections = _sections
        .where((s) => !_sectionHasDobField(s))
        .toList();

    if (targetSections.isEmpty) {
      showSnackBar(
        context,
        'Every section already has a Date of Birth field — nothing to add.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1A237E)),
            SizedBox(height: 16),
            Text('Adding age validation to the whole form...'),
          ],
        ),
      ),
    );

    int successCount = 0;
    for (var section in targetSections) {
      final ok = await _addAgeValidationToSection(formId, section['id']);
      if (ok) successCount++;
    }

    if (mounted) Navigator.pop(context);
    _loadSections(_selectedFormId ?? formId);
    _loadData();
    if (mounted) {
      showSnackBar(
        context,
        '✅ Age validation added to $successCount of ${targetSections.length} section(s).',
      );
    }
  }

  // Adds a Date of Birth field + conditional parent/guardian fields to
  // ONE section. Returns true on success. Does not show its own
  // loading dialog or snackbar — callers (single-section or
  // whole-form) handle that so multi-section runs show one dialog.
  Future<bool> _addAgeValidationToSection(int formId, int sectionId) async {
    try {
      final dobField = {
        'form_id': formId,
        'section_id': sectionId,
        'field_name': 'date_of_birth',
        'field_label': 'Date of Birth',
        'field_type': 'date',
        'is_required': 1,
        'placeholder': 'Select your date of birth',
        'select_options': '',
        'parent_field_id': null,
        'show_when_value': '',
        'help_text': 'Your date of birth (DD/MM/YYYY) - Age will be validated',
        'field_group': '',
        'sort_order': 0,
      };

      await http.post(
        Uri.parse('${widget.baseUrl}/form-fields-v2'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dobField),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final fieldsRes = await http.get(
        Uri.parse('${widget.baseUrl}/form-fields/$formId/sections'),
      );
      final fieldsData = jsonDecode(fieldsRes.body);

      int dobFieldId = 0;
      for (var section in fieldsData['sections']) {
        if (section['id'] == sectionId) {
          for (var field in section['fields']) {
            if (field['field_name'] == 'date_of_birth') {
              dobFieldId = field['id'];
              break;
            }
          }
          break;
        }
      }

      if (dobFieldId == 0) {
        return false;
      }

      final parentFields = [
        {
          'field_name': 'parent_full_name',
          'field_label': 'Parent/Guardian Full Name',
          'field_type': 'text',
          'is_required': 1,
          'placeholder': 'Enter parent/guardian full name',
          'help_text': 'Required if you are under 18',
        },
        {
          'field_name': 'parent_relationship',
          'field_label': 'Relationship with Parent/Guardian',
          'field_type': 'select',
          'is_required': 1,
          'placeholder': 'Select relationship',
          'select_options': 'Father,Mother,Guardian,Other',
          'help_text': 'Relationship with parent/guardian',
        },
        {
          'field_name': 'parent_mobile',
          'field_label': 'Parent/Guardian Mobile Number',
          'field_type': 'phone',
          'is_required': 1,
          'placeholder': 'Enter parent/guardian mobile number',
          'help_text': 'Parent/guardian contact number',
        },
        {
          'field_name': 'parent_email',
          'field_label': 'Parent/Guardian Email',
          'field_type': 'email',
          'is_required': 1,
          'placeholder': 'Enter parent/guardian email',
          'help_text': 'Parent/guardian email address',
        },
        {
          'field_name': 'parent_address',
          'field_label': 'Parent/Guardian Address',
          'field_type': 'textarea',
          'is_required': 0,
          'placeholder': 'Enter parent/guardian full address',
          'help_text': 'Optional - parent/guardian address',
        },
        {
          'field_name': 'minor_consent',
          'field_label': 'I have parent/guardian consent to apply',
          'field_type': 'checkbox',
          'is_required': 1,
          'placeholder': '',
          'help_text':
              'Parent/guardian consent is required for minor applicants',
        },
      ];

      for (var i = 0; i < parentFields.length; i++) {
        final field = parentFields[i];
        field['form_id'] = formId;
        field['section_id'] = sectionId;
        field['sort_order'] = i + 1;
        field['parent_field_id'] = dobFieldId;
        field['show_when_value'] = 'minor';
        field['field_group'] = 'Parent/Guardian Details';

        await http.post(
          Uri.parse('${widget.baseUrl}/form-fields-v2'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(field),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error adding age validation to section $sectionId: $e');
      return false;
    }
  }

  // ==================== SECTION DOCUMENTS CRUD ====================

  Future<void> _addSectionDocument(
    int sectionId,
    String docName,
    bool mandatory,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/section-documents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'section_id': sectionId,
          'doc_name': docName,
          'is_mandatory': mandatory ? 1 : 0,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (mounted) showSnackBar(context, 'Document added');
        _loadSections(_selectedFormId!);
      } else {
        if (mounted) {
          showSnackBar(context, data['message'] ?? 'Failed', success: false);
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Error: $e', success: false);
    }
  }

  Future<void> _deleteSectionDocument(int docId) async {
    try {
      final res = await http.delete(
        Uri.parse('${widget.baseUrl}/section-documents/$docId'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (mounted) showSnackBar(context, 'Document deleted');
        _loadSections(_selectedFormId!);
      } else {
        if (mounted) {
          showSnackBar(context, data['message'] ?? 'Failed', success: false);
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Error: $e', success: false);
    }
  }

  // ==================== FORM DIALOGS ====================
  void _showAddFormDialog() {
    final titleCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: 'Varies');
    final timeCtrl = TextEditingController(text: '3-7 Days');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Create Application Form',
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
                  labelText: 'Form Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fee',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: timeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Processing Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                    ),
                  ),
                ],
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
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await http.post(
                Uri.parse('${widget.baseUrl}/service-forms'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'service_id': widget.serviceId,
                  'form_title': titleCtrl.text,
                  'fee': feeCtrl.text,
                  'processing_time': timeCtrl.text,
                }),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Form'),
          ),
        ],
      ),
    );
  }

  void _showEditFormDialog(Map<String, dynamic> form) {
    final titleCtrl = TextEditingController(text: form['form_title']);
    final feeCtrl = TextEditingController(text: form['fee']);
    final timeCtrl = TextEditingController(text: form['processing_time']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Edit Form',
          style: TextStyle(color: Color(0xFF1A237E)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Form Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fee',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Processing Time',
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
            onPressed: () async {
              await http.put(
                Uri.parse('${widget.baseUrl}/service-forms/${form['id']}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'form_title': titleCtrl.text,
                  'fee': feeCtrl.text,
                  'processing_time': timeCtrl.text,
                }),
              );
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
    );
  }

  // ==================== SECTION MANAGEMENT ====================
  void _showAddSectionDialog(int formId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: 'Varies');
    final timeCtrl = TextEditingController(text: '3-7 Days');
    Uint8List? pickedBytes;
    String? pickedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add Section',
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
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section Name',
                    hintText: 'e.g., New PAN Apply',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (shown on "About This Service")',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: feeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fee',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Processing Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Section Image (shown in popup & detail header)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null &&
                        result.files.isNotEmpty &&
                        result.files.first.bytes != null) {
                      setDialogState(() {
                        pickedBytes = result.files.first.bytes;
                        pickedFileName = result.files.first.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[50],
                    ),
                    child: pickedBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              pickedBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Colors.grey[400],
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to select image',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
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
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;

                final res = await http.post(
                  Uri.parse('${widget.baseUrl}/form-sections-v2'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'form_id': formId,
                    'section_name': nameCtrl.text,
                    'section_order': _sections.length,
                    'description': descCtrl.text,
                    'fee': feeCtrl.text,
                    'processing_time': timeCtrl.text,
                  }),
                );
                final data = jsonDecode(res.body);
                final newSectionId = data['section_id'];

                if (pickedBytes != null && newSectionId != null) {
                  var request = http.MultipartRequest(
                    'POST',
                    Uri.parse(
                      '${widget.baseUrl}/form-sections/$newSectionId/upload-image',
                    ),
                  );
                  request.files.add(
                    http.MultipartFile.fromBytes(
                      'image',
                      pickedBytes!,
                      filename: pickedFileName ?? 'section.jpg',
                    ),
                  );
                  await request.send();
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadSections(formId);
                if (mounted) showSnackBar(context, 'Section added');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSectionDialog(Map<String, dynamic> section, int formId) {
    final nameCtrl = TextEditingController(text: section['section_name'] ?? '');
    final descCtrl = TextEditingController(text: section['description'] ?? '');
    final feeCtrl = TextEditingController(text: section['fee'] ?? 'Varies');
    final timeCtrl = TextEditingController(
      text: section['processing_time'] ?? '3-7 Days',
    );
    Uint8List? pickedBytes;
    String? pickedFileName;
    final existingImage = section['image_url']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Edit Section',
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
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: feeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fee',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Processing Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Section Image',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null &&
                        result.files.isNotEmpty &&
                        result.files.first.bytes != null) {
                      setDialogState(() {
                        pickedBytes = result.files.first.bytes;
                        pickedFileName = result.files.first.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[50],
                    ),
                    child: pickedBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              pickedBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : (existingImage != null && existingImage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _imageUrl(existingImage),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (c, e, s) => Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.grey[400],
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to select image',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                )),
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
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;

                await http.put(
                  Uri.parse(
                    '${widget.baseUrl}/form-sections/${section['id']}/details',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'section_name': nameCtrl.text,
                    'description': descCtrl.text,
                    'icon': section['icon'] ?? '',
                    'color': section['color'] ?? '',
                    'fee': feeCtrl.text,
                    'processing_time': timeCtrl.text,
                  }),
                );

                if (pickedBytes != null) {
                  var request = http.MultipartRequest(
                    'POST',
                    Uri.parse(
                      '${widget.baseUrl}/form-sections/${section['id']}/upload-image',
                    ),
                  );
                  request.files.add(
                    http.MultipartFile.fromBytes(
                      'image',
                      pickedBytes!,
                      filename: pickedFileName ?? 'section.jpg',
                    ),
                  );
                  await request.send();
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadSections(formId);
                if (mounted) showSnackBar(context, 'Section updated');
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

  void _deleteSection(int sectionId) async {
    await http.delete(Uri.parse('${widget.baseUrl}/form-sections/$sectionId'));
    if (_selectedFormId != null) _loadSections(_selectedFormId!);
    if (mounted) showSnackBar(context, 'Section deleted');
  }

  // ==================== FIELD MANAGEMENT ====================

  List<dynamic> _getAllFieldsForForm(int formId) {
    final allFields = <dynamic>[];
    for (var section in _sections) {
      if (section['fields'] != null) {
        allFields.addAll(List<dynamic>.from(section['fields']));
      }
    }
    return allFields;
  }

  // NEW: fields belonging to one specific section only. Conditional
  // "show when" parents should normally come from the SAME section as
  // the field being added, otherwise the parent question is never asked
  // together with the child and the child can never be shown.
  List<dynamic> _getFieldsForSection(int? sectionId) {
    if (sectionId == null) return [];
    for (var section in _sections) {
      if (section['id'] == sectionId) {
        return List<dynamic>.from(section['fields'] ?? []);
      }
    }
    return [];
  }

  List<String> _getExistingGroups(int formId) {
    final groups = <String>{};
    for (var f in _getAllFieldsForForm(formId)) {
      final g = (f['field_group'] ?? '').toString().trim();
      if (g.isNotEmpty) groups.add(g);
    }
    return groups.toList()..sort();
  }

  // ==================== ADD FIELD DIALOG ====================
  void _showAddFieldDialog(int formId, {int? sectionId}) {
    final nameCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final placeholderCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    final helpCtrl = TextEditingController();
    final showWhenCtrl = TextEditingController();
    final groupCtrl = TextEditingController();

    String type = 'text';
    bool required = true;
    int? parentFieldId;
    // CHANGED: a field can now be revealed by MORE THAN ONE parent
    // option (checkbox-based), instead of exactly one dropdown value.
    Set<String> selectedTriggerValues = {};

    final existingGroups = _getExistingGroups(formId);

    List<String> parentOptions = [];

    // Recomputed every time the chosen section changes, so the parent
    // picker only ever lists select-fields that live in the SAME
    // section as the field currently being created.
    List<dynamic> selectFieldsFor(int? forSectionId) {
      return _getFieldsForSection(forSectionId)
          .where(
            (f) =>
                f['field_type'] == 'select' || f['field_type'] == 'multiselect',
          )
          .toList();
    }

    void updateParentOptions(int? newParentId, List<dynamic> selectFields) {
      if (newParentId != null) {
        final parent = selectFields.firstWhere(
          (f) => f['id'] == newParentId,
          orElse: () => null,
        );
        if (parent != null &&
            (parent['field_type'] == 'select' ||
                parent['field_type'] == 'multiselect')) {
          parentOptions = _parseOptions(parent['select_options']?.toString());
        } else {
          parentOptions = [];
        }
      } else {
        parentOptions = [];
      }
      // Keep only the previously ticked boxes that are still valid
      // options for the newly chosen parent field.
      selectedTriggerValues = selectedTriggerValues
          .where((v) => parentOptions.contains(v))
          .toSet();
      showWhenCtrl.text = selectedTriggerValues.join(',');
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectFields = selectFieldsFor(sectionId);
          // If the previously chosen parent no longer belongs to the
          // currently selected section, clear it instead of silently
          // keeping a "invisible" cross-section parent.
          if (parentFieldId != null &&
              !selectFields.any((f) => f['id'] == parentFieldId)) {
            parentFieldId = null;
            parentOptions = [];
            selectedTriggerValues = {};
            showWhenCtrl.text = '';
          }

          return AlertDialog(
            title: const Text(
              'Add Form Field',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section
                    if (_sections.isNotEmpty) ...[
                      const Text(
                        'Section',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        initialValue: sectionId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Section'),
                          ),
                          ..._sections.map<DropdownMenuItem<int>>(
                            (s) => DropdownMenuItem(
                              value: s['id'],
                              child: Text(s['section_name'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (v) => setDialogState(() {
                          sectionId = v;
                          // Changing section invalidates any previously
                          // chosen conditional-display parent.
                          parentFieldId = null;
                          parentOptions = [];
                          selectedTriggerValues = {};
                          showWhenCtrl.text = '';
                        }),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Field Group
                    const Text(
                      'Field Group (numbered header on form)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: groupCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g., Personal Information',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        suffixIcon: existingGroups.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (v) => groupCtrl.text = v,
                                itemBuilder: (c) => existingGroups
                                    .map(
                                      (g) => PopupMenuItem(
                                        value: g,
                                        child: Text(
                                          g,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fields with the same group name are shown together under one numbered header. Leave blank to show ungrouped.',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 14),

                    // Field Name
                    const Text(
                      'Field Name (no spaces)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., full_name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Label
                    const Text(
                      'Display Label',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Full Name as per PAN',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field Type
                    const Text(
                      'Field Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items:
                          [
                                'text',
                                'email',
                                'phone',
                                'number',
                                'date',
                                'textarea',
                                'select',
                                'multiselect',
                                'file',
                                'aadhaar',
                                'pan',
                                'checkbox',
                              ]
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          setDialogState(() => type = v ?? 'text'),
                    ),
                    const SizedBox(height: 10),

                    // Required
                    SwitchListTile(
                      title: const Text('Required Field'),
                      value: required,
                      onChanged: (v) => setDialogState(() => required = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Placeholder
                    const SizedBox(height: 5),
                    const Text(
                      'Placeholder Text',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: placeholderCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Enter your full name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Help Text
                    const Text(
                      'Help Text (shown below field)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: helpCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., As per your Aadhaar card',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),

                    // Options for select type
                    if (type == 'select' || type == 'multiselect') ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Options (comma separated)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          hintText: 'New PAN,Correction,Duplicate',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tip: extra spaces around commas are fine, they are trimmed automatically.',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],

                    // Conditional Display
                    if (selectFields.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withAlpha(40),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'CONDITIONAL DISPLAY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Show this field when a dropdown field in the SAME section is set to ANY of the ticked options below',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Show when:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField<int>(
                              initialValue: parentFieldId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Always visible'),
                                ),
                                ...selectFields.map<DropdownMenuItem<int>>(
                                  (f) => DropdownMenuItem(
                                    value: f['id'],
                                    child: Text(
                                      'When "${f['field_label']}" is...',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                setDialogState(() {
                                  parentFieldId = v;
                                  updateParentOptions(v, selectFields);
                                });
                              },
                            ),
                            if (parentFieldId != null) ...[
                              const SizedBox(height: 8),
                              if (parentOptions.isNotEmpty) ...[
                                const Text(
                                  'Tick every option that should reveal this field *',
                                  style: TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: parentOptions.map((opt) {
                                        final checked = selectedTriggerValues
                                            .contains(opt);
                                        return CheckboxListTile(
                                          dense: true,
                                          value: checked,
                                          title: Text(
                                            opt,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: const Color(0xFF1A237E),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              if (v == true) {
                                                selectedTriggerValues.add(opt);
                                              } else {
                                                selectedTriggerValues.remove(
                                                  opt,
                                                );
                                              }
                                              showWhenCtrl.text =
                                                  selectedTriggerValues.join(
                                                    ',',
                                                  );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ] else
                                const Text(
                                  'Selected parent field has no options yet.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
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
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || labelCtrl.text.isEmpty) {
                    showSnackBar(
                      context,
                      'Field name and label are required',
                      success: false,
                    );
                    return;
                  }
                  // Guard against the exact bug we found in the data:
                  // a parent chosen but no "show when" value picked.
                  if (parentFieldId != null &&
                      showWhenCtrl.text.trim().isEmpty) {
                    showSnackBar(
                      context,
                      'Please tick at least one option that should reveal this field',
                      success: false,
                    );
                    return;
                  }
                  final normalizedOptions =
                      (type == 'select' || type == 'multiselect')
                      ? _normalizeOptionsForSave(optionsCtrl.text)
                      : '';
                  await http.post(
                    Uri.parse('${widget.baseUrl}/form-fields-v2'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'form_id': formId,
                      'section_id': sectionId,
                      'field_name': nameCtrl.text.trim(),
                      'field_label': labelCtrl.text.trim(),
                      'field_type': type,
                      'is_required': required ? 1 : 0,
                      'placeholder': placeholderCtrl.text,
                      'select_options': normalizedOptions,
                      'parent_field_id': parentFieldId,
                      'show_when_value': showWhenCtrl.text.trim(),
                      'help_text': helpCtrl.text,
                      'field_group': groupCtrl.text.trim(),
                      'sort_order': 0,
                    }),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (sectionId != null) {
                    _loadSections(formId);
                  }
                  _loadData();
                  if (mounted) {
                    showSnackBar(context, 'Field added successfully');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Field'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== EDIT FIELD DIALOG (FIXED) ====================
  void _showEditFieldDialog(Map<String, dynamic> field) {
    final fieldId = field['id'];
    final nameCtrl = TextEditingController(text: field['field_name'] ?? '');
    final labelCtrl = TextEditingController(text: field['field_label'] ?? '');
    final placeholderCtrl = TextEditingController(
      text: field['placeholder'] ?? '',
    );
    final optionsCtrl = TextEditingController(
      text: field['select_options'] ?? '',
    );
    final helpCtrl = TextEditingController(text: field['help_text'] ?? '');
    final showWhenCtrl = TextEditingController(
      text: field['show_when_value'] ?? '',
    );
    final groupCtrl = TextEditingController(text: field['field_group'] ?? '');

    String type = field['field_type'] ?? 'text';
    bool required = (field['is_required'] ?? 0) == 1;
    int? parentFieldId = field['parent_field_id'];
    int? sectionId = field['section_id'];
    bool saving = false;

    // CHANGED: show_when_value may now hold multiple, comma-separated
    // trigger options (checkbox-based) instead of exactly one value.
    Set<String> selectedTriggerValues = (field['show_when_value'] ?? '')
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final existingGroups = _getExistingGroups(_selectedFormId!);

    List<dynamic> selectFieldsFor(int? forSectionId) {
      return _getFieldsForSection(forSectionId)
          .where(
            (f) =>
                (f['field_type'] == 'select' ||
                    f['field_type'] == 'multiselect') &&
                f['id'] != fieldId,
          )
          .toList();
    }

    if (sectionId != null && !_sections.any((s) => s['id'] == sectionId)) {
      sectionId = null;
    }

    // --- FIX: If parentFieldId is not among select fields of THIS
    // section, reset it (covers both "field deleted" and "parent lives
    // in a different section" cases). ---
    if (parentFieldId != null &&
        !selectFieldsFor(sectionId).any((f) => f['id'] == parentFieldId)) {
      parentFieldId = null;
      selectedTriggerValues = {};
      showWhenCtrl.text = '';
    }

    List<String> parentOptions = [];
    void updateParentOptions(int? newParentId, List<dynamic> selectFields) {
      if (newParentId != null) {
        final parent = selectFields.firstWhere(
          (f) => f['id'] == newParentId,
          orElse: () => null,
        );
        if (parent != null &&
            (parent['field_type'] == 'select' ||
                parent['field_type'] == 'multiselect')) {
          parentOptions = _parseOptions(parent['select_options']?.toString());
        } else {
          parentOptions = [];
        }
      } else {
        parentOptions = [];
      }
      // Keep only the ticks that are still valid options for the
      // (possibly newly) chosen parent field.
      selectedTriggerValues = selectedTriggerValues
          .where((v) => parentOptions.contains(v))
          .toSet();
      showWhenCtrl.text = selectedTriggerValues.join(',');
    }

    // Initialize parent options if parentFieldId is already set (uses
    // the current section's select fields).
    if (parentFieldId != null) {
      updateParentOptions(parentFieldId, selectFieldsFor(sectionId));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectFields = selectFieldsFor(sectionId);
          if (parentFieldId != null &&
              !selectFields.any((f) => f['id'] == parentFieldId)) {
            parentFieldId = null;
            parentOptions = [];
            selectedTriggerValues = {};
            showWhenCtrl.text = '';
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1A237E),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Edit Field',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section
                    if (_sections.isNotEmpty) ...[
                      const Text(
                        'Section',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        initialValue: sectionId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Section'),
                          ),
                          ..._sections.map<DropdownMenuItem<int>>((s) {
                            return DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text(
                                s['section_name'] ?? 'Section ${s['id']}',
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setDialogState(() {
                          sectionId = v;
                          parentFieldId = null;
                          parentOptions = [];
                          selectedTriggerValues = {};
                          showWhenCtrl.text = '';
                        }),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Field Group
                    const Text(
                      'Field Group (numbered header on form)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: groupCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g., Personal Information',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        suffixIcon: existingGroups.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (v) => groupCtrl.text = v,
                                itemBuilder: (c) => existingGroups
                                    .map(
                                      (g) => PopupMenuItem(
                                        value: g,
                                        child: Text(
                                          g,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field Name
                    const Text(
                      'Field Name (no spaces)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., full_name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Label
                    const Text(
                      'Display Label',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Full Name as per PAN',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field Type
                    const Text(
                      'Field Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items:
                          [
                                'text',
                                'email',
                                'phone',
                                'number',
                                'date',
                                'textarea',
                                'select',
                                'multiselect',
                                'file',
                                'aadhaar',
                                'pan',
                                'checkbox',
                              ]
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          setDialogState(() => type = v ?? 'text'),
                    ),
                    const SizedBox(height: 10),

                    // Required
                    SwitchListTile(
                      title: const Text('Required Field'),
                      value: required,
                      onChanged: (v) => setDialogState(() => required = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Placeholder
                    const SizedBox(height: 5),
                    const Text(
                      'Placeholder Text',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: placeholderCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Enter your full name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Help Text
                    const Text(
                      'Help Text (shown below field)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: helpCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., As per your Aadhaar card',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),

                    // Options for select type
                    if (type == 'select' || type == 'multiselect') ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Options (comma separated)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          hintText: 'New PAN,Correction,Duplicate',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tip: extra spaces around commas are fine, they are trimmed automatically.',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],

                    // Conditional Display
                    if (selectFields.isNotEmpty || parentFieldId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withAlpha(40),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'CONDITIONAL DISPLAY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Show this field when a dropdown field in the SAME section is set to ANY of the ticked options below',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Show when:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField<int>(
                              initialValue: parentFieldId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Always visible'),
                                ),
                                ...selectFields.map<DropdownMenuItem<int>>((f) {
                                  return DropdownMenuItem<int>(
                                    value: f['id'] as int,
                                    child: Text(
                                      'When "${f['field_label']}" is...',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (v) {
                                setDialogState(() {
                                  parentFieldId = v;
                                  updateParentOptions(v, selectFields);
                                });
                              },
                            ),
                            if (parentFieldId != null) ...[
                              const SizedBox(height: 8),
                              if (parentOptions.isNotEmpty) ...[
                                const Text(
                                  'Tick every option that should reveal this field *',
                                  style: TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: parentOptions.map((opt) {
                                        final checked = selectedTriggerValues
                                            .contains(opt);
                                        return CheckboxListTile(
                                          dense: true,
                                          value: checked,
                                          title: Text(
                                            opt,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: const Color(0xFF1A237E),
                                          onChanged: (v) {
                                            setDialogState(() {
                                              if (v == true) {
                                                selectedTriggerValues.add(opt);
                                              } else {
                                                selectedTriggerValues.remove(
                                                  opt,
                                                );
                                              }
                                              showWhenCtrl.text =
                                                  selectedTriggerValues.join(
                                                    ',',
                                                  );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ] else
                                const Text(
                                  'Selected parent field has no options yet.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF1A237E)),
                ),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameCtrl.text.isEmpty || labelCtrl.text.isEmpty) {
                          showSnackBar(
                            context,
                            'Field name and label are required',
                            success: false,
                          );
                          return;
                        }
                        // Guard against saving a "dangling" condition
                        // (parent picked, but no option chosen).
                        if (parentFieldId != null &&
                            showWhenCtrl.text.trim().isEmpty) {
                          showSnackBar(
                            context,
                            'Please tick at least one option that should reveal this field',
                            success: false,
                          );
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          final normalizedOptions =
                              (type == 'select' || type == 'multiselect')
                              ? _normalizeOptionsForSave(optionsCtrl.text)
                              : '';
                          await http.put(
                            Uri.parse(
                              '${widget.baseUrl}/form-fields-v2/$fieldId',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'field_name': nameCtrl.text.trim(),
                              'field_label': labelCtrl.text.trim(),
                              'field_type': type,
                              'is_required': required ? 1 : 0,
                              'placeholder': placeholderCtrl.text,
                              'select_options': normalizedOptions,
                              'parent_field_id': parentFieldId,
                              'show_when_value': showWhenCtrl.text.trim(),
                              'help_text': helpCtrl.text,
                              'field_group': groupCtrl.text.trim(),
                              'section_id': sectionId,
                            }),
                          );
                          setDialogState(() => saving = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (sectionId != null) {
                            _loadSections(_selectedFormId!);
                          }
                          _loadData();
                          if (mounted) {
                            showSnackBar(context, 'Field updated successfully');
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            showSnackBar(
                              context,
                              'Error updating field',
                              success: false,
                            );
                          }
                        }
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
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDocumentDialog(int formId) {
    final nameCtrl = TextEditingController();
    bool mandatory = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Required Document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document Name',
                    hintText: 'e.g., Identity Proof',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Mandatory'),
                  value: mandatory,
                  onChanged: (v) => setDialogState(() => mandatory = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
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
              onPressed: () async {
                await http.post(
                  Uri.parse('${widget.baseUrl}/documents'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'form_id': formId,
                    'doc_name': nameCtrl.text,
                    'is_mandatory': mandatory ? 1 : 0,
                  }),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteForm(int formId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Form'),
        content: const Text('This will delete all fields and documents too.'),
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
      await http.delete(Uri.parse('${widget.baseUrl}/service-forms/$formId'));
      _loadData();
    }
  }

  void _deleteField(int fieldId) async {
    await http.delete(Uri.parse('${widget.baseUrl}/form-fields/$fieldId'));
    if (_selectedFormId != null) _loadSections(_selectedFormId!);
    _loadData();
  }

  void _deleteDocument(int docId) async {
    await http.delete(Uri.parse('${widget.baseUrl}/documents/$docId'));
    _loadData();
  }

  void _duplicateForm(int formId) async {
    await http.post(
      Uri.parse('${widget.baseUrl}/service-forms/$formId/duplicate'),
    );
    _loadData();
    if (mounted) showSnackBar(context, 'Form duplicated!');
  }

  Color _parseColor(String c) {
    if (c.startsWith('0x') || c.startsWith('0X')) {
      return Color(int.tryParse(c) ?? 0xFF1A237E);
    }
    if (c.startsWith('#')) {
      return Color(int.tryParse('0xFF${c.substring(1)}') ?? 0xFF1A237E);
    }
    return const Color(0xFF1A237E);
  }

  // ==================== FILE VIEWING ====================
  void _viewApplicationFiles(int applicationId) async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.folder_open, color: Color(0xFF1A237E)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Files',
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
              ),
              builder: (c, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return const Center(child: Text('Error'));
                try {
                  final data = jsonDecode(snap.data!.body);
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
                            'No files',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (c, i) {
                      final f = files[i];
                      final name = f['file_name'] ?? '';
                      final path = f['file_path'] ?? '';
                      final exists = f['exists'] ?? false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            exists ? Icons.check_circle : Icons.error,
                            color: exists ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: exists
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => _openFile(path, name),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _downloadFile(path, name),
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
        ),
      ),
    );
  }

  void _openFile(String filePath, String fileName) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final viewUrl = '${widget.baseUrl}/view-file/$encodedPath';
      final uri = Uri.parse(viewUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Cannot open file', success: false);
      }
    }
  }

  void _downloadFile(String filePath, String fileName) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final downloadUrl = '${widget.baseUrl}/download-file/$encodedPath';
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) showSnackBar(context, 'Downloading: $fileName');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Download error', success: false);
      }
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _service['name'] ?? 'Service Details',
          style: TextStyle(color: Colors.white, fontSize: isPhone ? 14 : 18),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: isPhone,
          labelStyle: TextStyle(fontSize: isPhone ? 10 : 12),
          tabs: const [
            Tab(icon: Icon(Icons.article, size: 16), text: 'Content'),
            Tab(icon: Icon(Icons.dynamic_form, size: 16), text: 'Forms'),
            Tab(icon: Icon(Icons.list_alt, size: 16), text: 'Fields'),
            Tab(icon: Icon(Icons.assignment, size: 16), text: 'Apps'),
          ],
        ),
      ),
      body: _loading
          ? loadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(),
                _buildFormsTab(),
                _buildFieldsTab(),
                _buildApplicationsTab(),
              ],
            ),
    );
  }

  Widget _buildContentTab() {
    final p = isPhone ? 12.0 : 20.0;
    final serviceImage = _service['image_url']?.toString();
    return SingleChildScrollView(
      padding: EdgeInsets.all(p),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(p),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: isPhone ? 36 : 50,
                    height: isPhone ? 36 : 50,
                    decoration: BoxDecoration(
                      color: _parseColor(
                        _service['color'] ?? '0xFF1A237E',
                      ).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: _parseColor(_service['color'] ?? '0xFF1A237E'),
                      size: isPhone ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Service Content',
                    style: TextStyle(
                      fontSize: isPhone ? 15 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isPhone ? 12 : 20),

              // Service grid image
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Service Image (shown on All Services grid)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickAndUploadServiceImage,
                child: Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: (serviceImage != null && serviceImage.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl(serviceImage),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to upload service image',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: isPhone ? 12 : 20),

              if (isPhone) ...[
                _buildField('Service Name *', _nameCtrl),
                const SizedBox(height: 10),
                _buildField('Category *', _categoryCtrl),
              ] else
                Row(
                  children: [
                    Expanded(child: _buildField('Service Name *', _nameCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Category *', _categoryCtrl)),
                  ],
                ),
              SizedBox(height: 10),
              _buildField('Short Description', _descCtrl, maxLines: 2),
              SizedBox(height: 10),
              _buildField('Detail Content', _detailCtrl, maxLines: 3),
              SizedBox(height: 10),
              _buildField('Benefits', _benefitsCtrl, maxLines: 2),
              SizedBox(height: 10),
              _buildField('Eligibility', _eligibilityCtrl, maxLines: 2),
              SizedBox(height: 10),
              _buildField('Process Steps', _processCtrl, maxLines: 2),
              SizedBox(height: 10),
              if (isPhone) ...[
                _buildField('Icon', _iconCtrl),
                const SizedBox(height: 10),
                _buildField('Color', _colorCtrl),
              ] else
                Row(
                  children: [
                    Expanded(child: _buildField('Icon', _iconCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Color', _colorCtrl)),
                  ],
                ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _saveContent,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${_forms.length} Form(s)',
                style: TextStyle(
                  fontSize: isPhone ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddFormDialog,
                icon: Icon(Icons.add, size: isPhone ? 14 : 18),
                label: Text(isPhone ? 'Create' : 'Create Form'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _forms.isEmpty
              ? emptyState('No forms yet')
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 16),
                  itemCount: _forms.length,
                  itemBuilder: (c, i) {
                    final f = _forms[i];
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
                            color: const Color(0xFF1A237E).withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.dynamic_form,
                            color: const Color(0xFF1A237E),
                            size: isPhone ? 18 : 22,
                          ),
                        ),
                        title: Text(
                          f['form_title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isPhone ? 13 : 15,
                          ),
                        ),
                        subtitle: Text(
                          '${f['fee']} | ${f['processing_time']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (a) {
                            if (a == 'edit') _showEditFormDialog(f);
                            if (a == 'dup') _duplicateForm(f['id']);
                            if (a == 'del') _deleteForm(f['id']);
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
                            const PopupMenuItem(
                              value: 'dup',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Duplicate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'del',
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFormId = f['id'];
                                      _sections = [];
                                    });
                                    _loadSections(f['id']);
                                    _tabController.animateTo(2);
                                  },
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    'Fields',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddDocumentDialog(f['id']),
                                  icon: const Icon(Icons.upload_file, size: 14),
                                  label: const Text(
                                    'Docs',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // IMPORTANT: `_sections` in state may
                                    // currently belong to a DIFFERENT form
                                    // (whichever one was last opened in the
                                    // Fields tab), not this form `f`. Fetch
                                    // this form's own sections fresh before
                                    // deciding anything.
                                    List<dynamic> formSections = [];
                                    try {
                                      final res = await http.get(
                                        Uri.parse(
                                          '${widget.baseUrl}/form-fields/${f['id']}/sections',
                                        ),
                                      );
                                      final resData = jsonDecode(res.body);
                                      if (resData['success'] == true) {
                                        formSections =
                                            resData['sections'] ?? [];
                                      }
                                    } catch (e) {
                                      debugPrint('Error fetching sections: $e');
                                    }

                                    if (formSections.isEmpty) {
                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('No Section Found'),
                                          content: const Text(
                                            'Please create a section first to add age validation fields.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('OK'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _showAddSectionDialog(f['id']);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF1A237E,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                'Create Section',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _selectedFormId = f['id'];
                                      _sections = formSections;
                                    });

                                    // CHANGED: applies to every section of
                                    // this form in one click, not only the
                                    // first one.
                                    await _addAgeValidationForWholeForm(
                                      f['id'],
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.verified_user,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Age Validation',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
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

  // ==================== FIELDS TAB WITH GROUPING ====================
  Widget _buildFieldsTab() {
    if (_forms.isEmpty) {
      return emptyState('Create a form first from the Forms tab');
    }

    if (_selectedFormId == null && _forms.isNotEmpty) {
      _selectedFormId = _forms.first['id'] as int;
      _loadSections(_selectedFormId!);
    }

    final formExists = _forms.any((f) => f['id'] == _selectedFormId);
    if (!formExists && _forms.isNotEmpty) {
      _selectedFormId = _forms.first['id'] as int;
      _loadSections(_selectedFormId!);
    }

    final selectedForm = _forms.firstWhere(
      (f) => f['id'] == _selectedFormId,
      orElse: () => _forms.first,
    );
    final documents = (selectedForm['documents'] as List?) ?? [];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 8 : 12),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Form:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedFormId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  items: _forms.map<DropdownMenuItem<int>>((f) {
                    return DropdownMenuItem<int>(
                      value: f['id'] as int,
                      child: Text(
                        f['form_title'] ?? 'Form ${f['id']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedFormId = v;
                        _sections = [];
                      });
                      _loadSections(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddSectionDialog(_selectedFormId!),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Section', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(isPhone ? 8 : 16),
            children: [
              ..._sections.map((section) {
                final sectionFields = (section['fields'] as List?) ?? [];
                final sectionDocs = (section['documents'] as List?) ?? [];
                final sectionImage = section['image_url']?.toString();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(isPhone ? 10 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            (sectionImage != null && sectionImage.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrl(sectionImage),
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF1A237E,
                                          ).withAlpha(20),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.folder,
                                          color: Color(0xFF1A237E),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1A237E,
                                      ).withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.folder,
                                      color: Color(0xFF1A237E),
                                      size: 16,
                                    ),
                                  ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                section['section_name'] ?? '',
                                style: TextStyle(
                                  fontSize: isPhone ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A237E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${section['fee'] ?? 'Varies'} • ${section['processing_time'] ?? '3-7 Days'}',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.image,
                                size: 18,
                                color: Colors.teal,
                              ),
                              onPressed: () => _showEditSectionDialog(
                                section,
                                _selectedFormId!,
                              ),
                              tooltip: 'Edit Image/Description/Fee',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                size: 18,
                                color: Color(0xFF1A237E),
                              ),
                              onPressed: () => _showAddFieldDialog(
                                _selectedFormId!,
                                sectionId: section['id'],
                              ),
                              tooltip: 'Add Field to this section',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteSection(section['id']),
                              tooltip: 'Delete Section',
                            ),
                          ],
                        ),
                        if ((section['description'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(
                              section['description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const Divider(),
                        if (sectionFields.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No fields in this section. Click + to add.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Drag fields to reorder — this sets which field appears first on the form.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildReorderableFieldsList(section, sectionFields),
                        ],

                        // Section Documents
                        const SizedBox(height: 8),
                        const Divider(),
                        Row(
                          children: [
                            const Text(
                              'Required Documents',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            const Spacer(),
                            _showAddDocButtonForSection(section['id']),
                          ],
                        ),
                        if (sectionDocs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'No documents',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          )
                        else
                          ...sectionDocs.map(
                            (d) => ListTile(
                              dense: true,
                              leading: Icon(
                                d['is_mandatory'] == 1
                                    ? Icons.verified_user
                                    : Icons.info_outline,
                                color: d['is_mandatory'] == 1
                                    ? Colors.green
                                    : Colors.grey,
                                size: 16,
                              ),
                              title: Text(
                                d['doc_name'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: d['is_mandatory'] == 1
                                          ? Colors.green.withAlpha(25)
                                          : Colors.grey.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      d['is_mandatory'] == 1 ? 'Req' : 'Opt',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: d['is_mandatory'] == 1
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteSectionDocument(d['id']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              if (_sections.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isPhone ? 12 : 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No sections created yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create sections to organize your form fields',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showAddSectionDialog(_selectedFormId!),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create First Section'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Old form-level documents (kept for compatibility)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 10 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Form-level Documents (legacy)',
                            style: TextStyle(
                              fontSize: isPhone ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddDocumentDialog(_selectedFormId!),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              'Add',
                              style: TextStyle(fontSize: 10),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (documents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No documents required',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...documents.map(
                          (d) => ListTile(
                            dense: true,
                            leading: Icon(
                              d['is_mandatory'] == 1
                                  ? Icons.verified_user
                                  : Icons.info_outline,
                              color: d['is_mandatory'] == 1
                                  ? Colors.green
                                  : Colors.grey,
                              size: 18,
                            ),
                            title: Text(
                              d['doc_name'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: d['is_mandatory'] == 1
                                    ? Colors.green.withAlpha(25)
                                    : Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d['is_mandatory'] == 1 ? 'Req' : 'Opt',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: d['is_mandatory'] == 1
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            onTap: () => _deleteDocument(d['id']),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DRAG-TO-REORDER FIELDS ====================
  // NEW: lets the admin drag fields up/down within a section to control
  // which one appears first on the public form. Fields keep whichever
  // field_group tag they already have (shown inline on each tile); the
  // grouped-header display on the PUBLIC form is driven by this same
  // order (first appearance of a group name = where its header shows).

  Widget _buildReorderableFieldsList(
    Map<String, dynamic> section,
    List<dynamic> sectionFields,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      itemCount: sectionFields.length,
      itemBuilder: (context, index) {
        final field = sectionFields[index];
        return Container(
          key: ValueKey('field_tile_${field['id']}'),
          child: _buildFieldTile(field),
        );
      },
      onReorder: (oldIndex, newIndex) {
        _reorderSectionFields(section, sectionFields, oldIndex, newIndex);
      },
    );
  }

  Future<void> _reorderSectionFields(
    Map<String, dynamic> section,
    List<dynamic> fields,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<dynamic>.from(fields);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Update the UI immediately so the drag feels instant.
    setState(() {
      section['fields'] = reordered;
    });

    // Persist the new order: sort_order = position within the section.
    for (var i = 0; i < reordered.length; i++) {
      final field = reordered[i];
      if ((field['sort_order'] ?? -1) == i) continue; // already correct
      try {
        await http.put(
          Uri.parse('${widget.baseUrl}/form-fields/${field['id']}/reorder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sort_order': i}),
        );
        field['sort_order'] = i;
      } catch (e) {
        debugPrint('Error persisting field order for ${field['id']}: $e');
      }
    }

    if (mounted) showSnackBar(context, 'Field order updated');
  }

  // Helper to build a field tile
  Widget _buildFieldTile(Map<String, dynamic> field) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          (field['field_type'] == 'select' ||
                  field['field_type'] == 'multiselect')
              ? Icons.arrow_drop_down_circle
              : Icons.text_fields,
          color: const Color(0xFF1A237E),
          size: 14,
        ),
      ),
      title: Text(
        '${field['field_label']}',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${field['field_type']} | ${field['is_required'] == 1 ? "Required" : "Optional"} | name: ${field['field_name']}',
            style: const TextStyle(fontSize: 9),
          ),
          if ((field['field_group'] ?? '').toString().trim().isNotEmpty)
            Text(
              '🏷 Group: ${field['field_group']}',
              style: TextStyle(fontSize: 9, color: Colors.blue[700]),
            ),
          if (field['parent_field_id'] != null)
            Text(
              (field['show_when_value'] == null ||
                      field['show_when_value'].toString().trim().isEmpty)
                  ? '⚠ Has a parent but NO show-when value set — will NEVER show. Edit this field to fix.'
                  : '⏩ Shows when parent = "${field['show_when_value']}"',
              style: TextStyle(
                fontSize: 9,
                color:
                    (field['show_when_value'] == null ||
                        field['show_when_value'].toString().trim().isEmpty)
                    ? Colors.red[700]
                    : Colors.orange[700],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
            onPressed: () => _showEditFieldDialog(field),
            tooltip: 'Edit Field',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            onPressed: () => _deleteField(field['id']),
            tooltip: 'Delete Field',
          ),
        ],
      ),
    );
  }

  // Helper to add a document for a specific section
  Widget _showAddDocButtonForSection(int sectionId) {
    final nameCtrl = TextEditingController();
    bool mandatory = true;
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Add Document to Section'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Document Name',
                      hintText: 'e.g., Identity Proof',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Mandatory'),
                    value: mandatory,
                    onChanged: (v) => setDialogState(() => mandatory = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
                  if (nameCtrl.text.isEmpty) {
                    showSnackBar(
                      context,
                      'Document name required',
                      success: false,
                    );
                    return;
                  }
                  _addSectionDocument(sectionId, nameCtrl.text, mandatory);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF1A237E)),
            SizedBox(width: 4),
            Text('Add Doc', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${_applications.length} Apps',
                style: TextStyle(
                  fontSize: isPhone ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
                onPressed: _loadApplications,
              ),
            ],
          ),
        ),
        Expanded(
          child: _applications.isEmpty
              ? emptyState('No applications')
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 16),
                  itemCount: _applications.length,
                  itemBuilder: (c, i) {
                    final a = _applications[i];
                    final st = a['status'] ?? 'pending';
                    Color sc;
                    IconData si;
                    switch (st) {
                      case 'completed':
                        sc = Colors.green;
                        si = Icons.check_circle;
                        break;
                      case 'processing':
                        sc = Colors.orange;
                        si = Icons.hourglass_top;
                        break;
                      case 'rejected':
                        sc = Colors.red;
                        si = Icons.cancel;
                        break;
                      default:
                        sc = Colors.blue;
                        si = Icons.pending;
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: sc.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(si, color: sc, size: 20),
                        ),
                        title: Text(
                          a['tracking_id'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isPhone ? 12 : 14,
                          ),
                        ),
                        subtitle: Text(
                          '${a['user_name']} • ${st.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.folder_open, size: 18),
                          color: const Color(0xFF1A237E),
                          onPressed: () => _viewApplicationFiles(a['id']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
