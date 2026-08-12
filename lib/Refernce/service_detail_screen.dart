            // import 'dart:convert';
            // import 'package:flutter/material.dart';
            // import 'package:flutter/gestures.dart';
            // import 'package:http/http.dart' as http;
            // import 'package:provider/provider.dart';
            // import 'package:file_picker/file_picker.dart';
            // import '../../providers/auth_provider.dart';
            // import '../../services/api_service.dart';
            // import 'terms_screen.dart';
            // import 'privacy_screen.dart';

            // class ServiceDetailScreen extends StatefulWidget {
            //   final Map<String, dynamic> service;
            //   final bool isGuest;
            //   final int? preselectedSectionId;
            //   final Map<String, dynamic>? preselectedSectionData;
            //   const ServiceDetailScreen({
            //     super.key,
            //     required this.service,
            //     this.isGuest = false,
            //     this.preselectedSectionId,
            //     this.preselectedSectionData,
            //   });

            //   @override
            //   State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
            // }

            // class _ServiceDetailScreenState extends State<ServiceDetailScreen>
            //     with SingleTickerProviderStateMixin {
            //   final _formKey = GlobalKey<FormState>();
            //   final ApiService _api = ApiService();
            //   bool _submitted = false;
            //   bool _loading = false;
            //   bool _loadingForm = true;
            //   String? _trackingId;

            //   Map<String, dynamic>? _formConfig;
            //   List<dynamic> _sections = [];
            //   // NEW: fetched independently via its own endpoint (not relying on
            //   // whatever _formConfig happens to contain) so the documents-after
            //   // -fields fallback always has data to show.
            //   List<dynamic> _serviceLevelDocuments = [];

            //   int? _selectedSectionId;

            //   final Map<String, TextEditingController> _controllers = {};
            //   final Map<String, String> _selectedOptions = {};
            //   final Map<String, List<Map<String, dynamic>>> _uploadedDocs = {};
            //   bool _termsAccepted = false;
            //   // NEW: when true (default), recognized personal-detail fields typed
            //   // into THIS form (name, address, DOB, Aadhaar/PAN, etc.) are saved to
            //   // the user's profile on successful submit, so they're available to
            //   // reuse ("Use My Saved Details") on any other service too.
            //   bool _saveDetailsForReuse = true;

            //   Map<String, dynamic>? _savedDetails;
            //   List<dynamic> _savedDocuments = [];
            //   bool _showSavedDocs = false;

            //   late AnimationController _animationController;
            //   late Animation<double> _fadeAnimation;

            //   static const Color primary = Color(0xFF6C63FF);
            //   static const Color primaryDark = Color(0xFF4A42CC);
            //   static const Color secondary = Color(0xFFFF6584);
            //   static const Color success = Color(0xFF4CAF50);
            //   static const Color warning = Color(0xFFFFB74D);
            //   static const Color bgColor = Color(0xFFF8F9FF);
            //   static const Color textPrimaryColor = Color(0xFF1A1A2E);
            //   static const Color textSecondaryColor = Color(0xFF6B7280);
            //   static const Color cardBg = Color(0xFFFFFFFF);

            //   bool get _hasPreselectedSection => widget.preselectedSectionId != null;

            //   @override
            //   void initState() {
            //     super.initState();
            //     _animationController = AnimationController(
            //       duration: const Duration(milliseconds: 800),
            //       vsync: this,
            //     );
            //     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            //       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            //     );
            //     _animationController.forward();
            //     _fetchFormConfig();
            //     _loadSavedData();
            //   }

            //   @override
            //   void dispose() {
            //     _animationController.dispose();
            //     for (var c in _controllers.values) {
            //       c.dispose();
            //     }
            //     super.dispose();
            //   }

            //   Future<void> _loadSavedData() async {
            //     final auth = Provider.of<AuthProvider>(context, listen: false);
            //     if (!auth.isLoggedIn || auth.userId == null) return;

            //     final detailsResult = await _api.getUserSavedDetails(auth.userId!);
            //     final docsResult = await _api.getUserDocuments(auth.userId!);

            //     if (mounted) {
            //       setState(() {
            //         _savedDetails = detailsResult['details'];
            //         _savedDocuments = docsResult['documents'] ?? [];
            //       });
            //     }
            //   }

            //   Future<void> _fetchFormConfig() async {
            //     final serviceId = widget.service['id'];
            //     try {
            //       final data = await _api.getServiceForm(serviceId);

            //       if (data['success'] == true && mounted) {
            //         setState(() {
            //           _formConfig = data['form'];
            //           _sections = data['sections'] ?? [];

            //           for (var section in _sections) {
            //             for (var field in (section['fields'] ?? [])) {
            //               _initFieldController(field);
            //             }
            //           }

            //           if (_sections.isNotEmpty) {
            //             if (widget.preselectedSectionId != null &&
            //                 _sections.any((s) => s['id'] == widget.preselectedSectionId)) {
            //               _selectedSectionId = widget.preselectedSectionId;
            //             } else if (_selectedSectionId == null) {
            //               _selectedSectionId = _sections.first['id'];
            //             }
            //           }

            //           _loadingForm = false;
            //         });
            //       } else {
            //         if (mounted) setState(() => _loadingForm = false);
            //       }
            //     } catch (e) {
            //       if (mounted) setState(() => _loadingForm = false);
            //     }

            //     // NEW: fetch the whole-service required documents on a SEPARATE,
            //     // dedicated call. This doesn't depend on what the form/sections
            //     // call above returns, so the documents-after-fields fallback works
            //     // even if ApiService.getServiceForm() doesn't happen to include a
            //     // form-level 'documents' key.
            //     try {
            //       final res = await http.get(
            //           Uri.parse('${ApiService.baseUrl}/services/$serviceId/required-documents'));
            //       final docsData = jsonDecode(res.body);
            //       if (docsData['success'] == true && mounted) {
            //         setState(() {
            //           _serviceLevelDocuments = docsData['documents'] ?? [];
            //         });
            //       }
            //     } catch (e) {
            //       debugPrint('Error loading service-level documents: $e');
            //     }
            //   }

            //   void _initFieldController(Map<String, dynamic> field) {
            //     final fname = field['field_name'] ?? '';
            //     final ftype = field['field_type'] ?? 'text';
            //     if (ftype == 'file') return;
            //     if (ftype == 'select' || ftype == 'multiselect') {
            //       _selectedOptions[fname] = '';
            //     } else {
            //       if (!_controllers.containsKey(fname)) {
            //         _controllers[fname] = TextEditingController();
            //       }
            //     }
            //   }

            //   Map<String, dynamic>? get _currentSection {
            //     if (_selectedSectionId == null) return null;
            //     try {
            //       return Map<String, dynamic>.from(
            //         _sections.firstWhere((s) => s['id'] == _selectedSectionId),
            //       );
            //     } catch (e) {
            //       return widget.preselectedSectionData;
            //     }
            //   }

            //   String _effectiveDescription() {
            //     final section = _currentSection ?? widget.preselectedSectionData;
            //     if (section != null) {
            //       final secDesc = (section['description'] ?? '').toString().trim();
            //       if (secDesc.isNotEmpty) return secDesc;
            //     }
            //     return (widget.service['description'] ?? '').toString();
            //   }

            //   String _effectiveSectionImage() {
            //     final section = _currentSection ?? widget.preselectedSectionData;
            //     if (section != null) {
            //       final img = (section['image_url'] ?? '').toString().trim();
            //       if (img.isNotEmpty) return img;
            //     }
            //     return '';
            //   }

            //   String _sectionFee() {
            //     final section = _currentSection ?? widget.preselectedSectionData;
            //     if (section != null) {
            //       final fee = (section['fee'] ?? '').toString().trim();
            //       if (fee.isNotEmpty) return fee;
            //     }
            //     return _formConfig?['fee'] ?? 'Varies';
            //   }

            //   String _sectionProcessingTime() {
            //     final section = _currentSection ?? widget.preselectedSectionData;
            //     if (section != null) {
            //       final time = (section['processing_time'] ?? '').toString().trim();
            //       if (time.isNotEmpty) return time;
            //     }
            //     return _formConfig?['processing_time'] ?? '3-7 Days';
            //   }

            //   // ==================== OPTION HELPER (NEW) ====================
            //   // Same parsing used on the admin side: trims every option so the
            //   // value stored in _selectedOptions always matches show_when_value
            //   // exactly (avoids "Male" vs " Male" mismatches).
            //   List<String> _parseOptions(dynamic raw) {
            //     return (raw ?? '')
            //         .toString()
            //         .split(',')
            //         .map((s) => s.trim())
            //         .where((s) => s.isNotEmpty)
            //         .toList();
            //   }

            //   // ==================== AGE VALIDATION ====================

            //   // NEW: recognizes any field meant to capture Date of Birth, whatever
            //   // exact name the admin gave it (the Age Validation button always
            //   // creates one named 'date_of_birth', but this stays tolerant of
            //   // 'dob' too). This is intentionally section-agnostic: whichever
            //   // section is active, if ITS date field is a DOB field, the age
            //   // check runs and the global `age_status` flag flips — which is what
            //   // makes the parent/guardian fields (checked via that same flag in
            //   // _isFieldVisible) work consistently across the WHOLE form rather
            //   // than being tied to one specific section.
            //   bool _isDobFieldName(String fieldName) {
            //     final n = fieldName.toLowerCase();
            //     return n == 'dob' || n.contains('date_of_birth') || n.contains('dateofbirth');
            //   }

            //   void _checkAgeAndShowParentFields(String dobValue) {
            //     if (dobValue.isEmpty) return;
            //     try {
            //       DateTime dob;
            //       if (dobValue.contains('/')) {
            //         final parts = dobValue.split('/');
            //         if (parts.length == 3) {
            //           dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            //         } else {
            //           return;
            //         }
            //       } else if (dobValue.contains('-')) {
            //         final parts = dobValue.split('-');
            //         if (parts.length == 3) {
            //           dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            //         } else {
            //           return;
            //         }
            //       } else {
            //         return;
            //       }

            //       final age = DateTime.now().difference(dob).inDays ~/ 365;

            //       if (age < 18) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: Row(
            //               children: [
            //                 const Icon(Icons.warning_amber, color: Colors.white),
            //                 const SizedBox(width: 10),
            //                 Expanded(
            //                   child: Text(
            //                     '⚠️ You are $age years old (Minor). Parent/Guardian details required.',
            //                     style: const TextStyle(fontSize: 13),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //             backgroundColor: Colors.orange,
            //             duration: const Duration(seconds: 4),
            //             behavior: SnackBarBehavior.floating,
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //           ),
            //         );

            //         setState(() {
            //           _selectedOptions['age_status'] = 'minor';
            //         });

            //         _formKey.currentState?.validate();
            //       } else {
            //         setState(() {
            //           _selectedOptions['age_status'] = 'adult';
            //         });
            //       }
            //     } catch (e) {
            //       // ignore
            //     }
            //   }

            //   // ==================== USE SAVED DETAILS ====================

            //   void _useSavedDetails() {
            //     if (_savedDetails == null) return;

            //     setState(() {
            //       final fieldMappings = {
            //         'full_name': _savedDetails!['full_name'],
            //         'father_name': _savedDetails!['father_name'],
            //         'mother_name': _savedDetails!['mother_name'],
            //         'dob': _savedDetails!['dob']?.toString(),
            //         'gender': _savedDetails!['gender'],
            //         'aadhaar_number': _savedDetails!['aadhaar_number'],
            //         'aadhaar': _savedDetails!['aadhaar_number'],
            //         'pan_number': _savedDetails!['pan_number'],
            //         'pan': _savedDetails!['pan_number'],
            //         'address_line1': _savedDetails!['address_line1'],
            //         'address_line2': _savedDetails!['address_line2'],
            //         'address': '${_savedDetails!['address_line1'] ?? ''}, ${_savedDetails!['city'] ?? ''}',
            //         'city': _savedDetails!['city'],
            //         'state': _savedDetails!['state'],
            //         'pincode': _savedDetails!['pincode'],
            //       };

            //       fieldMappings.forEach((fieldName, value) {
            //         if (value != null && value.toString().isNotEmpty) {
            //           if (_controllers.containsKey(fieldName)) {
            //             _controllers[fieldName]!.text = value.toString();
            //           }
            //           if (_selectedOptions.containsKey(fieldName)) {
            //             _selectedOptions[fieldName] = value.toString();
            //           }
            //         }
            //       });

            //       if (_controllers.containsKey('dob') && _controllers['dob']!.text.isNotEmpty) {
            //         _checkAgeAndShowParentFields(_controllers['dob']!.text);
            //       }

            //       // Auto-attach saved documents
            //       final docs = _getDocumentsForSelectedSection();
            //       if (docs.isNotEmpty && _savedDocuments.isNotEmpty) {
            //         for (var doc in docs) {
            //           final docName = (doc['doc_name'] ?? '').toString().toLowerCase();
            //           final docId = doc['id'].toString();

            //           Map<String, dynamic>? matchingDoc;
            //           for (var savedDoc in _savedDocuments) {
            //             final savedDocType = (savedDoc['doc_type'] ?? '').toString().toLowerCase();
            //             final savedDocName = (savedDoc['doc_name'] ?? '').toString().toLowerCase();

            //             if (docName.contains(savedDocType) ||
            //                 savedDocName.contains(docName) ||
            //                 savedDocType == 'aadhaar' && docName.contains('aadhaar') ||
            //                 savedDocType == 'pan' && docName.contains('pan') ||
            //                 savedDocType == 'photo' && docName.contains('photo') ||
            //                 savedDocType == 'signature' && docName.contains('signature') ||
            //                 savedDocType == 'bank' && docName.contains('bank') ||
            //                 savedDocType == 'address' && docName.contains('address')) {
            //               matchingDoc = savedDoc;
            //               break;
            //             }
            //           }

            //           if (matchingDoc != null) {
            //             final filePath = matchingDoc['file_path'] ?? '';
            //             final fileName = matchingDoc['file_name'] ?? matchingDoc['doc_name'] ?? 'document';
            //             _fetchAndAttachDocument(filePath, fileName, docId);
            //           }
            //         }
            //       }
            //     });

            //     if (mounted) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(
            //           content: const Text('✨ Saved details applied! Documents auto-attached!'),
            //           backgroundColor: success,
            //           duration: const Duration(seconds: 3),
            //           behavior: SnackBarBehavior.floating,
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //         ),
            //       );
            //     }
            //   }

            //   Future<void> _fetchAndAttachDocument(String filePath, String fileName, String docId) async {
            //     try {
            //       final encodedPath = Uri.encodeComponent(filePath);
            //       final url = '${ApiService.baseUrl}/view-file/$encodedPath';
            //       final response = await http.get(Uri.parse(url));

            //       if (response.statusCode == 200 && mounted) {
            //         setState(() {
            //           _uploadedDocs[docId] ??= [];
            //           _uploadedDocs[docId]!.add({
            //             'bytes': response.bodyBytes,
            //             'name': fileName,
            //             'size': response.bodyBytes.length,
            //             'extension': fileName.split('.').last.toLowerCase(),
            //           });
            //         });

            //         if (mounted) {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text('📎 Auto-attached: $fileName'),
            //               backgroundColor: success,
            //               duration: const Duration(seconds: 2),
            //               behavior: SnackBarBehavior.floating,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //             ),
            //           );
            //         }
            //       }
            //     } catch (e) {
            //       // silent
            //     }
            //   }

            //   // ==================== SAVE DETAILS FOR REUSE (NEW) ====================
            //   // Recognizes common personal-detail field names (whatever exact
            //   // name each service happens to use for "address", "aadhaar", etc.)
            //   // and stores them to the user's profile via the existing saved
            //   // -details endpoint. The backend now merges these in (fields that
            //   // aren't sent keep their previous value), so filling in just an
            //   // address on one service won't wipe out a name/DOB saved earlier
            //   // from a different service, and vice versa.
            //   static final Map<String, List<String>> _savedDetailAliases = {
            //     'full_name': ['full_name', 'name', 'applicant_name', 'fullname'],
            //     'father_name': ['father_name', 'fathers_name', 'father_full_name'],
            //     'mother_name': ['mother_name', 'mothers_name', 'mother_full_name'],
            //     'dob': ['dob', 'date_of_birth'],
            //     'gender': ['gender', 'sex'],
            //     'aadhaar_number': ['aadhaar_number', 'aadhaar', 'aadhar_number', 'aadhar'],
            //     'pan_number': ['pan_number', 'pan'],
            //     'address_line1': ['address_line1', 'address', 'address1', 'permanent_address'],
            //     'address_line2': ['address_line2', 'address2'],
            //     'city': ['city'],
            //     'state': ['state'],
            //     'pincode': ['pincode', 'pin_code', 'zipcode', 'zip'],
            //   };

            //   Future<void> _autoSaveDetailsForReuse(
            //       Map<String, String> formValues, int userId) async {
            //     // Build a case-insensitive lookup of whatever the user just typed.
            //     final lowerFormValues = <String, String>{};
            //     formValues.forEach((k, v) {
            //       lowerFormValues[k.toLowerCase()] = v;
            //     });

            //     final Map<String, String> toSave = {};
            //     _savedDetailAliases.forEach((canonicalKey, aliases) {
            //       for (final alias in aliases) {
            //         final value = lowerFormValues[alias.toLowerCase()];
            //         if (value != null && value.trim().isNotEmpty) {
            //           toSave[canonicalKey] = value.trim();
            //           break;
            //         }
            //       }
            //     });

            //     // Nothing recognizable was typed (e.g. a service with completely
            //     // custom field names) - nothing to save, and nothing lost either.
            //     if (toSave.isEmpty) return;

            //     try {
            //       final res = await http.post(
            //         Uri.parse('${ApiService.baseUrl}/user/$userId/saved-details'),
            //         headers: {'Content-Type': 'application/json'},
            //         body: jsonEncode(toSave),
            //       );
            //       if (res.statusCode == 200) {
            //         // Refresh in-memory copy so "Use My Saved Details" reflects the
            //         // freshest data immediately without needing to reopen the app.
            //         final auth = Provider.of<AuthProvider>(context, listen: false);
            //         if (auth.userId != null) {
            //           final detailsResult = await _api.getUserSavedDetails(auth.userId!);
            //           if (mounted) {
            //             setState(() {
            //               _savedDetails = detailsResult['details'];
            //             });
            //           }
            //         }
            //       }
            //     } catch (e) {
            //       debugPrint('Error auto-saving details for reuse: $e');
            //       // Non-fatal: the application itself already submitted fine.
            //     }
            //   }

            //   // ==================== CONDITIONAL VISIBILITY (FIXED) ====================

            //   bool _isFieldVisible(Map<String, dynamic> field) {
            //     final parentId = field['parent_field_id'];
            //     final showWhen = field['show_when_value'];

            //     // Special case: age validation fields
            //     final fieldName = field['field_name'] ?? '';
            //     if (fieldName.startsWith('parent_') || fieldName == 'minor_consent') {
            //       return _selectedOptions['age_status'] == 'minor';
            //     }

            //     // If no parent, always visible
            //     if (parentId == null || showWhen == null || showWhen.toString().trim().isEmpty) {
            //       return true;
            //     }

            //     // Find the parent field. IMPORTANT: only look inside the CURRENTLY
            //     // SELECTED section. A parent field that lives in a different,
            //     // non-visible section can never receive a value from the user, so
            //     // treating it as "found elsewhere" would make the child permanently
            //     // hidden (or, if we fell back to "always visible", permanently
            //     // shown) with no way for the admin to notice why. Searching only
            //     // the active section keeps behaviour predictable and matches how
            //     // fields are actually meant to be authored (parent + child in the
            //     // same section).
            //     Map<String, dynamic>? parentField;
            //     final activeSection = _sections.firstWhere(
            //       (s) => s['id'] == _selectedSectionId,
            //       orElse: () => null,
            //     );
            //     if (activeSection != null) {
            //       for (var f in (activeSection['fields'] ?? [])) {
            //         if (f['id'].toString() == parentId.toString()) {
            //           parentField = f;
            //           break;
            //         }
            //       }
            //     }

            //     // Fallback: search every section too, in case data was authored
            //     // with a cross-section parent. This keeps old data working while
            //     // the admin-side fix (which now blocks cross-section parents for
            //     // NEW fields) takes effect for anything created going forward.
            //     if (parentField == null) {
            //       for (var section in _sections) {
            //         for (var f in (section['fields'] ?? [])) {
            //           if (f['id'].toString() == parentId.toString()) {
            //             parentField = f;
            //             break;
            //           }
            //         }
            //         if (parentField != null) break;
            //       }
            //     }

            //     // If parent field truly doesn't exist anymore, show the child
            //     // (fallback) rather than hide it silently.
            //     if (parentField == null) {
            //       return true;
            //     }

            //     // Get parent field name
            //     final parentName = parentField['field_name'] ?? '';

            //     // Get parent value from _selectedOptions (for dropdowns) or _controllers (for text fields)
            //     String parentValue = '';
            //     if (_selectedOptions.containsKey(parentName)) {
            //       parentValue = _selectedOptions[parentName] ?? '';
            //     } else if (_controllers.containsKey(parentName)) {
            //       parentValue = _controllers[parentName]!.text;
            //     }

            //     // Compare with the required show_when_value (trim and case-insensitive for safety)
            //     final showWhenTrimmed = showWhen.toString().trim();
            //     final parentValueTrimmed = parentValue.trim();

            //     // If showWhen is empty, always visible
            //     if (showWhenTrimmed.isEmpty) return true;

            //     // FIX: show_when_value can now hold MULTIPLE trigger values,
            //     // comma-separated (the admin dialog uses checkboxes, not a single
            //     // dropdown pick, so an admin can tick 2+ options). The previous
            //     // version compared the parent's value against the WHOLE
            //     // show_when_value string as one piece, which only ever worked by
            //     // coincidence when exactly one box was ticked. Split it into the
            //     // actual set of trigger values here and match against ANY of them.
            //     final triggerValues = showWhenTrimmed
            //         .split(',')
            //         .map((s) => s.trim().toLowerCase())
            //         .where((s) => s.isNotEmpty)
            //         .toSet();

            //     // If the parent itself is a multi-select field, its own value is
            //     // ALSO a comma-separated list of everything the user picked there.
            //     // Show the child if there's any overlap between what the user
            //     // picked on the parent and the trigger values configured here.
            //     if ((parentField['field_type'] ?? '') == 'multiselect') {
            //       final pickedValues = parentValueTrimmed
            //           .split(',')
            //           .map((s) => s.trim().toLowerCase())
            //           .where((s) => s.isNotEmpty)
            //           .toSet();
            //       return pickedValues.intersection(triggerValues).isNotEmpty;
            //     }

            //     // Regular single-select parent: show if its one current value is
            //     // among the ticked trigger values.
            //     return triggerValues.contains(parentValueTrimmed.toLowerCase());
            //   }

            //   // Clears the stored value of every field that conditionally depends
            //   // on [parentFieldId], so that once a field becomes hidden again its
            //   // old answer isn't silently carried along in the submission.
            //   void _clearFieldsDependingOn(dynamic parentFieldId) {
            //     for (var section in _sections) {
            //       for (var f in (section['fields'] ?? [])) {
            //         if (f['parent_field_id'] != null &&
            //             f['parent_field_id'].toString() == parentFieldId.toString()) {
            //           final depName = f['field_name'] ?? '';
            //           if (_controllers.containsKey(depName)) {
            //             _controllers[depName]!.clear();
            //           }
            //           if (_selectedOptions.containsKey(depName)) {
            //             _selectedOptions[depName] = '';
            //           }
            //           // Clear recursively in case a field depends on this dependent field.
            //           if (f['id'] != null) {
            //             _clearFieldsDependingOn(f['id']);
            //           }
            //         }
            //       }
            //     }
            //   }

            //   List<Map<String, dynamic>> _getFieldsForSelectedSection() {
            //     if (_selectedSectionId == null) return [];

            //     final selectedSection = _sections.firstWhere(
            //       (s) => s['id'] == _selectedSectionId,
            //       orElse: () => null,
            //     );

            //     if (selectedSection == null) return [];

            //     final sectionFields = (selectedSection['fields'] ?? []) as List;
            //     return sectionFields.where((f) => _isFieldVisible(f)).cast<Map<String, dynamic>>().toList();
            //   }

            //   List<dynamic> _getDocumentsForSelectedSection() {
            //     if (_selectedSectionId == null) return [];
            //     final selectedSection = _sections.firstWhere(
            //       (s) => s['id'] == _selectedSectionId,
            //       orElse: () => null,
            //     );
            //     if (selectedSection == null) return [];
            //     final sectionDocs = (selectedSection['documents'] as List?) ?? [];
            //     if (sectionDocs.isNotEmpty) return sectionDocs;
            //     // FIX: section has no documents of its own -> fall back to the
            //     // WHOLE SERVICE's required documents, fetched independently via
            //     // its own dedicated endpoint (see _fetchFormConfig), so this
            //     // always has data regardless of what _formConfig contains.
            //     if (_serviceLevelDocuments.isNotEmpty) return _serviceLevelDocuments;
            //     return (_formConfig?['documents'] as List?) ?? [];
            //   }

            //   // ==================== FILE PICKING & SUBMIT ====================

            //   Future<void> _pickDocuments(String docId) async {
            //     try {
            //       final result = await FilePicker.platform.pickFiles(
            //         type: FileType.custom,
            //         allowMultiple: true,
            //         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
            //         withData: true,
            //       );

            //       if (result != null && result.files.isNotEmpty) {
            //         setState(() {
            //           _uploadedDocs[docId] ??= [];

            //           for (var file in result.files) {
            //             _uploadedDocs[docId]!.add({
            //               'bytes': file.bytes,
            //               'name': file.name,
            //               'size': file.size,
            //               'extension': file.extension,
            //             });
            //           }
            //         });

            //         if (mounted) {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text('📎 ${result.files.length} file(s) uploaded'),
            //               backgroundColor: success,
            //               duration: const Duration(seconds: 1),
            //               behavior: SnackBarBehavior.floating,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //             ),
            //           );
            //         }
            //       }
            //     } catch (e) {
            //       if (mounted) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: const Text('❌ Error picking files'),
            //             backgroundColor: Colors.red,
            //             behavior: SnackBarBehavior.floating,
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //           ),
            //         );
            //       }
            //     }
            //   }

            //   void _removeDocumentFile(String docId, int index) {
            //     setState(() {
            //       _uploadedDocs[docId]?.removeAt(index);
            //     });
            //   }

            //   Future<void> _submitForm() async {
            //     if (!_formKey.currentState!.validate()) return;

            //     if (!_termsAccepted) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(
            //           content: const Text('⚠️ Please accept Terms & Conditions'),
            //           backgroundColor: warning,
            //           behavior: SnackBarBehavior.floating,
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //         ),
            //       );
            //       return;
            //     }

            //     final auth = Provider.of<AuthProvider>(context, listen: false);
            //     if (!auth.isLoggedIn) {
            //       _showLoginPopup();
            //       return;
            //     }

            //     if (_selectedSectionId == null) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(
            //           content: const Text('⚠️ Please select an application type'),
            //           backgroundColor: warning,
            //           behavior: SnackBarBehavior.floating,
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //         ),
            //       );
            //       return;
            //     }

            //     // Validate required documents for this section
            //     final docs = _getDocumentsForSelectedSection();
            //     for (var doc in docs) {
            //       if (doc['is_mandatory'] == 1 || doc['is_mandatory'] == true) {
            //         final docId = doc['id'].toString();
            //         final files = _uploadedDocs[docId] ?? [];
            //         if (files.isEmpty) {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text('📎 Please upload: ${doc['doc_name']}'),
            //               backgroundColor: Colors.red,
            //               duration: const Duration(seconds: 3),
            //               behavior: SnackBarBehavior.floating,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //             ),
            //           );
            //           return;
            //         }
            //       }
            //     }

            //     setState(() => _loading = true);

            //     Map<String, String> formValues = {};
            //     _controllers.forEach((key, ctrl) => formValues[key] = ctrl.text);
            //     _selectedOptions.forEach((key, value) {
            //       if (value.isNotEmpty) formValues[key] = value;
            //     });

            //     final selectedSection = _sections.firstWhere((s) => s['id'] == _selectedSectionId);
            //     formValues['selected_section'] = selectedSection['section_name'] ?? '';
            //     formValues['selected_section_id'] = _selectedSectionId.toString();

            //     try {
            //       var request = http.MultipartRequest(
            //           'POST', Uri.parse('${ApiService.baseUrl}/submit-application-with-docs'));
            //       request.fields['user_id'] = auth.userId.toString();
            //       request.fields['service_id'] = widget.service['id'].toString();
            //       request.fields['form_id'] = _formConfig!['id'].toString();
            //       request.fields['form_data'] = jsonEncode(formValues);

            //       for (var entry in _uploadedDocs.entries) {
            //         for (var fileInfo in entry.value) {
            //           if (fileInfo['bytes'] != null && fileInfo['name'] != null) {
            //             request.files.add(http.MultipartFile.fromBytes(
            //               'doc_${entry.key}',
            //               fileInfo['bytes'],
            //               filename: fileInfo['name'],
            //             ));
            //           }
            //         }
            //       }

            //       final streamedResponse = await request.send();
            //       final response = await http.Response.fromStream(streamedResponse);
            //       final result = jsonDecode(response.body);

            //       if (mounted) {
            //         setState(() => _loading = false);
            //         if (result['success'] == true) {
            //           setState(() {
            //             _submitted = true;
            //             _trackingId = result['tracking_id'];
            //           });
            //           // NEW: pull out anything that looks like a reusable personal
            //           // detail (name, address, DOB, Aadhaar/PAN, etc.) from what
            //           // was just typed, and save it to the user's profile so it's
            //           // ready to auto-fill on ANY other service next time.
            //           if (_saveDetailsForReuse && auth.userId != null) {
            //             _autoSaveDetailsForReuse(formValues, auth.userId!);
            //           }
            //         } else {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text('❌ ${result['message'] ?? 'Failed'}'),
            //               backgroundColor: Colors.red,
            //               behavior: SnackBarBehavior.floating,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //             ),
            //           );
            //         }
            //       }
            //     } catch (e) {
            //       if (mounted) {
            //         setState(() => _loading = false);
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: const Text('❌ Connection failed'),
            //             backgroundColor: Colors.red,
            //             behavior: SnackBarBehavior.floating,
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //           ),
            //         );
            //       }
            //     }
            //   }

            //   void _showLoginPopup() {
            //     showModalBottomSheet(
            //       context: context,
            //       isScrollControlled: true,
            //       backgroundColor: Colors.transparent,
            //       builder: (ctx) => _LoginPopup(onLoginSuccess: () {
            //         Navigator.pop(ctx);
            //         setState(() {});
            //       }),
            //     );
            //   }

            //   // ==================== BUILD ====================

            //   @override
            //   Widget build(BuildContext context) {
            //     final name = (widget.service['name'] ?? 'Service').toString();
            //     final color = _parseColor(widget.service['color']);
            //     final icon = _parseIcon(widget.service['icon']);

            //     return Scaffold(
            //       backgroundColor: bgColor,
            //       body: _submitted ? _buildSuccessScreen(name) : _buildDetailScreen(name, color, icon),
            //     );
            //   }

            //   Widget _buildDetailScreen(String name, Color color, IconData icon) {
            //     final desc = _effectiveDescription();
            //     final sectionImage = _effectiveSectionImage();
            //     final headerTitle = _currentSection != null
            //         ? '$name - ${(_currentSection!['section_name'] ?? '').toString()}'
            //         : name;

            //     return CustomScrollView(
            //       slivers: [
            //         SliverAppBar(
            //           expandedHeight: 200,
            //           pinned: true,
            //           backgroundColor: color,
            //           elevation: 0,
            //           iconTheme: const IconThemeData(color: Colors.white),
            //           flexibleSpace: FlexibleSpaceBar(
            //             background: Container(
            //               decoration: BoxDecoration(
            //                 gradient: LinearGradient(
            //                   colors: [color, color.withAlpha(180)],
            //                   begin: Alignment.topLeft,
            //                   end: Alignment.bottomRight,
            //                 ),
            //               ),
            //               child: SafeArea(
            //                 child: Center(
            //                   child: Column(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     children: [
            //                       TweenAnimationBuilder<double>(
            //                         tween: Tween<double>(begin: 0.0, end: 1.0),
            //                         duration: const Duration(milliseconds: 600),
            //                         builder: (BuildContext context, double value,
            //                             Widget? child) {
            //                           return Transform.scale(
            //                             scale: value,
            //                             child: Container(
            //                               width: 72,
            //                               height: 72,
            //                               decoration: BoxDecoration(
            //                                 color: Colors.white.withAlpha(40),
            //                                 borderRadius: BorderRadius.circular(20),
            //                                 boxShadow: [
            //                                   BoxShadow(
            //                                     color: Colors.black.withAlpha(20),
            //                                     blurRadius: 20,
            //                                     offset: const Offset(0, 8),
            //                                   ),
            //                                 ],
            //                               ),
            //                               clipBehavior: Clip.antiAlias,
            //                               child: sectionImage.isNotEmpty
            //                                   ? Image.network(
            //                                       sectionImage,
            //                                       fit: BoxFit.cover,
            //                                       errorBuilder: (c, e, s) =>
            //                                           Icon(icon, color: Colors.white, size: 36),
            //                                     )
            //                                   : Icon(icon, color: Colors.white, size: 36),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                       const SizedBox(height: 12),
            //                       TweenAnimationBuilder<double>(
            //                         tween: Tween<double>(begin: 0.0, end: 1.0),
            //                         duration: const Duration(milliseconds: 800),
            //                         builder: (BuildContext context, double value,
            //                             Widget? child) {
            //                           return Opacity(
            //                             opacity: value,
            //                             child: Transform.translate(
            //                               offset: Offset(0, 20 * (1 - value)),
            //                               child: Padding(
            //                                 padding: const EdgeInsets.symmetric(horizontal: 16),
            //                                 child: Text(
            //                                   headerTitle,
            //                                   style: const TextStyle(
            //                                     color: Colors.white,
            //                                     fontSize: 20,
            //                                     fontWeight: FontWeight.bold,
            //                                     letterSpacing: 0.5,
            //                                   ),
            //                                   textAlign: TextAlign.center,
            //                                 ),
            //                               ),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //         SliverToBoxAdapter(
            //           child: _loadingForm
            //               ? Center(
            //                   child: Padding(
            //                     padding: const EdgeInsets.all(40),
            //                     child: Column(
            //                       children: [
            //                         Container(
            //                           width: 60,
            //                           height: 60,
            //                           decoration: BoxDecoration(
            //                             gradient: LinearGradient(
            //                               colors: [primary, primaryDark],
            //                               begin: Alignment.topLeft,
            //                               end: Alignment.bottomRight,
            //                             ),
            //                             borderRadius: BorderRadius.circular(16),
            //                           ),
            //                           child: const Center(
            //                             child: SizedBox(
            //                               width: 30,
            //                               height: 30,
            //                               child: CircularProgressIndicator(
            //                                 color: Colors.white,
            //                                 strokeWidth: 3,
            //                               ),
            //                             ),
            //                           ),
            //                         ),
            //                         const SizedBox(height: 16),
            //                         Text(
            //                           'Loading form...',
            //                           style: TextStyle(
            //                             color: textSecondaryColor,
            //                             fontSize: 14,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 )
            //               : FadeTransition(
            //                   opacity: _fadeAnimation,
            //                   child: Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       const SizedBox(height: 16),
            //                       _buildInfoCard(),
            //                       const SizedBox(height: 20),
            //                       if (desc.isNotEmpty) ...[
            //                         _sectionTitle('About This Service'),
            //                         Padding(
            //                           padding: const EdgeInsets.symmetric(horizontal: 16),
            //                           child: Container(
            //                             padding: const EdgeInsets.all(16),
            //                             decoration: BoxDecoration(
            //                               color: cardBg,
            //                               borderRadius: BorderRadius.circular(16),
            //                               boxShadow: [
            //                                 BoxShadow(
            //                                   color: Colors.grey.withAlpha(15),
            //                                   blurRadius: 10,
            //                                   offset: const Offset(0, 4),
            //                                 ),
            //                               ],
            //                             ),
            //                             child: Text(
            //                               desc,
            //                               style: TextStyle(
            //                                 color: textSecondaryColor,
            //                                 fontSize: 13,
            //                                 height: 1.6,
            //                               ),
            //                             ),
            //                           ),
            //                         ),
            //                         const SizedBox(height: 20),
            //                       ],

            //                       // Use Saved Details Button
            //                       if (_savedDetails != null && _savedDetails!.isNotEmpty) ...[
            //                         Padding(
            //                           padding: const EdgeInsets.symmetric(horizontal: 16),
            //                           child: InkWell(
            //                             onTap: _useSavedDetails,
            //                             borderRadius: BorderRadius.circular(16),
            //                             child: Container(
            //                               padding: const EdgeInsets.all(16),
            //                               decoration: BoxDecoration(
            //                                 gradient: LinearGradient(
            //                                   colors: [success.withAlpha(15), success.withAlpha(30)],
            //                                   begin: Alignment.topLeft,
            //                                   end: Alignment.bottomRight,
            //                                 ),
            //                                 borderRadius: BorderRadius.circular(16),
            //                                 border: Border.all(color: success.withAlpha(80)),
            //                               ),
            //                               child: Row(
            //                                 children: [
            //                                   Container(
            //                                     width: 44,
            //                                     height: 44,
            //                                     decoration: BoxDecoration(
            //                                       gradient: LinearGradient(
            //                                         colors: [success, success.withAlpha(180)],
            //                                         begin: Alignment.topLeft,
            //                                         end: Alignment.bottomRight,
            //                                       ),
            //                                       borderRadius: BorderRadius.circular(12),
            //                                     ),
            //                                     child: const Icon(Icons.person_outline,
            //                                         color: Colors.white, size: 24),
            //                                   ),
            //                                   const SizedBox(width: 12),
            //                                   Expanded(
            //                                     child: Column(
            //                                       crossAxisAlignment: CrossAxisAlignment.start,
            //                                       children: [
            //                                         Text(
            //                                           '✨ Use My Saved Details',
            //                                           style: TextStyle(
            //                                             fontWeight: FontWeight.bold,
            //                                             fontSize: 14,
            //                                             color: success,
            //                                           ),
            //                                         ),
            //                                         Text(
            //                                           'Auto-fill form & attach saved documents',
            //                                           style: TextStyle(
            //                                             fontSize: 11,
            //                                             color: success.withAlpha(180),
            //                                           ),
            //                                         ),
            //                                       ],
            //                                     ),
            //                                   ),
            //                                   Icon(Icons.arrow_forward_ios, size: 16,
            //                                       color: success),
            //                                 ],
            //                               ),
            //                             ),
            //                           ),
            //                         ),
            //                         const SizedBox(height: 16),
            //                       ],

            //                       // Saved Documents
            //                       if (_savedDocuments.isNotEmpty) ...[
            //                         Padding(
            //                           padding: const EdgeInsets.symmetric(horizontal: 16),
            //                           child: InkWell(
            //                             onTap: () => setState(() => _showSavedDocs = !_showSavedDocs),
            //                             borderRadius: BorderRadius.circular(16),
            //                             child: Container(
            //                               padding: const EdgeInsets.all(16),
            //                               decoration: BoxDecoration(
            //                                 gradient: LinearGradient(
            //                                   colors: [primary.withAlpha(10), primaryDark.withAlpha(10)],
            //                                   begin: Alignment.topLeft,
            //                                   end: Alignment.bottomRight,
            //                                 ),
            //                                 borderRadius: BorderRadius.circular(16),
            //                                 border: Border.all(color: primary.withAlpha(40)),
            //                               ),
            //                               child: Row(
            //                                 children: [
            //                                   Container(
            //                                     width: 44,
            //                                     height: 44,
            //                                     decoration: BoxDecoration(
            //                                       gradient: LinearGradient(
            //                                         colors: [primary, primaryDark],
            //                                         begin: Alignment.topLeft,
            //                                         end: Alignment.bottomRight,
            //                                       ),
            //                                       borderRadius: BorderRadius.circular(12),
            //                                     ),
            //                                     child: const Icon(Icons.folder_shared,
            //                                         color: Colors.white, size: 24),
            //                                   ),
            //                                   const SizedBox(width: 12),
            //                                   Expanded(
            //                                     child: Column(
            //                                       crossAxisAlignment: CrossAxisAlignment.start,
            //                                       children: [
            //                                         const Text(
            //                                           'My Saved Documents',
            //                                           style: TextStyle(
            //                                             fontWeight: FontWeight.bold,
            //                                             fontSize: 14,
            //                                             color: textPrimaryColor,
            //                                           ),
            //                                         ),
            //                                         Text(
            //                                           '${_savedDocuments.length} document(s) available',
            //                                           style: TextStyle(
            //                                             fontSize: 11,
            //                                             color: textSecondaryColor,
            //                                           ),
            //                                         ),
            //                                       ],
            //                                     ),
            //                                   ),
            //                                   Icon(
            //                                     _showSavedDocs
            //                                         ? Icons.keyboard_arrow_up
            //                                         : Icons.keyboard_arrow_down,
            //                                     color: primary,
            //                                   ),
            //                                 ],
            //                               ),
            //                             ),
            //                           ),
            //                         ),
            //                         if (_showSavedDocs)
            //                           Container(
            //                             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //                             padding: const EdgeInsets.all(12),
            //                             decoration: BoxDecoration(
            //                               color: cardBg,
            //                               borderRadius: BorderRadius.circular(16),
            //                               boxShadow: [
            //                                 BoxShadow(
            //                                   color: Colors.grey.withAlpha(15),
            //                                   blurRadius: 10,
            //                                   offset: const Offset(0, 4),
            //                                 ),
            //                               ],
            //                             ),
            //                             child: Column(
            //                               children: [
            //                                 const Text(
            //                                   'Tap to manually attach a saved document',
            //                                   style: TextStyle(fontSize: 11, color: textSecondaryColor),
            //                                 ),
            //                                 const SizedBox(height: 8),
            //                                 ..._savedDocuments.map((doc) {
            //                                   final docType = doc['doc_type'] ?? '';
            //                                   final docName = doc['doc_name'] ?? '';
            //                                   final filePath = doc['file_path'] ?? '';
            //                                   return ListTile(
            //                                     dense: true,
            //                                     leading: Icon(_getDocTypeIcon(docType),
            //                                         color: primary, size: 22),
            //                                     title: Text(
            //                                       _getDocTypeLabel(docType),
            //                                       style: const TextStyle(
            //                                           fontWeight: FontWeight.w500,
            //                                           fontSize: 12),
            //                                     ),
            //                                     subtitle: Text(
            //                                       docName,
            //                                       style: TextStyle(
            //                                           fontSize: 10,
            //                                           color: textSecondaryColor),
            //                                     ),
            //                                     trailing: Icon(Icons.add_circle,
            //                                         color: success, size: 20),
            //                                     onTap: () {
            //                                       _fetchAndAttachDocument(
            //                                           filePath, docName, docType);
            //                                     },
            //                                   );
            //                                 }),
            //                               ],
            //                             ),
            //                           ),
            //                         const SizedBox(height: 16),
            //                       ],

            //                       // NOTE: "Required Documents" used to render HERE,
            //                       // before the form fields. It's now rendered AFTER
            //                       // the fields instead, inside _buildForm(), so the
            //                       // natural order is: fill in fields -> then attach
            //                       // the documents they need -> then submit.

            //                       _sectionTitle(_formConfig?['form_title'] ?? 'Application Form'),

            //                       // Section Selector
            //                       if (_sections.isNotEmpty && !_hasPreselectedSection) ...[
            //                         Padding(
            //                           padding: const EdgeInsets.symmetric(horizontal: 16),
            //                           child: Container(
            //                             padding: const EdgeInsets.all(16),
            //                             decoration: BoxDecoration(
            //                               color: cardBg,
            //                               borderRadius: BorderRadius.circular(16),
            //                               boxShadow: [
            //                                 BoxShadow(
            //                                   color: Colors.grey.withAlpha(15),
            //                                   blurRadius: 10,
            //                                   offset: const Offset(0, 4),
            //                                 ),
            //                               ],
            //                             ),
            //                             child: Column(
            //                               crossAxisAlignment: CrossAxisAlignment.start,
            //                               children: [
            //                                 Row(
            //                                   children: [
            //                                     Icon(Icons.select_all, color: primary,
            //                                         size: 20),
            //                                     const SizedBox(width: 8),
            //                                     const Text(
            //                                       'Select Application Type',
            //                                       style: TextStyle(
            //                                         fontSize: 14,
            //                                         fontWeight: FontWeight.bold,
            //                                         color: textPrimaryColor,
            //                                       ),
            //                                     ),
            //                                   ],
            //                                 ),
            //                                 const SizedBox(height: 6),
            //                                 Text(
            //                                   'Choose one option below to proceed',
            //                                   style: TextStyle(
            //                                       fontSize: 12, color: textSecondaryColor),
            //                                 ),
            //                                 const SizedBox(height: 12),
            //                                 ..._sections.asMap().entries.map((entry) {
            //                                   final index = entry.key;
            //                                   final section = entry.value;
            //                                   final isSelected =
            //                                       _selectedSectionId == section['id'];
            //                                   final sectionName =
            //                                       section['section_name'] ?? '';
            //                                   final fieldCount =
            //                                       (section['fields'] ?? []).length;
            //                                   final fee = section['fee'] ?? 'Varies';
            //                                   final time = section['processing_time'] ?? '3-7 Days';

            //                                   return TweenAnimationBuilder<double>(
            //                                     tween: Tween<double>(begin: 0.0, end: 1.0),
            //                                     duration: Duration(
            //                                         milliseconds: 300 + (index * 50)),
            //                                     builder: (BuildContext context,
            //                                         double value, Widget? child) {
            //                                       return Opacity(
            //                                         opacity: value,
            //                                         child: Transform.translate(
            //                                           offset: Offset(20 * (1 - value), 0),
            //                                           child: Container(
            //                                             margin: const EdgeInsets.only(
            //                                                 bottom: 8),
            //                                             child: InkWell(
            //                                               onTap: () {
            //                                                 setState(() {
            //                                                   _selectedSectionId =
            //                                                       section['id'];
            //                                                   _controllers.forEach((key,
            //                                                           ctrl) =>
            //                                                       ctrl.clear());
            //                                                   _selectedOptions.forEach(
            //                                                       (key, value) =>
            //                                                           _selectedOptions[
            //                                                               key] = '');
            //                                                   _uploadedDocs.clear();
            //                                                   _selectedOptions
            //                                                       .remove('age_status');
            //                                                 });
            //                                               },
            //                                               borderRadius:
            //                                                   BorderRadius.circular(12),
            //                                               child: Container(
            //                                                 padding:
            //                                                     const EdgeInsets.all(14),
            //                                                 decoration: BoxDecoration(
            //                                                   gradient: isSelected
            //                                                       ? LinearGradient(
            //                                                           colors: [
            //                                                             primary,
            //                                                             primaryDark
            //                                                           ],
            //                                                           begin: Alignment
            //                                                               .topLeft,
            //                                                           end: Alignment
            //                                                               .bottomRight,
            //                                                         )
            //                                                       : null,
            //                                                   color: isSelected
            //                                                       ? null
            //                                                       : Colors.grey[50],
            //                                                   borderRadius:
            //                                                       BorderRadius.circular(12),
            //                                                   border: Border.all(
            //                                                     color: isSelected
            //                                                         ? Colors.transparent
            //                                                         : Colors.grey[300]!,
            //                                                     width: isSelected ? 0 : 1,
            //                                                   ),
            //                                                   boxShadow: isSelected
            //                                                       ? [
            //                                                           BoxShadow(
            //                                                             color: primary
            //                                                                 .withAlpha(40),
            //                                                             blurRadius: 12,
            //                                                             offset:
            //                                                                 const Offset(
            //                                                                     0, 4),
            //                                                           ),
            //                                                         ]
            //                                                       : null,
            //                                                 ),
            //                                                 child: Row(
            //                                                   children: [
            //                                                     Container(
            //                                                       width: 36,
            //                                                       height: 36,
            //                                                       decoration: BoxDecoration(
            //                                                         color: isSelected
            //                                                             ? Colors.white
            //                                                                 .withAlpha(30)
            //                                                             : Colors.grey[300],
            //                                                         borderRadius:
            //                                                             BorderRadius
            //                                                                 .circular(8),
            //                                                       ),
            //                                                       child: Icon(
            //                                                         isSelected
            //                                                             ? Icons.check_circle
            //                                                             : Icons
            //                                                                 .radio_button_unchecked,
            //                                                         color: isSelected
            //                                                             ? Colors.white
            //                                                             : Colors.grey[600],
            //                                                         size: 18,
            //                                                       ),
            //                                                     ),
            //                                                     const SizedBox(width: 12),
            //                                                     Expanded(
            //                                                       child: Column(
            //                                                         crossAxisAlignment:
            //                                                             CrossAxisAlignment
            //                                                                 .start,
            //                                                         children: [
            //                                                           Text(
            //                                                             sectionName,
            //                                                             style: TextStyle(
            //                                                               fontSize: 14,
            //                                                               fontWeight:
            //                                                                   FontWeight
            //                                                                       .w600,
            //                                                               color: isSelected
            //                                                                   ? Colors.white
            //                                                                   : textPrimaryColor,
            //                                                             ),
            //                                                           ),
            //                                                           Text(
            //                                                             '$fieldCount field(s) • Fee: $fee • $time',
            //                                                             style: TextStyle(
            //                                                               fontSize: 11,
            //                                                               color: isSelected
            //                                                                   ? Colors
            //                                                                       .white70
            //                                                                   : textSecondaryColor,
            //                                                             ),
            //                                                           ),
            //                                                         ],
            //                                                       ),
            //                                                     ),
            //                                                     if (isSelected)
            //                                                       Container(
            //                                                         padding:
            //                                                             const EdgeInsets
            //                                                                 .symmetric(
            //                                                           horizontal: 10,
            //                                                           vertical: 4,
            //                                                         ),
            //                                                         decoration:
            //                                                             BoxDecoration(
            //                                                           color: Colors.white
            //                                                               .withAlpha(30),
            //                                                           borderRadius:
            //                                                               BorderRadius
            //                                                                   .circular(12),
            //                                                         ),
            //                                                         child: const Text(
            //                                                           'SELECTED',
            //                                                           style: TextStyle(
            //                                                             color: Colors.white,
            //                                                             fontSize: 9,
            //                                                             fontWeight:
            //                                                                 FontWeight.bold,
            //                                                           ),
            //                                                         ),
            //                                                       ),
            //                                                   ],
            //                                                 ),
            //                                               ),
            //                                             ),
            //                                           ),
            //                                         ),
            //                                       );
            //                                     },
            //                                   );
            //                                 }),
            //                               ],
            //                             ),
            //                           ),
            //                         ),
            //                         const SizedBox(height: 20),
            //                       ],

            //                       // Form Fields
            //                       _buildForm(),
            //                       const SizedBox(height: 40),
            //                     ],
            //                   ),
            //                 ),
            //         ),
            //       ],
            //     );
            //   }

            //   Widget _buildInfoCard() {
            //     final fee = _sectionFee();
            //     final time = _sectionProcessingTime();
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: cardBg,
            //           borderRadius: BorderRadius.circular(16),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.grey.withAlpha(15),
            //               blurRadius: 10,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceAround,
            //           children: [
            //             _infoChip(Icons.currency_rupee, 'Fee', fee, primary),
            //             Container(width: 1, height: 40, color: Colors.grey[200]),
            //             _infoChip(Icons.timer, 'Processing Time', time, secondary),
            //             Container(width: 1, height: 40, color: Colors.grey[200]),
            //             _infoChip(Icons.verified_user, 'Help', 'Expert', success),
            //           ],
            //         ),
            //       ),
            //     );
            //   }

            //   Widget _infoChip(IconData icon, String label, String value, Color color) {
            //     return Column(
            //       children: [
            //         Container(
            //           padding: const EdgeInsets.all(8),
            //           decoration: BoxDecoration(
            //             color: color.withAlpha(15),
            //             borderRadius: BorderRadius.circular(10),
            //           ),
            //           child: Icon(icon, color: color, size: 18),
            //         ),
            //         const SizedBox(height: 4),
            //         Text(
            //           label,
            //           style: TextStyle(fontSize: 10, color: textSecondaryColor),
            //         ),
            //         Text(
            //           value,
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 12,
            //             color: textPrimaryColor,
            //           ),
            //         ),
            //       ],
            //     );
            //   }

            //   Widget _buildDocumentsSection() {
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: _buildDocumentsCardContent(),
            //     );
            //   }

            //   // NEW: same card content as _buildDocumentsSection, but without the
            //   // extra horizontal padding — used when embedding the documents
            //   // section directly inside the form card (which already has its own
            //   // padding), i.e. the "documents after the fields" placement.
            //   Widget _buildDocumentsSectionInline() {
            //     return _buildDocumentsCardContent();
            //   }

            //   Widget _buildDocumentsCardContent() {
            //     final docs = _getDocumentsForSelectedSection();
            //     return Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: cardBg,
            //           borderRadius: BorderRadius.circular(16),
            //           border: Border.all(color: warning.withAlpha(100)),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.grey.withAlpha(15),
            //               blurRadius: 10,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Row(
            //               children: [
            //                 Icon(Icons.warning_amber_rounded, color: warning, size: 22),
            //                 const SizedBox(width: 8),
            //                 const Expanded(
            //                   child: Text(
            //                     'Upload the required documents below',
            //                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //             const SizedBox(height: 16),
            //             ...docs.map((doc) {
            //               final docId = doc['id'].toString();
            //               final docName = (doc['doc_name'] ?? '').toString();
            //               final mandatory = doc['is_mandatory'] == 1 ||
            //                   doc['is_mandatory'] == true;
            //               final files = _uploadedDocs[docId] ?? [];
            //               return _buildDocCard(docId, docName, mandatory, files);
            //             }),
            //           ],
            //         ),
            //       );
            //   }

            //   Widget _buildDocCard(String docId, String docName, bool mandatory,
            //       List<Map<String, dynamic>> files) {
            //     final hasFiles = files.isNotEmpty;

            //     return Container(
            //       margin: const EdgeInsets.only(bottom: 12),
            //       padding: const EdgeInsets.all(12),
            //       decoration: BoxDecoration(
            //         color: hasFiles ? success.withAlpha(12) : Colors.grey[50],
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(
            //           color: hasFiles ? success : Colors.grey[300]!,
            //           width: hasFiles ? 2 : 1.5,
            //         ),
            //       ),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Row(
            //             children: [
            //               Icon(
            //                 hasFiles
            //                     ? Icons.check_circle
            //                     : (mandatory
            //                         ? Icons.radio_button_unchecked
            //                         : Icons.info_outline),
            //                 color: hasFiles
            //                     ? success
            //                     : (mandatory ? warning : Colors.grey),
            //                 size: 22,
            //               ),
            //               const SizedBox(width: 8),
            //               Expanded(
            //                 child: Text(
            //                   docName,
            //                   style: TextStyle(
            //                     fontSize: 13,
            //                     fontWeight: FontWeight.w600,
            //                     color: hasFiles ? success : textPrimaryColor,
            //                   ),
            //                 ),
            //               ),
            //               Container(
            //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            //                 decoration: BoxDecoration(
            //                   color: mandatory
            //                       ? warning.withAlpha(25)
            //                       : Colors.grey[200]!,
            //                   borderRadius: BorderRadius.circular(6),
            //                 ),
            //                 child: Text(
            //                   mandatory ? 'Required' : 'Optional',
            //                   style: TextStyle(
            //                     fontSize: 10,
            //                     fontWeight: FontWeight.w700,
            //                     color: mandatory ? warning : Colors.grey[600],
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //           const SizedBox(height: 10),
            //           InkWell(
            //             onTap: () => _pickDocuments(docId),
            //             child: Container(
            //               width: double.infinity,
            //               padding: const EdgeInsets.symmetric(vertical: 12),
            //               decoration: BoxDecoration(
            //                 color: hasFiles ? success.withAlpha(8) : primary.withAlpha(8),
            //                 borderRadius: BorderRadius.circular(8),
            //                 border: Border.all(
            //                   color: hasFiles ? success : primary.withAlpha(60),
            //                   width: hasFiles ? 2 : 1.5,
            //                 ),
            //               ),
            //               child: Row(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Icon(
            //                     hasFiles
            //                         ? Icons.add_circle_outline
            //                         : Icons.cloud_upload_outlined,
            //                     size: 20,
            //                     color: hasFiles ? success : primary,
            //                   ),
            //                   const SizedBox(width: 8),
            //                   Text(
            //                     hasFiles
            //                         ? 'Add More Files (${files.length})'
            //                         : 'Tap to Upload',
            //                     style: TextStyle(
            //                       fontSize: 13,
            //                       fontWeight: FontWeight.w600,
            //                       color: hasFiles ? success : primary,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           if (hasFiles) ...[
            //             const SizedBox(height: 10),
            //             ...List.generate(files.length, (i) {
            //               final f = files[i];
            //               final name = f['name'] ?? '';
            //               final size = f['size'];

            //               return Container(
            //                 margin: const EdgeInsets.only(top: 6),
            //                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            //                 decoration: BoxDecoration(
            //                   color: cardBg,
            //                   borderRadius: BorderRadius.circular(8),
            //                   border: Border.all(color: success.withAlpha(100)),
            //                 ),
            //                 child: Row(
            //                   children: [
            //                     Container(
            //                       width: 36,
            //                       height: 36,
            //                       decoration: BoxDecoration(
            //                         color: _getFileColor(name).withAlpha(40),
            //                         borderRadius: BorderRadius.circular(6),
            //                       ),
            //                       child: Icon(
            //                         _getFileIcon(name),
            //                         color: _getFileColor(name),
            //                         size: 18,
            //                       ),
            //                     ),
            //                     const SizedBox(width: 10),
            //                     Expanded(
            //                       child: Column(
            //                         crossAxisAlignment: CrossAxisAlignment.start,
            //                         children: [
            //                           Text(
            //                             name,
            //                             style: const TextStyle(
            //                                 fontSize: 12, fontWeight: FontWeight.w500),
            //                             maxLines: 1,
            //                             overflow: TextOverflow.ellipsis,
            //                           ),
            //                           Text(
            //                             _formatFileSize(size),
            //                             style: TextStyle(
            //                                 fontSize: 10, color: textSecondaryColor),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                     IconButton(
            //                       icon: const Icon(Icons.close, color: Colors.red, size: 18),
            //                       onPressed: () => _removeDocumentFile(docId, i),
            //                       padding: EdgeInsets.zero,
            //                       constraints: const BoxConstraints(),
            //                     ),
            //                   ],
            //                 ),
            //               );
            //             }),
            //           ],
            //         ],
            //       ),
            //     );
            //   }

            //   // ==================== FORM BUILDING WITH GROUPING ====================

            //   Widget _buildForm() {
            //     final auth = Provider.of<AuthProvider>(context);
            //     final isGuest = !auth.isLoggedIn;
            //     final selectedFields = _getFieldsForSelectedSection();

            //     return Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: Container(
            //         padding: const EdgeInsets.all(20),
            //         decoration: BoxDecoration(
            //           color: cardBg,
            //           borderRadius: BorderRadius.circular(20),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.grey.withAlpha(15),
            //               blurRadius: 10,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Form(
            //           key: _formKey,
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               if (isGuest)
            //                 Container(
            //                   margin: const EdgeInsets.only(bottom: 16),
            //                   padding: const EdgeInsets.all(12),
            //                   decoration: BoxDecoration(
            //                     color: warning.withAlpha(25),
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   child: Row(
            //                     children: [
            //                       const Icon(Icons.lock, color: warning, size: 18),
            //                       const SizedBox(width: 8),
            //                       const Expanded(
            //                         child: Text(
            //                           'Login required to submit application',
            //                           style: TextStyle(fontSize: 12, color: textSecondaryColor),
            //                         ),
            //                       ),
            //                       TextButton(
            //                         onPressed: _showLoginPopup,
            //                         style: TextButton.styleFrom(
            //                           backgroundColor: primary,
            //                           foregroundColor: Colors.white,
            //                           shape: RoundedRectangleBorder(
            //                             borderRadius: BorderRadius.circular(8),
            //                           ),
            //                         ),
            //                         child: const Text('Login',
            //                             style: TextStyle(fontWeight: FontWeight.bold)),
            //                       ),
            //                     ],
            //                   ),
            //                 ),

            //               if (_selectedSectionId != null) ...[
            //                 Container(
            //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //                   decoration: BoxDecoration(
            //                     gradient: LinearGradient(
            //                       colors: [primary.withAlpha(15), primaryDark.withAlpha(15)],
            //                       begin: Alignment.topLeft,
            //                       end: Alignment.bottomRight,
            //                     ),
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   child: Row(
            //                     children: [
            //                       Icon(Icons.edit_note, color: primary, size: 18),
            //                       const SizedBox(width: 8),
            //                       Expanded(
            //                         child: Text(
            //                           '${_sections.firstWhere((s) => s['id'] == _selectedSectionId)['section_name']} - Form',
            //                           style: const TextStyle(
            //                             fontWeight: FontWeight.bold,
            //                             fontSize: 14,
            //                             color: textPrimaryColor,
            //                           ),
            //                         ),
            //                       ),
            //                       Container(
            //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            //                         decoration: BoxDecoration(
            //                           color: primary.withAlpha(15),
            //                           borderRadius: BorderRadius.circular(10),
            //                         ),
            //                         child: Text(
            //                           '${selectedFields.length} fields',
            //                           style: TextStyle(
            //                             fontSize: 11,
            //                             color: primary,
            //                             fontWeight: FontWeight.w600,
            //                           ),
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //                 const SizedBox(height: 16),
            //               ],

            //               if (selectedFields.isEmpty && _sections.isNotEmpty) ...[
            //                 Center(
            //                   child: Padding(
            //                     padding: const EdgeInsets.all(32),
            //                     child: Column(
            //                       children: [
            //                         Icon(Icons.info_outline, size: 48,
            //                             color: Colors.grey[300]),
            //                         const SizedBox(height: 12),
            //                         Text(
            //                           'No fields in this section',
            //                           style: TextStyle(color: textSecondaryColor),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 ),
            //               ],

            //               if (selectedFields.isNotEmpty) _buildGroupedFields(selectedFields),

            //               // NEW: documents now come AFTER the fields (previously
            //               // they were shown before the form). Falls back to the
            //               // whole service's document list when the selected
            //               // section has none of its own (see
            //               // _getDocumentsForSelectedSection).
            //               if (_selectedSectionId != null &&
            //                   _getDocumentsForSelectedSection().isNotEmpty) ...[
            //                 const SizedBox(height: 8),
            //                 Row(
            //                   children: [
            //                     Icon(Icons.folder_copy_outlined, color: primary, size: 18),
            //                     const SizedBox(width: 8),
            //                     Text(
            //                       'Required Documents',
            //                       style: TextStyle(
            //                         fontSize: 15,
            //                         fontWeight: FontWeight.bold,
            //                         color: textPrimaryColor,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //                 const SizedBox(height: 10),
            //                 _buildDocumentsSectionInline(),
            //                 const SizedBox(height: 8),
            //               ],

            //               if (_sections.isEmpty) ...[
            //                 Center(
            //                   child: Padding(
            //                     padding: const EdgeInsets.all(32),
            //                     child: Column(
            //                       children: [
            //                         Icon(Icons.warning_amber, size: 48, color: warning),
            //                         const SizedBox(height: 12),
            //                         Text(
            //                           'No application types available',
            //                           style: TextStyle(color: textSecondaryColor),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 ),
            //               ],

            //               if (_sections.isNotEmpty && _selectedSectionId == null) ...[
            //                 Center(
            //                   child: Padding(
            //                     padding: const EdgeInsets.all(32),
            //                     child: Column(
            //                       children: [
            //                         Icon(Icons.touch_app, size: 48,
            //                             color: primary.withAlpha(100)),
            //                         const SizedBox(height: 12),
            //                         Text(
            //                           'Please select an application type above',
            //                           style: TextStyle(
            //                             color: primary,
            //                             fontWeight: FontWeight.w500,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 ),
            //               ],

            //               const SizedBox(height: 8),
            //               Row(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   SizedBox(
            //                     width: 24,
            //                     child: Checkbox(
            //                       value: _termsAccepted,
            //                       onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            //                       activeColor: primary,
            //                       shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(4),
            //                       ),
            //                     ),
            //                   ),
            //                   Expanded(
            //                     child: RichText(
            //                       text: TextSpan(
            //                         style: TextStyle(fontSize: 11, color: textSecondaryColor),
            //                         children: [
            //                           const TextSpan(text: 'I agree to the '),
            //                           TextSpan(
            //                             text: 'Terms & Conditions',
            //                             style: TextStyle(
            //                               color: primary,
            //                               fontWeight: FontWeight.w600,
            //                               decoration: TextDecoration.underline,
            //                             ),
            //                             recognizer: TapGestureRecognizer()
            //                               ..onTap = () => Navigator.push(
            //                                     context,
            //                                     MaterialPageRoute(
            //                                         builder: (_) => const TermsScreen()),
            //                                   ),
            //                           ),
            //                           const TextSpan(text: ' and '),
            //                           TextSpan(
            //                             text: 'Privacy Policy',
            //                             style: TextStyle(
            //                               color: primary,
            //                               fontWeight: FontWeight.w600,
            //                               decoration: TextDecoration.underline,
            //                             ),
            //                             recognizer: TapGestureRecognizer()
            //                               ..onTap = () => Navigator.push(
            //                                     context,
            //                                     MaterialPageRoute(
            //                                         builder: (_) => const PrivacyScreen()),
            //                                   ),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //               const SizedBox(height: 8),
            //               Row(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   SizedBox(
            //                     width: 24,
            //                     child: Checkbox(
            //                       value: _saveDetailsForReuse,
            //                       onChanged: (v) =>
            //                           setState(() => _saveDetailsForReuse = v ?? false),
            //                       activeColor: success,
            //                       shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(4),
            //                       ),
            //                     ),
            //                   ),
            //                   Expanded(
            //                     child: Text(
            //                       'Save my details (name, address, DOB, Aadhaar/PAN, etc.) so I don\'t have to retype them on other services',
            //                       style: TextStyle(fontSize: 11, color: textSecondaryColor),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //               const SizedBox(height: 16),
            //               SizedBox(
            //                 width: double.infinity,
            //                 height: 52,
            //                 child: ElevatedButton(
            //                   onPressed: _loading ? null : _submitForm,
            //                   style: ElevatedButton.styleFrom(
            //                     backgroundColor: primary,
            //                     foregroundColor: Colors.white,
            //                     shape: RoundedRectangleBorder(
            //                       borderRadius: BorderRadius.circular(14),
            //                     ),
            //                     elevation: 0,
            //                   ),
            //                   child: _loading
            //                       ? const SizedBox(
            //                           width: 24,
            //                           height: 24,
            //                           child: CircularProgressIndicator(
            //                             color: Colors.white,
            //                             strokeWidth: 2.5,
            //                           ),
            //                         )
            //                       : const Text(
            //                           'Submit Application',
            //                           style: TextStyle(
            //                             fontSize: 16,
            //                             fontWeight: FontWeight.bold,
            //                             letterSpacing: 0.5,
            //                           ),
            //                         ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     );
            //   }

            //   // ==================== GROUPED FIELDS ====================

            //   Widget _buildGroupedFields(List<Map<String, dynamic>> selectedFields) {
            //     final Map<String, List<Map<String, dynamic>>> grouped = {};
            //     final List<String> groupOrder = [];

            //     for (var f in selectedFields) {
            //       final g = (f['field_group'] ?? '').toString().trim();
            //       final key = g.isEmpty ? '_ungrouped' : g;
            //       if (!grouped.containsKey(key)) {
            //         grouped[key] = [];
            //         groupOrder.add(key);
            //       }
            //       grouped[key]!.add(f);
            //     }

            //     // If only one ungrouped group, rename to "Details"
            //     if (groupOrder.length == 1 && groupOrder.first == '_ungrouped') {
            //       final fields = grouped['_ungrouped']!;
            //       grouped.clear();
            //       groupOrder.clear();
            //       grouped['Details'] = fields;
            //       groupOrder.add('Details');
            //     }

            //     int groupIndex = 0;
            //     final widgets = <Widget>[];

            //     for (var key in groupOrder) {
            //       final fields = grouped[key]!;
            //       if (key != '_ungrouped') {
            //         groupIndex++;
            //         widgets.add(_buildGroupHeader(groupIndex, key));
            //       }
            //       widgets.add(_buildResponsiveFieldRow(fields));
            //       widgets.add(const SizedBox(height: 6));
            //     }

            //     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
            //   }

            //   Widget _buildGroupHeader(int number, String title) {
            //     return Container(
            //       margin: const EdgeInsets.only(bottom: 14, top: 6),
            //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            //       decoration: BoxDecoration(
            //         gradient: const LinearGradient(
            //           colors: [Color(0xFFE0705A), Color(0xFF6C63FF)],
            //           begin: Alignment.centerLeft,
            //           end: Alignment.centerRight,
            //         ),
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: Text(
            //         '$number. $title',
            //         style: const TextStyle(
            //             color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            //       ),
            //     );
            //   }

            //   Widget _buildResponsiveFieldRow(List<Map<String, dynamic>> fields) {
            //     return LayoutBuilder(
            //       builder: (context, constraints) {
            //         final width = constraints.maxWidth;
            //         // FIX: the previous 300px breakpoint was still ABOVE the
            //         // actual available width on common ~360dp phones once the
            //         // outer Padding(16) + Form Container padding(20) on both sides
            //         // are subtracted (360 - 32 - 40 ≈ 288px), so phones kept
            //         // falling back to 1 column. 2 columns is now the default for
            //         // every normal width; only a genuinely tiny width (folded
            //         // split-screen, very old device) drops to 1, and wide
            //         // tablet/desktop screens get 3.
            //         int columns = 2;
            //         if (width >= 700) {
            //           columns = 3;
            //         } else if (width < 220) {
            //           columns = 1;
            //         }

            //         final List<Widget> rows = [];
            //         List<Map<String, dynamic>> buffer = [];

            //         void flush() {
            //           if (buffer.isEmpty) return;
            //           rows.add(
            //             Padding(
            //               padding: const EdgeInsets.only(bottom: 4),
            //               child: Row(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   for (int i = 0; i < buffer.length; i++) ...[
            //                     Expanded(child: _buildFieldWidget(buffer[i])),
            //                     if (i != buffer.length - 1) const SizedBox(width: 12),
            //                   ],
            //                   for (int i = buffer.length; i < columns; i++) ...[
            //                     const SizedBox(width: 12),
            //                     const Expanded(child: SizedBox()),
            //                   ],
            //                 ],
            //               ),
            //             ),
            //           );
            //           buffer = [];
            //         }

            //         for (var f in fields) {
            //           final type = (f['field_type'] ?? 'text').toString();
            //           final fullWidth = type == 'textarea' ||
            //               type == 'checkbox' ||
            //               type == 'multiselect' ||
            //               type == 'file';
            //           if (fullWidth) {
            //             flush();
            //             rows.add(Padding(
            //                 padding: const EdgeInsets.only(bottom: 4),
            //                 child: _buildFieldWidget(f)));
            //           } else {
            //             buffer.add(f);
            //             if (buffer.length == columns) flush();
            //           }
            //         }
            //         flush();

            //         return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
            //       },
            //     );
            //   }

            //   Widget _buildFieldWidget(Map<String, dynamic> field) {
            //     final type = (field['field_type'] ?? 'text').toString();
            //     final fname = (field['field_name'] ?? '').toString();
            //     final label = (field['field_label'] ?? '').toString();
            //     final required = field['is_required'] == 1 || field['is_required'] == true;
            //     final placeholder = (field['placeholder'] ?? '').toString();
            //     final helpText = (field['help_text'] ?? '').toString();
            //     // FIX: trim every option so values exactly match what the admin
            //     // picked as "show_when_value" (previously untrimmed, so " Female"
            //     // never matched the trimmed "Female" stored as the condition).
            //     final options = _parseOptions(field['select_options']);
            //     final fieldId = field['id'];

            //     return Padding(
            //       padding: const EdgeInsets.only(bottom: 14),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           _buildField(type, fname, label, required, placeholder, options, fieldId),
            //           if (helpText.isNotEmpty)
            //             Padding(
            //               padding: const EdgeInsets.only(top: 4, left: 4),
            //               child: Row(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Icon(Icons.info_outline, size: 12, color: textSecondaryColor),
            //                   const SizedBox(width: 4),
            //                   Expanded(
            //                     child: Text(
            //                       helpText,
            //                       style: TextStyle(
            //                         fontSize: 10,
            //                         color: textSecondaryColor,
            //                         fontStyle: FontStyle.italic,
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           // NEW: for address-like fields, offer an immediate way to
            //           // reuse a previously-saved address, and to save whatever was
            //           // just typed for next time - without waiting for the whole
            //           // form to be submitted. Restricted to text/textarea so a
            //           // dropdown like "address_proof_type" doesn't get this UI.
            //           if ((type == 'text' || type == 'textarea') &&
            //               _isAddressFieldName(fname))
            //             _buildAddressSaveReuseRow(fname),
            //         ],
            //       ),
            //     );
            //   }

            //   // Recognizes address-style fields regardless of the exact name a
            //   // given service happens to use for it.
            //   bool _isAddressFieldName(String fieldName) {
            //     final n = fieldName.toLowerCase();
            //     return n == 'address' ||
            //         n == 'address_line1' ||
            //         n == 'address1' ||
            //         n == 'permanent_address' ||
            //         n.contains('address');
            //   }

            //   Widget _buildAddressSaveReuseRow(String fieldName) {
            //     final controller = _controllers[fieldName];
            //     final savedAddress =
            //         (_savedDetails?['address_line1'] ?? '').toString().trim();
            //     final currentText = (controller?.text ?? '').trim();
            //     final hasSavedAddress = savedAddress.isNotEmpty;
            //     final canOfferReuse = hasSavedAddress && currentText != savedAddress;

            //     return Padding(
            //       padding: const EdgeInsets.only(top: 6, left: 4),
            //       child: Wrap(
            //         spacing: 8,
            //         runSpacing: 6,
            //         children: [
            //           if (canOfferReuse)
            //             InkWell(
            //               onTap: () {
            //                 setState(() {
            //                   controller?.text = savedAddress;
            //                 });
            //               },
            //               borderRadius: BorderRadius.circular(8),
            //               child: Container(
            //                 padding:
            //                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            //                 decoration: BoxDecoration(
            //                   color: primary.withAlpha(15),
            //                   borderRadius: BorderRadius.circular(8),
            //                   border: Border.all(color: primary.withAlpha(60)),
            //                 ),
            //                 child: Row(
            //                   mainAxisSize: MainAxisSize.min,
            //                   children: [
            //                     Icon(Icons.location_on, size: 13, color: primary),
            //                     const SizedBox(width: 4),
            //                     ConstrainedBox(
            //                       constraints: const BoxConstraints(maxWidth: 200),
            //                       child: Text(
            //                         'Use saved: $savedAddress',
            //                         style: TextStyle(fontSize: 11, color: primary),
            //                         overflow: TextOverflow.ellipsis,
            //                         maxLines: 1,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ),
            //           InkWell(
            //             onTap: currentText.isEmpty
            //                 ? null
            //                 : () => _saveAddressOnly(currentText),
            //             borderRadius: BorderRadius.circular(8),
            //             child: Container(
            //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            //               decoration: BoxDecoration(
            //                 color: currentText.isEmpty
            //                     ? Colors.grey.withAlpha(20)
            //                     : success.withAlpha(15),
            //                 borderRadius: BorderRadius.circular(8),
            //                 border: Border.all(
            //                     color: currentText.isEmpty
            //                         ? Colors.grey.withAlpha(60)
            //                         : success.withAlpha(60)),
            //               ),
            //               child: Row(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(Icons.save_outlined,
            //                       size: 13,
            //                       color: currentText.isEmpty ? Colors.grey : success),
            //                   const SizedBox(width: 4),
            //                   Text(
            //                     'Save this address',
            //                     style: TextStyle(
            //                       fontSize: 11,
            //                       color: currentText.isEmpty ? Colors.grey : success,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     );
            //   }

            //   Future<void> _saveAddressOnly(String address) async {
            //     final auth = Provider.of<AuthProvider>(context, listen: false);
            //     if (auth.userId == null) return;
            //     try {
            //       final res = await http.post(
            //         Uri.parse('${ApiService.baseUrl}/user/${auth.userId}/saved-details'),
            //         headers: {'Content-Type': 'application/json'},
            //         body: jsonEncode({'address_line1': address}),
            //       );
            //       if (res.statusCode == 200 && mounted) {
            //         final detailsResult = await _api.getUserSavedDetails(auth.userId!);
            //         setState(() {
            //           _savedDetails = detailsResult['details'];
            //         });
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: const Text('📍 Address saved for next time!'),
            //             backgroundColor: success,
            //             duration: const Duration(seconds: 2),
            //             behavior: SnackBarBehavior.floating,
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //           ),
            //         );
            //       }
            //     } catch (e) {
            //       debugPrint('Error saving address: $e');
            //     }
            //   }

            //   Widget _buildField(String type, String name, String label, bool required,
            //       String placeholder, List<String> options, dynamic fieldId) {
            //     final inputDecoration = InputDecoration(
            //       labelText: '$label${required ? " *" : ""}',
            //       hintText: placeholder,
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide(color: Colors.grey[300]!),
            //       ),
            //       enabledBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide(color: Colors.grey[300]!),
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide(color: primary, width: 2),
            //       ),
            //       filled: true,
            //       fillColor: Colors.grey[50],
            //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            //     );

            //     switch (type) {
            //       case 'text':
            //       case 'email':
            //       case 'phone':
            //       case 'number':
            //       case 'aadhaar':
            //       case 'pan':
            //         TextInputType keyboardType = TextInputType.text;
            //         int? maxLength;
            //         IconData fieldIcon = Icons.text_fields;
            //         if (type == 'email') {
            //           keyboardType = TextInputType.emailAddress;
            //           fieldIcon = Icons.email_outlined;
            //         }
            //         if (type == 'phone') {
            //           keyboardType = TextInputType.phone;
            //           maxLength = 10;
            //           fieldIcon = Icons.phone_outlined;
            //         }
            //         if (type == 'number') {
            //           keyboardType = TextInputType.number;
            //           fieldIcon = Icons.pin;
            //         }
            //         if (type == 'aadhaar') {
            //           keyboardType = TextInputType.number;
            //           maxLength = 12;
            //           fieldIcon = Icons.fingerprint;
            //         }
            //         if (type == 'pan') {
            //           maxLength = 10;
            //           fieldIcon = Icons.credit_card;
            //         }
            //         if (!_controllers.containsKey(name))
            //           _controllers[name] = TextEditingController();
            //         return TextFormField(
            //           controller: _controllers[name],
            //           keyboardType: keyboardType,
            //           maxLength: maxLength,
            //           decoration: inputDecoration.copyWith(
            //             prefixIcon: Icon(fieldIcon, size: 20, color: primary),
            //             counterText: '',
            //           ),
            //           validator: required
            //               ? (v) => v == null || v.isEmpty ? 'Required' : null
            //               : null,
            //           onChanged: (value) {
            //             setState(() {});
            //           },
            //         );

            //       case 'checkbox':
            //         return CheckboxListTile(
            //           title: Text('$label${required ? " *" : ""}'),
            //           value: _selectedOptions[name] == 'true',
            //           onChanged: (v) => setState(() {
            //             _selectedOptions[name] = v == true ? 'true' : 'false';
            //           }),
            //           activeColor: primary,
            //           contentPadding: EdgeInsets.zero,
            //           controlAffinity: ListTileControlAffinity.leading,
            //         );

            //       case 'date':
            //         if (!_controllers.containsKey(name))
            //           _controllers[name] = TextEditingController();
            //         return TextFormField(
            //           controller: _controllers[name],
            //           readOnly: true,
            //           decoration: inputDecoration.copyWith(
            //             prefixIcon: const Icon(Icons.calendar_today, size: 20,
            //                 color: primary),
            //           ),
            //           onTap: () async {
            //             final d = await showDatePicker(
            //               context: context,
            //               initialDate: DateTime(1990),
            //               firstDate: DateTime(1900),
            //               lastDate: DateTime.now(),
            //             );
            //             if (d != null) {
            //               final dateStr =
            //                   '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
            //               _controllers[name]?.text = dateStr;
            //               // FIX: only trigger the minor/parent-guardian logic for
            //               // fields that actually represent a Date of Birth. Before,
            //               // ANY date-type field (e.g. "Issue Date", "Preferred
            //               // Appointment Date") would incorrectly run the age check
            //               // and could show/hide the parent-guardian fields for the
            //               // wrong reason.
            //               if (_isDobFieldName(name)) {
            //                 _checkAgeAndShowParentFields(dateStr);
            //               }
            //               setState(() {});
            //             }
            //           },
            //           validator: required
            //               ? (v) => v == null || v.isEmpty ? 'Required' : null
            //               : null,
            //         );

            //       case 'textarea':
            //         if (!_controllers.containsKey(name))
            //           _controllers[name] = TextEditingController();
            //         return TextFormField(
            //           controller: _controllers[name],
            //           maxLines: 4,
            //           decoration: inputDecoration,
            //           validator: required
            //               ? (v) => v == null || v.isEmpty ? 'Required' : null
            //               : null,
            //           onChanged: (value) => setState(() {}),
            //         );

            //       case 'select':
            //         String cv = _selectedOptions[name] ?? '';
            //         return DropdownButtonFormField<String>(
            //           value: (cv.isEmpty || !options.contains(cv)) ? null : cv,
            //           decoration: inputDecoration,
            //           isExpanded: true,
            //           items: options
            //               .map((o) => DropdownMenuItem(
            //                   value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
            //               .toList(),
            //           onChanged: (v) {
            //             setState(() {
            //               _selectedOptions[name] = v ?? '';
            //               // NEW: whenever a parent dropdown's value changes, wipe
            //               // out any answers previously entered into fields that
            //               // conditionally depend on it. Otherwise a hidden field's
            //               // stale value could still get submitted, and re-showing
            //               // it later would show old data instead of a fresh field.
            //               if (fieldId != null) {
            //                 _clearFieldsDependingOn(fieldId);
            //               }
            //               _formKey.currentState?.validate();
            //             });
            //           },
            //           validator: required
            //               ? (v) => v == null || v.isEmpty ? 'Please select' : null
            //               : null,
            //         );

            //       case 'multiselect':
            //         return _buildMultiSelectField(name, label, required, options, fieldId);

            //       default:
            //         return const SizedBox();
            //     }
            //   }

            //   // NEW: multi-select field, shown as toggleable chips. Selected values
            //   // are stored as a single comma-separated string in _selectedOptions,
            //   // exactly like a single-select field, so the submit payload and the
            //   // conditional-visibility logic both keep working unchanged.
            //   Widget _buildMultiSelectField(String name, String label, bool required,
            //       List<String> options, dynamic fieldId) {
            //     return FormField<String>(
            //       initialValue: _selectedOptions[name] ?? '',
            //       validator: required
            //           ? (v) => (v == null || v.trim().isEmpty)
            //               ? 'Please select at least one option'
            //               : null
            //           : null,
            //       builder: (formFieldState) {
            //         final selected = (_selectedOptions[name] ?? '')
            //             .split(',')
            //             .map((s) => s.trim())
            //             .where((s) => s.isNotEmpty)
            //             .toSet();

            //         return InputDecorator(
            //           decoration: InputDecoration(
            //             labelText: '$label${required ? " *" : ""}',
            //             border: OutlineInputBorder(
            //               borderRadius: BorderRadius.circular(12),
            //               borderSide: BorderSide(color: Colors.grey[300]!),
            //             ),
            //             enabledBorder: OutlineInputBorder(
            //               borderRadius: BorderRadius.circular(12),
            //               borderSide: BorderSide(
            //                   color: formFieldState.hasError
            //                       ? Colors.red
            //                       : Colors.grey[300]!),
            //             ),
            //             filled: true,
            //             fillColor: Colors.grey[50],
            //             contentPadding:
            //                 const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            //             errorText: formFieldState.errorText,
            //           ),
            //           child: Wrap(
            //             spacing: 8,
            //             runSpacing: 8,
            //             children: options.map((opt) {
            //               final isSelected = selected.contains(opt);
            //               return FilterChip(
            //                 label: Text(opt, style: const TextStyle(fontSize: 12)),
            //                 selected: isSelected,
            //                 onSelected: (val) {
            //                   setState(() {
            //                     final set = (_selectedOptions[name] ?? '')
            //                         .split(',')
            //                         .map((s) => s.trim())
            //                         .where((s) => s.isNotEmpty)
            //                         .toSet();
            //                     if (val) {
            //                       set.add(opt);
            //                     } else {
            //                       set.remove(opt);
            //                     }
            //                     _selectedOptions[name] = set.join(',');
            //                     formFieldState.didChange(_selectedOptions[name]);
            //                     // Same reasoning as the single-select onChanged:
            //                     // clear anything conditionally depending on this
            //                     // field so stale answers don't linger.
            //                     if (fieldId != null) {
            //                       _clearFieldsDependingOn(fieldId);
            //                     }
            //                     _formKey.currentState?.validate();
            //                   });
            //                 },
            //                 selectedColor: primary.withAlpha(40),
            //                 checkmarkColor: primary,
            //                 backgroundColor: Colors.white,
            //                 side: BorderSide(
            //                     color: isSelected ? primary : Colors.grey[300]!),
            //               );
            //             }).toList(),
            //           ),
            //         );
            //       },
            //     );
            //   }

            //   // ==================== UTILITY HELPERS ====================

            //   Color _parseColor(dynamic c) {
            //     if (c == null) return primary;
            //     if (c is int) return Color(c);
            //     if (c is String) {
            //       String s = c.trim();
            //       if ((s.startsWith('0x') || s.startsWith('0X')) && s.length >= 8) {
            //         int? val = int.tryParse(s);
            //         if (val != null) return Color(val);
            //       }
            //       if (s.startsWith('#')) {
            //         s = '0xFF${s.substring(1)}';
            //         int? val = int.tryParse(s);
            //         if (val != null) return Color(val);
            //       }
            //       int? val = int.tryParse(s);
            //       if (val != null) return Color(val);
            //     }
            //     return primary;
            //   }

            //   IconData _parseIcon(dynamic i) {
            //     if (i == null) return Icons.assured_workload;
            //     if (i is IconData) return i;
            //     String iconStr = (i ?? '').toString().trim();
            //     switch (iconStr) {
            //       case 'account_balance':
            //         return Icons.account_balance;
            //       case 'payments':
            //         return Icons.payments;
            //       case 'phone_android':
            //         return Icons.phone_android;
            //       case 'flight_takeoff':
            //         return Icons.flight_takeoff;
            //       case 'health_and_safety':
            //         return Icons.health_and_safety;
            //       case 'credit_card':
            //         return Icons.credit_card;
            //       case 'receipt_long':
            //         return Icons.receipt_long;
            //       case 'description':
            //         return Icons.description;
            //       case 'fingerprint':
            //         return Icons.fingerprint;
            //       case 'account_balance_wallet':
            //         return Icons.account_balance_wallet;
            //       case 'point_of_sale':
            //         return Icons.point_of_sale;
            //       case 'receipt':
            //         return Icons.receipt;
            //       default:
            //         return Icons.assured_workload;
            //     }
            //   }

            //   String _formatFileSize(int? bytes) {
            //     if (bytes == null) return '';
            //     if (bytes < 1024) return '$bytes B';
            //     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
            //     return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
            //   }

            //   IconData _getFileIcon(String? name) {
            //     if (name == null) return Icons.insert_drive_file;
            //     final ext = name.split('.').last.toLowerCase();
            //     if (ext == 'pdf') return Icons.picture_as_pdf;
            //     if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image;
            //     if (['doc', 'docx'].contains(ext)) return Icons.description;
            //     return Icons.insert_drive_file;
            //   }

            //   Color _getFileColor(String? name) {
            //     if (name == null) return Colors.grey;
            //     final ext = name.split('.').last.toLowerCase();
            //     if (ext == 'pdf') return Colors.red;
            //     if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Colors.green;
            //     if (['doc', 'docx'].contains(ext)) return Colors.blue;
            //     return Colors.grey;
            //   }

            //   String _getDocTypeLabel(String type) {
            //     switch (type) {
            //       case 'aadhaar':
            //         return 'Aadhaar Card';
            //       case 'pan':
            //         return 'PAN Card';
            //       case 'photo':
            //         return 'Passport Photo';
            //       case 'signature':
            //         return 'Signature';
            //       case 'bank':
            //         return 'Bank Proof';
            //       case 'address':
            //         return 'Address Proof';
            //       default:
            //         return type;
            //     }
            //   }

            //   IconData _getDocTypeIcon(String type) {
            //     switch (type) {
            //       case 'aadhaar':
            //         return Icons.fingerprint;
            //       case 'pan':
            //         return Icons.credit_card;
            //       case 'photo':
            //         return Icons.photo;
            //       case 'signature':
            //         return Icons.draw;
            //       case 'bank':
            //         return Icons.account_balance;
            //       case 'address':
            //         return Icons.home;
            //       default:
            //         return Icons.description;
            //     }
            //   }

            //   Widget _sectionTitle(String title) {
            //     return Padding(
            //       padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            //       child: Row(
            //         children: [
            //           Container(
            //             width: 4,
            //             height: 20,
            //             decoration: BoxDecoration(
            //               gradient: LinearGradient(
            //                 colors: [primary, primaryDark],
            //                 begin: Alignment.topLeft,
            //                 end: Alignment.bottomRight,
            //               ),
            //               borderRadius: BorderRadius.circular(2),
            //             ),
            //           ),
            //           const SizedBox(width: 10),
            //           Expanded(
            //             child: Text(
            //               title,
            //               style: const TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: textPrimaryColor,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     );
            //   }

            //   Widget _buildSuccessScreen(String name) {
            //     return Center(
            //       child: SingleChildScrollView(
            //         padding: const EdgeInsets.all(32),
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             Container(
            //               width: 120,
            //               height: 120,
            //               decoration: BoxDecoration(
            //                 gradient: LinearGradient(
            //                   colors: [success.withAlpha(25), success.withAlpha(15)],
            //                   begin: Alignment.topLeft,
            //                   end: Alignment.bottomRight,
            //                 ),
            //                 shape: BoxShape.circle,
            //               ),
            //               child: const Icon(
            //                 Icons.check_circle,
            //                 color: success,
            //                 size: 80,
            //               ),
            //             ),
            //             const SizedBox(height: 24),
            //             const Text(
            //               '🎉 Application Submitted!',
            //               style: TextStyle(
            //                 fontSize: 26,
            //                 fontWeight: FontWeight.bold,
            //                 color: textPrimaryColor,
            //               ),
            //             ),
            //             const SizedBox(height: 8),
            //             Text(
            //               'Your $name application has been submitted successfully.',
            //               textAlign: TextAlign.center,
            //               style: TextStyle(
            //                 color: textSecondaryColor,
            //                 fontSize: 14,
            //                 height: 1.5,
            //               ),
            //             ),
            //             if (_trackingId != null) ...[
            //               const SizedBox(height: 24),
            //               Container(
            //                 padding: const EdgeInsets.all(24),
            //                 decoration: BoxDecoration(
            //                   color: cardBg,
            //                   borderRadius: BorderRadius.circular(20),
            //                   boxShadow: [
            //                     BoxShadow(
            //                       color: Colors.grey.withAlpha(15),
            //                       blurRadius: 20,
            //                       offset: const Offset(0, 8),
            //                     ),
            //                   ],
            //                 ),
            //                 child: Column(
            //                   children: [
            //                     Container(
            //                       padding: const EdgeInsets.all(12),
            //                       decoration: BoxDecoration(
            //                         gradient: LinearGradient(
            //                           colors: [primary, primaryDark],
            //                           begin: Alignment.topLeft,
            //                           end: Alignment.bottomRight,
            //                         ),
            //                         borderRadius: BorderRadius.circular(14),
            //                       ),
            //                       child: const Icon(
            //                         Icons.qr_code,
            //                         color: Colors.white,
            //                         size: 32,
            //                       ),
            //                     ),
            //                     const SizedBox(height: 12),
            //                     Text(
            //                       'Tracking ID',
            //                       style: TextStyle(
            //                         color: textSecondaryColor,
            //                         fontSize: 12,
            //                       ),
            //                     ),
            //                     const SizedBox(height: 6),
            //                     Text(
            //                       _trackingId!,
            //                       style: const TextStyle(
            //                         fontSize: 24,
            //                         fontWeight: FontWeight.bold,
            //                         color: textPrimaryColor,
            //                         letterSpacing: 3,
            //                       ),
            //                     ),
            //                     const SizedBox(height: 8),
            //                     Container(
            //                       padding: const EdgeInsets.symmetric(
            //                         horizontal: 12,
            //                         vertical: 4,
            //                       ),
            //                       decoration: BoxDecoration(
            //                         color: success.withAlpha(15),
            //                         borderRadius: BorderRadius.circular(12),
            //                       ),
            //                       child: Row(
            //                         mainAxisSize: MainAxisSize.min,
            //                         children: [
            //                           Icon(Icons.check_circle, size: 14, color: success),
            //                           const SizedBox(width: 4),
            //                           Text(
            //                             'Application Received',
            //                             style: TextStyle(
            //                               fontSize: 10,
            //                               color: success,
            //                               fontWeight: FontWeight.w600,
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //             const SizedBox(height: 24),
            //             SizedBox(
            //               width: double.infinity,
            //               height: 50,
            //               child: ElevatedButton.icon(
            //                 onPressed: () => Navigator.pop(context),
            //                 icon: const Icon(Icons.home, size: 20),
            //                 label: const Text(
            //                   'Back to Home',
            //                   style: TextStyle(
            //                     fontWeight: FontWeight.bold,
            //                     fontSize: 16,
            //                   ),
            //                 ),
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: primary,
            //                   foregroundColor: Colors.white,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(14),
            //                   ),
            //                   elevation: 0,
            //                 ),
            //               ),
            //             ),
            //             const SizedBox(height: 12),
            //             TextButton(
            //               onPressed: () => setState(() {
            //                 _submitted = false;
            //                 _trackingId = null;
            //               }),
            //               child: Text(
            //                 'Submit Another Application',
            //                 style: TextStyle(
            //                   color: primary,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     );
            //   }
            // }

            // // ==================== LOGIN POPUP ====================

            // class _LoginPopup extends StatefulWidget {
            //   final VoidCallback onLoginSuccess;
            //   const _LoginPopup({required this.onLoginSuccess});

            //   @override
            //   State<_LoginPopup> createState() => _LoginPopupState();
            // }

            // class _LoginPopupState extends State<_LoginPopup> {
            //   final _loginIdCtrl = TextEditingController();
            //   final _passCtrl = TextEditingController();
            //   bool _loading = false;
            //   String? _error;

            //   static const Color primary = Color(0xFF6C63FF);
            //   static const Color primaryDark = Color(0xFF4A42CC);
            //   static const Color textPrimaryColor = Color(0xFF1A1A2E);
            //   static const Color textSecondaryColor = Color(0xFF6B7280);

            //   @override
            //   void dispose() {
            //     _loginIdCtrl.dispose();
            //     _passCtrl.dispose();
            //     super.dispose();
            //   }

            //   void _login() async {
            //     if (_loginIdCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
            //     setState(() {
            //       _loading = true;
            //       _error = null;
            //     });
            //     final auth = Provider.of<AuthProvider>(context, listen: false);
            //     final r = await auth.login(_loginIdCtrl.text.trim(), _passCtrl.text.trim());
            //     setState(() => _loading = false);
            //     if (r['success'] == true) {
            //       widget.onLoginSuccess();
            //     } else {
            //       setState(() => _error = r['message'] as String?);
            //     }
            //   }

            //   @override
            //   Widget build(BuildContext context) {
            //     return Container(
            //       constraints: BoxConstraints(
            //         maxHeight: MediaQuery.of(context).size.height * 0.55,
            //       ),
            //       decoration: const BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            //       ),
            //       child: SingleChildScrollView(
            //         padding: const EdgeInsets.all(24),
            //         child: Column(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             Container(
            //               margin: const EdgeInsets.only(bottom: 16),
            //               width: 40,
            //               height: 4,
            //               decoration: BoxDecoration(
            //                 color: Colors.grey[300],
            //                 borderRadius: BorderRadius.circular(2),
            //               ),
            //             ),
            //             Container(
            //               padding: const EdgeInsets.all(12),
            //               decoration: BoxDecoration(
            //                 gradient: LinearGradient(
            //                   colors: [primary, primaryDark],
            //                   begin: Alignment.topLeft,
            //                   end: Alignment.bottomRight,
            //                 ),
            //                 borderRadius: BorderRadius.circular(16),
            //               ),
            //               child: const Icon(
            //                 Icons.lock_outline,
            //                 color: Colors.white,
            //                 size: 28,
            //               ),
            //             ),
            //             const SizedBox(height: 12),
            //             const Text(
            //               'Login to Apply',
            //               style: TextStyle(
            //                 fontSize: 20,
            //                 fontWeight: FontWeight.bold,
            //                 color: textPrimaryColor,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               'Sign in to submit your application',
            //               style: TextStyle(
            //                 fontSize: 13,
            //                 color: textSecondaryColor,
            //               ),
            //             ),
            //             const SizedBox(height: 16),
            //             if (_error != null)
            //               Container(
            //                 padding: const EdgeInsets.all(12),
            //                 margin: const EdgeInsets.only(bottom: 12),
            //                 decoration: BoxDecoration(
            //                   color: Colors.red.withAlpha(25),
            //                   borderRadius: BorderRadius.circular(12),
            //                 ),
            //                 child: Row(
            //                   children: [
            //                     const Icon(Icons.error_outline, color: Colors.red, size: 18),
            //                     const SizedBox(width: 8),
            //                     Expanded(
            //                       child: Text(
            //                         _error!,
            //                         style: const TextStyle(
            //                           color: Colors.red,
            //                           fontSize: 12,
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             TextField(
            //               controller: _loginIdCtrl,
            //               decoration: InputDecoration(
            //                 labelText: 'Email or Mobile',
            //                 prefixIcon: Icon(Icons.person_outline, color: primary),
            //                 border: OutlineInputBorder(
            //                   borderRadius: BorderRadius.circular(12),
            //                   borderSide: BorderSide(color: Colors.grey[300]!),
            //                 ),
            //                 focusedBorder: OutlineInputBorder(
            //                   borderRadius: BorderRadius.circular(12),
            //                   borderSide: BorderSide(color: primary, width: 2),
            //                 ),
            //                 filled: true,
            //                 fillColor: Colors.grey[50],
            //               ),
            //             ),
            //             const SizedBox(height: 12),
            //             TextField(
            //               controller: _passCtrl,
            //               obscureText: true,
            //               decoration: InputDecoration(
            //                 labelText: 'Password',
            //                 prefixIcon: Icon(Icons.lock_outline, color: primary),
            //                 border: OutlineInputBorder(
            //                   borderRadius: BorderRadius.circular(12),
            //                   borderSide: BorderSide(color: Colors.grey[300]!),
            //                 ),
            //                 focusedBorder: OutlineInputBorder(
            //                   borderRadius: BorderRadius.circular(12),
            //                   borderSide: BorderSide(color: primary, width: 2),
            //                 ),
            //                 filled: true,
            //                 fillColor: Colors.grey[50],
            //               ),
            //             ),
            //             const SizedBox(height: 16),
            //             SizedBox(
            //               width: double.infinity,
            //               height: 50,
            //               child: ElevatedButton(
            //                 onPressed: _loading ? null : _login,
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: primary,
            //                   foregroundColor: Colors.white,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   elevation: 0,
            //                 ),
            //                 child: _loading
            //                     ? const SizedBox(
            //                         width: 24,
            //                         height: 24,
            //                         child: CircularProgressIndicator(
            //                           color: Colors.white,
            //                           strokeWidth: 2.5,
            //                         ),
            //                       )
            //                     : const Text(
            //                         'Login',
            //                         style: TextStyle(
            //                           fontWeight: FontWeight.bold,
            //                           fontSize: 16,
            //                         ),
            //                       ),
            //               ),
            //             ),
            //             const SizedBox(height: 12),
            //           ],
            //         ),
            //       ),
            //     );
            //   }
            // }