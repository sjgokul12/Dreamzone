import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_helpers.dart';
import 'admin_service_detail_screen.dart';

class AdminServicesScreen extends StatefulWidget {
  final String baseUrl;
  const AdminServicesScreen({super.key, required this.baseUrl});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<dynamic> _services = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  bool _loadingCategories = false;
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadCategories();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/services'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _services = data['services']);
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/categories'));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _categories = data['categories']);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
    if (mounted) setState(() => _loadingCategories = false);
  }

  List<dynamic> get _filteredServices {
    return _services.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final cat = (s['category'] ?? '').toString();
      final matchesSearch =
          _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _filterCategory == 'All' || cat == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _filterCategories {
    final cats = <String>{'All'};
    for (var s in _services) {
      cats.add((s['category'] ?? 'Other').toString());
    }
    return cats.toList();
  }

  // ==================== CATEGORY MANAGEMENT ====================

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Manage Categories',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _loadingCategories
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                  )
                : Column(
                    children: [
                      // Add new category row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(),
                              decoration: const InputDecoration(
                                hintText: 'New category name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (value) {
                                _addCategory(ctx, value, setDialogState);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // We'll use a TextEditingController but for simplicity we use the onSubmitted approach.
                              // Instead, we'll use a proper controller in a separate dialog.
                              // Let's open a dedicated add dialog.
                              _showAddCategoryDialog(ctx, setDialogState);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _categories.isEmpty
                            ? Center(
                                child: Text(
                                  'No categories yet.\nAdd your first one above.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.category,
                                      color: Color(0xFF1A237E),
                                    ),
                                    title: Text(cat['name']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _editCategory(
                                            ctx,
                                            cat,
                                            setDialogState,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteCategory(
                                            ctx,
                                            cat,
                                            setDialogState,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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

  void _showAddCategoryDialog(BuildContext ctx, StateSetter setState) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Government, Financial',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                final res = await http.post(
                  Uri.parse('${widget.baseUrl}/categories'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': name}),
                );
                final data = jsonDecode(res.body);
                if (data['success'] == true) {
                  await _loadCategories();
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  // Refresh whichever dialog called us (Manage Categories
                  // list, or the Add/Edit Service dropdown) so the new
                  // category shows up immediately without having to
                  // close and reopen anything.
                  setState(() {});
                  if (ctx.mounted) showSnackBar(ctx, 'Category added');
                } else {
                  if (ctx.mounted) {
                    showSnackBar(
                      ctx,
                      data['message'] ?? 'Failed',
                      success: false,
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) showSnackBar(ctx, 'Error', success: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCategory(BuildContext ctx, String name, StateSetter setState) async {
    if (name.trim().isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name.trim()}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await _loadCategories();
        setState(() {});
        if (ctx.mounted) showSnackBar(ctx, 'Category added');
      } else {
        if (ctx.mounted) {
          showSnackBar(ctx, data['message'] ?? 'Failed', success: false);
        }
      }
    } catch (e) {
      if (ctx.mounted) showSnackBar(ctx, 'Error', success: false);
    }
  }

  void _editCategory(
    BuildContext ctx,
    Map<String, dynamic> cat,
    StateSetter setState,
  ) async {
    final ctrl = TextEditingController(text: cat['name']);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              try {
                final res = await http.put(
                  Uri.parse('${widget.baseUrl}/categories/${cat['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': newName}),
                );
                final data = jsonDecode(res.body);
                if (data['success'] == true) {
                  await _loadCategories();
                  await _loadServices();
                  setState(() {});
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (ctx.mounted) showSnackBar(ctx, 'Category updated');
                } else {
                  if (ctx.mounted) {
                    showSnackBar(
                      ctx,
                      data['message'] ?? 'Failed',
                      success: false,
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) showSnackBar(ctx, 'Error', success: false);
              }
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

  void _deleteCategory(
    BuildContext ctx,
    Map<String, dynamic> cat,
    StateSetter setState,
  ) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete category "${cat['name']}"? Services will be moved to "Other".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
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
      try {
        final res = await http.delete(
          Uri.parse('${widget.baseUrl}/categories/${cat['id']}'),
        );
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await _loadCategories();
          await _loadServices();
          setState(() {});
          if (ctx.mounted) showSnackBar(ctx, 'Category deleted');
        } else {
          if (ctx.mounted) {
            showSnackBar(ctx, data['message'] ?? 'Failed', success: false);
          }
        }
      } catch (e) {
        if (ctx.mounted) showSnackBar(ctx, 'Error', success: false);
      }
    }
  }

  // ==================== SERVICE CRUD ====================

  // FIX: previously this method read `_categories` at whatever state it
  // happened to be in (possibly still empty/loading) and defaulted
  // selectedCategory to '' (an empty STRING, not null). A
  // DropdownButtonFormField's `value` must be either null or exactly
  // match one of its `items` values - '' matched nothing, which is
  // exactly why the dropdown rendered blank and unusable in your
  // screenshot. Now: (1) categories are freshly reloaded right before
  // the dialog opens, (2) selectedCategory is properly nullable, and
  // (3) if there are truly zero categories, the dialog shows a clear
  // "add a category first" prompt instead of a broken dropdown.
  Future<void> _showAddServiceDialog() async {
    if (_loading) {
      // no-op guard, kept simple
    }
    await _loadCategories();
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: 'assured_workload');
    final colorCtrl = TextEditingController(text: '0xFF1A237E');
    String? selectedCategory = _categories.isNotEmpty
        ? _categories[0]['name'] as String
        : null;
    bool saving = false;
    final isPhone = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add New Service',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Service Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.miscellaneous_services),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withAlpha(80)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No categories yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You need at least one category before adding a service.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddCategoryDialog(ctx, (fn) {
                                // After a category is added, refresh this
                                // dialog's own dropdown state immediately.
                                setDialogState(() {
                                  if (_categories.isNotEmpty) {
                                    selectedCategory =
                                        _categories[0]['name'] as String;
                                  }
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add a Category'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['name'],
                          child: Text(cat['name']),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please select a category'
                          : null,
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: iconCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Icon',
                            border: OutlineInputBorder(),
                            hintText: 'credit_card',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Color',
                            border: OutlineInputBorder(),
                            hintText: '0xFF00695C',
                          ),
                        ),
                      ),
                    ],
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
                      if (nameCtrl.text.isEmpty ||
                          selectedCategory == null ||
                          selectedCategory!.isEmpty) {
                        if (ctx.mounted) {
                          showSnackBar(
                            ctx,
                            'Name and category required',
                            success: false,
                          );
                        }
                        return;
                      }
                      setDialogState(() => saving = true);
                      await http.post(
                        Uri.parse('${widget.baseUrl}/services/add'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': nameCtrl.text,
                          'category': selectedCategory,
                          'description': descCtrl.text,
                          'icon': iconCtrl.text,
                          'color': colorCtrl.text,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadServices();
                      if (mounted) showSnackBar(context, 'Service added');
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

  Future<void> _showEditServiceDialog(Map<String, dynamic> service) async {
    // Same fix as Add: reload categories fresh, and make sure the
    // service's OWN existing category text is always present as an
    // option even if it's missing from the categories table (this can
    // happen for services created before "Manage Categories" existed,
    // or ones seeded directly into the database) - otherwise the
    // dropdown's `value` wouldn't match any item and would appear
    // blank again, exactly like the Add dialog bug.
    await _loadCategories();
    if (!mounted) return;

    final nameCtrl = TextEditingController(text: service['name']);
    final descCtrl = TextEditingController(text: service['description']);
    final iconCtrl = TextEditingController(text: service['icon']);
    final colorCtrl = TextEditingController(text: service['color']);
    final detailCtrl = TextEditingController(
      text: service['detail_content'] ?? '',
    );
    final benefitsCtrl = TextEditingController(text: service['benefits'] ?? '');
    final eligibilityCtrl = TextEditingController(
      text: service['eligibility'] ?? '',
    );
    final processCtrl = TextEditingController(
      text: service['process_steps'] ?? '',
    );
    bool isActive = service['is_active'] == 1;
    bool saving = false;
    final isPhone = MediaQuery.of(context).size.width < 600;

    final existingCategory = (service['category'] ?? '').toString();
    final categoryNames = _categories.map((c) => c['name'].toString()).toSet();
    // Build the dropdown option list, guaranteeing the service's
    // current category is always included even if it's not (yet) a
    // real row in the categories table.
    final List<String> dropdownCategoryNames = [
      if (existingCategory.isNotEmpty) existingCategory,
      ..._categories
          .map((c) => c['name'].toString())
          .where((n) => n != existingCategory),
    ];
    String? selectedCategory = existingCategory.isNotEmpty
        ? existingCategory
        : (dropdownCategoryNames.isNotEmpty
              ? dropdownCategoryNames.first
              : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Edit: ${service['name']}',
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (dropdownCategoryNames.isEmpty)
                    TextField(
                      controller: TextEditingController(text: existingCategory)
                        ..addListener(() {}),
                      onChanged: (v) => selectedCategory = v,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        helperText:
                            'No categories in the system yet - type one directly.',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: dropdownCategoryNames
                          .map<DropdownMenuItem<String>>((name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                          })
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please select a category'
                          : null,
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Detail Content',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: benefitsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Benefits',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: eligibilityCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Eligibility',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: processCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Process Steps',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: iconCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Icon',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Color',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
                      if (selectedCategory == null ||
                          selectedCategory!.trim().isEmpty) {
                        if (ctx.mounted) {
                          showSnackBar(
                            ctx,
                            'Category required',
                            success: false,
                          );
                        }
                        return;
                      }
                      setDialogState(() => saving = true);
                      await http.put(
                        Uri.parse(
                          '${widget.baseUrl}/services/${service['id']}',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': nameCtrl.text,
                          'category': selectedCategory,
                          'description': descCtrl.text,
                          'detail_content': detailCtrl.text,
                          'benefits': benefitsCtrl.text,
                          'eligibility': eligibilityCtrl.text,
                          'process_steps': processCtrl.text,
                          'icon': iconCtrl.text,
                          'color': colorCtrl.text,
                          'is_active': isActive ? 1 : 0,
                        }),
                      );
                      setDialogState(() => saving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadServices();
                      if (mounted) showSnackBar(context, 'Service updated');
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

  void _deleteService(Map<String, dynamic> service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Delete "${service['name']}"?'),
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
      final res = await http.delete(
        Uri.parse('${widget.baseUrl}/services/${service['id']}'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (mounted) showSnackBar(context, 'Service deleted');
        _loadServices();
      } else {
        if (mounted) {
          showSnackBar(context, data['message'] ?? 'Failed', success: false);
        }
      }
    }
  }

  void _toggleService(int serviceId) async {
    await http.put(Uri.parse('${widget.baseUrl}/services/$serviceId/toggle'));
    _loadServices();
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

  IconData _parseIcon(String i) {
    switch (i) {
      case 'account_balance':
        return Icons.account_balance;
      case 'payments':
        return Icons.payments;
      case 'phone_android':
        return Icons.phone_android;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'credit_card':
        return Icons.credit_card;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'description':
        return Icons.description;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'point_of_sale':
        return Icons.point_of_sale;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.miscellaneous_services;
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final filtered = _filteredServices;

    int crossAxisCount = 3;
    if (isPhone) {
      crossAxisCount = 1;
    } else if (isTablet)
      crossAxisCount = 2;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Services',
                    style: TextStyle(
                      fontSize: isPhone ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  if (!isPhone) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filtered.length}/${_services.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  ElevatedButton.icon(
                    onPressed: _showManageCategoriesDialog,
                    icon: const Icon(Icons.category, size: 18),
                    label: const Text('Categories'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: const Color(0xFF1A237E),
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 10 : 16,
                        vertical: isPhone ? 6 : 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddServiceDialog,
                    icon: Icon(Icons.add, size: isPhone ? 16 : 18),
                    label: Text(isPhone ? 'Add' : 'Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 10 : 16,
                        vertical: isPhone ? 6 : 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search services...',
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: isPhone ? 2 : 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterCategory,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: isPhone ? 11 : 13,
                            color: const Color(0xFF1A237E),
                          ),
                          items: _filterCategories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _filterCategory = v ?? 'All'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Service Grid
        Expanded(
          child: _loading
              ? loadingState()
              : filtered.isEmpty
              ? emptyState('No services found')
              : GridView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: isPhone ? 8 : 12,
                    crossAxisSpacing: isPhone ? 8 : 12,
                    childAspectRatio: isPhone ? 2.5 : 1.5,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final s = filtered[i];
                    final color = _parseColor(s['color'] ?? '0xFF1A237E');
                    final icon = _parseIcon(
                      s['icon'] ?? 'miscellaneous_services',
                    );
                    final isActive = s['is_active'] == 1;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminServiceDetailScreen(
                              baseUrl: widget.baseUrl,
                              serviceId: s['id'],
                              serviceName: s['name'] ?? '',
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isPhone ? 10 : 14),
                          child: isPhone
                              ? _buildMobileServiceCard(
                                  s,
                                  color,
                                  icon,
                                  isActive,
                                )
                              : _buildDesktopServiceCard(
                                  s,
                                  color,
                                  icon,
                                  isActive,
                                ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== SERVICE CARDS ====================

  Widget _buildMobileServiceCard(
    Map<String, dynamic> s,
    Color color,
    IconData icon,
    bool isActive,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (s['category'] ?? 'Service').toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'edit') _showEditServiceDialog(s);
              if (action == 'delete') _deleteService(s);
              if (action == 'toggle') _toggleService(s['id']);
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
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
                      isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                    Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopServiceCard(
    Map<String, dynamic> s,
    Color color,
    IconData icon,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A237E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      s['category'] ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          s['description'] ?? '',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _toggleService(s['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.red.withAlpha(20)
                      : Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Off' : 'On',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showEditServiceDialog(s),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _deleteService(s),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.delete, size: 14, color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
