import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

/// Redesigned Responsive Career Screen matching reference design aesthetic.
/// Features top rounded header with search bar, "Featured for you" cards,
/// "Expert advice" guidance banners, category filter tags, job listings, and application form.
class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen>
    with SingleTickerProviderStateMixin {
  // Money Transfer Reference Teal & Orange Theme Palette
  static const Color primaryPurple = Color(0xFF00A896);
  static const Color primaryDark = Color(0xFF028090);
  static const Color accentIndigo = Color(0xFFFF6B00);
  static const Color bgGradientStart = Color(0xFFE0F2F1);
  static const Color bgGradientEnd = Color(0xFFF4FBF7);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  final ApiService _api = ApiService();

  // Data & Search States
  List<dynamic> _jobs = [];
  bool _loadingJobs = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '#All Openings#';

  // Form Controllers & State
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  Uint8List? _fileBytes;
  String? _resumeFileName;
  int? _resumeFileSize;
  String? _selectedJobId;
  bool _submitting = false;
  bool _submitted = false;
  final _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _categories = [
    '#All Openings#',
    '#Engineering#',
    '#Design#',
    '#Marketing#',
    '#Operations#',
  ];

  // Static expert advice banners
  final List<Map<String, dynamic>> _expertAdviceList = [
    {
      'title': 'Habits that should be developed for tech excellence',
      'tag': '#Growth',
      'color': const Color(0xFF4F46E5),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'title': 'How to ace your DreamZone technical interview',
      'tag': '#Interview Tips',
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.quiz_rounded,
    },
    {
      'title': 'Building scalable flutter apps & backend solutions',
      'tag': '#Tech Guide',
      'color': const Color(0xFF06B6D4),
      'icon': Icons.code_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _orgCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _msgCtrl.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final data = await _api.getCareerJobs();
      if (data['success'] == true && mounted) {
        setState(() {
          _jobs = data['jobs'] ?? [];
          _loadingJobs = false;
        });
      } else {
        if (mounted) setState(() => _loadingJobs = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileBytes = file.bytes;
          _resumeFileName = file.name;
          _resumeFileSize = file.size;
        });
        if (mounted) {
          _showSnackBar('Resume selected: ${file.name}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error picking file: $e', isError: true);
      }
    }
  }

  void _removeResume() {
    setState(() {
      _fileBytes = null;
      _resumeFileName = null;
      _resumeFileSize = null;
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _scrollToForm() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJobId == null) {
      _showSnackBar('Please select a position first', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      var uri = Uri.parse('${ApiService.baseUrl}/career/apply');
      var request = http.MultipartRequest('POST', uri);

      request.fields['job_id'] = _selectedJobId!;
      request.fields['first_name'] = _firstNameCtrl.text.trim();
      request.fields['last_name'] = _lastNameCtrl.text.trim();
      request.fields['organization'] = _orgCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['mobile'] = _mobileCtrl.text.trim();
      request.fields['message'] = _msgCtrl.text.trim();

      if (_fileBytes != null && _resumeFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'resume',
            _fileBytes!,
            filename: _resumeFileName!,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final result = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
        _showSnackBar(
          result['message'] ?? 'Application submitted successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnackBar(
          'Failed to submit application. Check connection.',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? dangerRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<dynamic> get _filteredJobs {
    return _jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final skills = (job['skills'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          skills.contains(_searchQuery.toLowerCase());

      bool matchesCategory = true;
      if (_selectedCategory == '#Engineering#') {
        matchesCategory = title.contains('developer') ||
            title.contains('engineer') ||
            title.contains('tech') ||
            title.contains('flutter') ||
            title.contains('full stack') ||
            skills.contains('python') ||
            skills.contains('flutter');
      } else if (_selectedCategory == '#Design#') {
        matchesCategory = title.contains('design') ||
            title.contains('ui') ||
            title.contains('ux') ||
            skills.contains('figma');
      } else if (_selectedCategory == '#Marketing#') {
        matchesCategory = title.contains('marketing') ||
            title.contains('sales') ||
            title.contains('seo');
      } else if (_selectedCategory == '#Operations#') {
        matchesCategory = title.contains('manager') ||
            title.contains('operation') ||
            title.contains('hr');
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Responsive Curved Header with Search Bar (Matching Reference UI)
                        _buildTopHeader(),

                        // Main Scrollable Body
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. "Featured for you" Section (Matching Reference UI)
                                _buildFeaturedSection(),

                                const SizedBox(height: 20),

                                // 2. "Expert advice" Section (Matching Reference UI)
                                _buildExpertAdviceSection(),

                                const SizedBox(height: 20),

                                // 3. "Career Categories & Tags" Section (Matching Reference UI)
                                _buildCategoriesSection(),

                                const SizedBox(height: 16),

                                // 4. Job Openings List
                                _buildJobsList(),

                                const SizedBox(height: 24),

                                // 5. Application Form Card
                                _buildApplicationFormCard(),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Curved Header Banner with Search Field (Exact Layout from Reference Image)
  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x335B46E5),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile avatar preview (matching top left in reference image)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(45),
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Portal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Explore top opportunities',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Pill shaped Search Bar ("Q Search" matching reference image)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search career openings...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Featured for you" Section with Horizontal Scroll Cards (Reference Image Section 1)
  Widget _buildFeaturedSection() {
    final featuredItems = _jobs.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured for you',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              InkWell(
                onTap: () =>
                    setState(() => _selectedCategory = '#All Openings#'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryPurple.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'More',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingJobs)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          )
        else if (featuredItems.isEmpty)
          _buildFeaturedPlaceholder()
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: featuredItems.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final job = featuredItems[index];
                final title = job['title'] ?? 'Open Role';
                final exp = job['experience'] ?? 'Entry Level';
                final colors = [
                  const Color(0xFFF59E0B), // Warm Gold
                  const Color(0xFF06B6D4), // Sky Blue
                  const Color(0xFFEC4899), // Rose Pink
                  const Color(0xFF8B5CF6), // Soft Violet
                ];
                final cardColor = colors[index % colors.length];

                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1B4B).withAlpha(10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          index % 2 == 0
                              ? Icons.code_rounded
                              : Icons.work_outline_rounded,
                          color: cardColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              exp,
                              style: const TextStyle(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
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

  Widget _buildFeaturedPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.stars_rounded, color: primaryPurple, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'High Impact Tech & Design Positions Available',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Expert advice" Guidance Banners (Reference Image Section 2)
  Widget _buildExpertAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Expert advice',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _expertAdviceList.length,
            separatorBuilder: (_, i) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = _expertAdviceList[index];
              return Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item['color'] as Color,
                      (item['color'] as Color).withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withAlpha(70),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['tag'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

  /// "Career Categories / Tags" Section (Reference Image Section 3)
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Explore categories',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;

              return InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryPurple.withAlpha(25) : cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryPurple : borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? primaryPurple : textMuted,
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

  /// Filtered Jobs List Rendering (Matching Reference UI List Format)
  Widget _buildJobsList() {
    final jobs = _filteredJobs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open Positions (${jobs.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              if (_searchQuery.isNotEmpty ||
                  _selectedCategory != '#All Openings#')
                TextButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = '#All Openings#';
                    });
                  },
                  child: const Text(
                    'Reset filters',
                    style: TextStyle(color: primaryPurple),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingJobs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: primaryPurple),
              ),
            )
          else if (jobs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 44, color: textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No open positions match your filter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try resetting your search or category filter.',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobs.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(job);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Open Role';
    final experience = job['experience'] ?? '1 - 3 Years';
    final qualification = job['qualification'] ?? 'Degree';
    final skills = (job['skills'] ?? '').toString();
    final isSelected = _selectedJobId == job['id'].toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? primaryPurple : borderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: primaryPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_center_rounded,
                          size: 14,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          experience,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.school_rounded,
                          size: 14,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            qualification,
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.split(',').take(4).map((s) {
                final skill = s.trim();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgGradientStart,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryPurple,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSelected)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: successGreen,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Position Selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: successGreen,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedJobId = job['id'].toString());
                  _scrollToForm();
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(isSelected ? 'Selected' : 'Apply Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Application Form Card with Modern Input Design
  Widget _buildApplicationFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1B4B).withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_ind_rounded,
                    color: primaryPurple,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in your details to apply for open positions',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 20),

              // Position Dropdown Field
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedJobId,
                hint: const Text(
                  'Select Position *',
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
                decoration: _inputDecoration(
                  'Position *',
                  Icons.work_outline_rounded,
                ),
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                dropdownColor: cardWhite,
                items: _jobs.map<DropdownMenuItem<String>>((job) {
                  return DropdownMenuItem<String>(
                    value: job['id'].toString(),
                    child: Text(
                      '${job['title']} (${job['experience'] ?? ''})',
                      style: const TextStyle(color: textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedJobId = v),
                validator: (v) => v == null ? 'Please select a position' : null,
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFormTextField(
                      'First Name *',
                      _firstNameCtrl,
                      Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormTextField(
                      'Last Name *',
                      _lastNameCtrl,
                      Icons.person_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildFormTextField(
                'Organization',
                _orgCtrl,
                Icons.business_rounded,
              ),
              const SizedBox(height: 14),
              _buildFormTextField(
                'Email Address *',
                _emailCtrl,
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildFormTextField(
                'Mobile Number *',
                _mobileCtrl,
                Icons.phone_outlined,
                type: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 14),

              // Resume Picker Box
              InkWell(
                onTap: _pickResume,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _resumeFileName != null
                          ? successGreen
                          : borderColor,
                      width: _resumeFileName != null ? 1.8 : 1.2,
                    ),
                  ),
                  child: _resumeFileName != null
                      ? Row(
                          children: [
                            const Icon(
                              Icons.file_present_rounded,
                              color: successGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _resumeFileName!,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatFileSize(_resumeFileSize),
                                    style: const TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: dangerRed,
                                size: 20,
                              ),
                              onPressed: _removeResume,
                            ),
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              color: primaryPurple,
                              size: 26,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Upload Resume (PDF, DOC, JPG)',
                                style:
                                    TextStyle(color: textMuted, fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),
              _buildFormTextField(
                'Message (Optional)',
                _msgCtrl,
                Icons.message_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _submitting ? null : _submitApplication,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPurple, primaryDark, accentIndigo],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildFormTextField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      decoration: _inputDecoration(label, icon),
      validator: (v) => (label.contains('*') && (v == null || v.trim().isEmpty))
          ? 'Required field'
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryPurple, size: 20),
      filled: true,
      fillColor: inputFill,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPurple, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: dangerRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: dangerRed, width: 2.0),
      ),
    );
  }

  /// Success View Dialog Screen
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withAlpha(15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: successGreen.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: successGreen,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Submitted!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thank you for applying. Our HR team will review your application and contact you soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(isGuest: true),
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
