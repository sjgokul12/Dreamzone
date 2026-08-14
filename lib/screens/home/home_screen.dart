import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../profile/profile_screen.dart';
import '../profile/my_applications_screen.dart';
import '../profile/help_support_screen.dart';
import '../services/service_detail_screen.dart';
import '../services/Home Product/Aadhaar/aadhaar_service_screen.dart';
import '../services/Home Product/Pan/pan_service_screen.dart';
import '../services/Home Product/Gst/gst_service_screen.dart';
import '../services/Home Product/Voter Id/voter_id_service_screen.dart';
import '../services/Home Product/Fastag/fastag_purchase_screen.dart';
import '../services/Home Product/Dsc/dsc_service_screen.dart';
import '../services/Home Product/Msme/msme_service_screen.dart';
import '../services/Home Product/Fssai/fssai_service_screen.dart';
import '../services/Home Product/Passport/passport_service_screen.dart';
import '../services/all_services_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../career/career_screen.dart';
import '../services/BBPS Services/Landline/Landline.dart';
import '../services/BBPS Services/DTH/DTH.dart';
import '../services/BBPS Services/Electricity/Electricity.dart';
import '../services/BBPS Services/Piped Gas Bill/Piped Gas Bill.dart';
import '../services/BBPS Services/Gas Cylinder/Gas Cylinder.dart';
import '../services/BBPS Services/Recharge/recharge_screen.dart';
import '../services/BBPS Services/Water/Water.dart';
import '../services/BBPS Services/Education/Education.dart';
import '../services/BBPS Services/Loan Payment/Loan Payment.dart';
import '../services/BBPS Services/Housing Society/Housing Society.dart';
import '../services/BBPS Services/Fastag/Fastag.dart';
import '../services/BBPS Services/Metro Card/Metro Card.dart';
import '../services/BBPS Services/Broadband/Broadband.dart';
import '../services/BBPS Services/Insurance/Insurance.dart';
import '../services/Payment Services/Money Transfer/Money Transfer.dart';
import '../services/Travels/bus_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allServices = [];
  int _notificationCount = 0;
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _mainAnimationController;
  late AnimationController _pulseController;
  late AnimationController _marqueeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final PageController _reviewController = PageController(
    viewportFraction: 0.88,
  );
  int _currentReview = 0;

  // Dark Glassmorphism Theme Palette
  static const Color kBgTop = Color(0xFF0F0826);
  static const Color kBgBottom = Color(0xFF1A0F3D);
  static const Color kCardColor = Color(0xFF241247);
  static const Color kFieldColor = Color(0xFF2E1B57);
  static const Color kAccentPink = Color(0xFFEC4899);
  static const Color kAccentPurple = Color(0xFF7C3AED);
  static const Color kMutedText = Color(0xFFB3A8CC);
  
  static const Color primaryOrange = Color(0xFFEC4899); // Re-mapped to Pink
  static const Color deepOrange = Color(0xFF7C3AED);
  static const Color headerNavy = Color(0xFF1A0F3D);
  static const Color headerNavyLight = Color(0xFF241247);
  static const Color bgCream = Colors.white; // Full white background
  static const Color cardWhite = Color(0xFF241247);
  static const Color textDark = Colors.white;
  static const Color textLight = Color(0xFFB3A8CC);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color softOrange = Color(0xFF2E1B57);

  List<Map<String, dynamic>> get _homeServices {
    final defaultOrder = [
      {
        'id': 'aadhaar',
        'name': 'Aadhaar',
        'category': 'E-Government',
        'icon': 'fingerprint',
        'color': '#D97706',
      },
      {
        'id': 'pan',
        'name': 'PAN',
        'category': 'E-Government',
        'icon': 'description',
        'color': '#2563EB',
      },
      {
        'id': 'gst',
        'name': 'GST',
        'category': 'E-Government',
        'icon': 'receipt_long',
        'color': '#059669',
      },
      {
        'id': 'voter',
        'name': 'Voter ID',
        'category': 'E-Government',
        'icon': 'how_to_vote',
        'color': '#7C3AED',
      },
      {
        'id': 'fastag_purchase',
        'name': 'Fastag',
        'category': 'Home Product',
        'asset_image': 'assets/Fastag Purchase.png',
        'icon': 'directions_car',
        'color': '#00A896',
      },
      {
        'id': 'landline_bbps',
        'name': 'Landline',
        'category': 'BBPS Services',
        'asset_image': 'assets/Landline.jpg',
        'icon': 'phone_in_talk',
        'color': '#2563EB',
      },
    ];

    final result = <Map<String, dynamic>>[];
    for (final item in defaultOrder) {
      final nameKey = item['name'].toString().toLowerCase().split(' ').first;
      final match = _allServices.firstWhere(
        (s) => (s['name'] ?? '').toString().toLowerCase().contains(nameKey),
        orElse: () => item,
      );
      result.add(match);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.services.isNotEmpty) {
      _allServices = List<Map<String, dynamic>>.from(auth.services);
    } else {
      _allServices = [
        {
          'id': 'pan',
          'name': 'PAN',
          'category': 'E-Government',
          'icon': 'description',
          'color': '#2563EB',
        },
        {
          'id': 'gst',
          'name': 'GST Registration',
          'category': 'E-Government',
          'icon': 'receipt_long',
          'color': '#059669',
        },
        {
          'id': 'voter',
          'name': 'Voter ID',
          'category': 'E-Government',
          'icon': 'how_to_vote',
          'color': '#7C3AED',
        },
        {
          'id': 'aadhaar',
          'name': 'Aadhaar Card',
          'category': 'E-Government',
          'icon': 'fingerprint',
          'color': '#D97706',
        },
        {
          'id': 'fastag_purchase',
          'name': 'Fastag Purchase',
          'category': 'Home Product',
          'asset_image': 'assets/Fastag Purchase.png',
          'icon': 'directions_car',
          'color': '#00A896',
        },
        {
          'id': 'landline_bbps',
          'name': 'Landline',
          'category': 'BBPS Services',
          'asset_image': 'assets/Landline.jpg',
          'icon': 'phone_in_talk',
          'color': '#2563EB',
        },
        {
          'id': 'payments',
          'name': 'Money Transfer',
          'category': 'Payment Services',
          'icon': 'payments',
          'color': '#16A34A',
        },
        {
          'id': 'recharge',
          'name': 'Mobile Recharge',
          'category': 'BBPS Services',
          'icon': 'phone_android',
          'color': '#059669',
        },
      ];
    }

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _marqueeController = AnimationController(
      duration: const Duration(milliseconds: 15000), // Medium speed slider
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _mainAnimationController.forward();
    _startReviewAutoScroll();
    _loadData();
  }

  void _startReviewAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _reviewController.hasClients) {
        _currentReview = (_currentReview + 1) % 6;
        _reviewController.animateToPage(
          _currentReview,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
        _startReviewAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseController.dispose();
    _marqueeController.dispose();
    _reviewController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeCategory(String? cat) {
    if (cat == null) return 'E-Government';
    final s = cat.trim();
    final lower = s.toLowerCase();
    if (lower.contains('banking')) return 'Payment Services';
    if (lower.contains('business')) return 'E-Government';
    if (lower.contains('government') || lower.contains('goverment')) {
      return 'E-Government';
    }
    if (lower.contains('financial')) return ''; // Exclude Financial Services
    if (lower.contains('travel')) return 'Travels';
    return s;
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    _api
        .getAnnouncementCount()
        .then((count) {
          if (mounted) setState(() => _notificationCount = count);
        })
        .catchError((_) {});

    await auth.loadServices();

    if (mounted) {
      setState(() {
        final seen = <String>{};
        _allServices = auth.services
            .map((s) {
              final item = Map<String, dynamic>.from(s);
              item['category'] = _normalizeCategory(
                item['category']?.toString(),
              );
              return item;
            })
            .where((s) {
              if ((s['category'] as String).isEmpty) return false;
              final name = (s['name'] ?? '').toString();
              if (seen.contains(name)) return false;
              seen.add(name);
              return true;
            })
            .toList();

        final hasRecharge = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('recharge'),
        );
        if (!hasRecharge) {
          _allServices.add({
            'id': 'recharge',
            'name': 'Mobile Recharge',
            'category': 'BBPS Services',
            'asset_image': 'assets/Postpaid Mobile Recharges.png',
            'icon': 'phone_android',
            'color': '#059669',
          });
        }

        final hasLandline = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('landline'),
        );
        if (!hasLandline) {
          _allServices.add({
            'id': 'landline_bbps',
            'name': 'Landline',
            'category': 'BBPS Services',
            'icon': 'phone_in_talk',
            'color': '#2563EB',
          });
        }

        final hasDth = _allServices.any(
          (s) => (s['name'] ?? '').toString().toLowerCase().contains('dth'),
        );
        if (!hasDth) {
          _allServices.add({
            'id': 'dth_bbps',
            'name': 'DTH Recharge',
            'category': 'BBPS Services',
            'icon': 'tv',
            'color': '#6D28D9',
          });
        }

        final hasElectricity = _allServices.any(
          (s) => (s['name'] ?? '').toString().toLowerCase().contains(
            'electricity',
          ),
        );
        if (!hasElectricity) {
          _allServices.add({
            'id': 'electricity_bbps',
            'name': 'Electricity Bill',
            'category': 'BBPS Services',
            'asset_image': 'assets/Electricity.png',
            'icon': 'bolt',
            'color': '#0284C7',
          });
        }

        final hasPipedGas = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('piped gas'),
        );
        if (!hasPipedGas) {
          _allServices.add({
            'id': 'piped_gas_bbps',
            'name': 'Piped Gas Bill',
            'category': 'BBPS Services',
            'asset_image': 'assets/Piped Gas Bill.jpg',
            'icon': 'propane_tank',
            'color': '#0EA5E9',
          });
        }

        final hasGasCylinder = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('cylinder'),
        );
        if (!hasGasCylinder) {
          _allServices.add({
            'id': 'gas_cylinder_bbps',
            'name': 'Gas Cylinder',
            'category': 'BBPS Services',
            'asset_image': 'assets/GAS.png',
            'icon': 'propane_tank',
            'color': '#E11D48',
          });
        }

        final hasHousing = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('housing') ||
              (s['name'] ?? '').toString().toLowerCase().contains('society'),
        );
        if (!hasHousing) {
          _allServices.add({
            'id': 'housing_society_bbps',
            'name': 'Housing Society',
            'category': 'BBPS Services',
            'asset_image': 'assets/Housing Society.png',
            'icon': 'home_work',
            'color': '#5A80F6',
          });
        }

        final hasFastagRecharge = _allServices.any(
          (s) =>
              (s['id'] == 'fastag_bbps') ||
              ((s['name'] ?? '').toString().toLowerCase().contains('fastag') &&
                  (s['category'] ?? '').toString().toLowerCase().contains('bbps')),
        );
        if (!hasFastagRecharge) {
          _allServices.add({
            'id': 'fastag_bbps',
            'name': 'FASTag',
            'category': 'BBPS Services',
            'asset_image': 'assets/Fastag.png',
            'icon': 'directions_car',
            'color': '#FF2D6C',
          });
        }

        final hasMetro = _allServices.any(
          (s) => (s['name'] ?? '').toString().toLowerCase().contains('metro'),
        );
        if (!hasMetro) {
          _allServices.add({
            'id': 'metro_card_bbps',
            'name': 'Metro Card Recharge',
            'category': 'BBPS Services',
            'asset_image': 'assets/Metro card Recharge.png',
            'icon': 'subway',
            'color': '#FF7D54',
          });
        }

        final hasBroadband = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('broadband'),
        );
        if (!hasBroadband) {
          _allServices.add({
            'id': 'broadband_bbps',
            'name': 'Broadband Bill',
            'category': 'BBPS Services',
            'asset_image': 'assets/Broadband.png',
            'icon': 'router',
            'color': '#6366F1',
          });
        }

        final hasInsurance = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('insurance'),
        );
        if (!hasInsurance) {
          _allServices.add({
            'id': 'insurance_bbps',
            'name': 'Insurance Premium',
            'category': 'BBPS Services',
            'asset_image': 'assets/Insurance premium.png',
            'icon': 'health_and_safety',
            'color': '#A855F7',
          });
        }

        final hasMoneyTransfer = _allServices.any(
          (s) =>
              (s['name'] ?? '').toString().toLowerCase().contains('money') ||
              (s['name'] ?? '').toString().toLowerCase().contains('transfer'),
        );
        if (!hasMoneyTransfer) {
          _allServices.add({
            'id': 'money_transfer_payment',
            'name': 'Money Transfer',
            'category': 'Payment Services',
            'asset_image': 'assets/Money Transfer.png',
            'icon': 'swap_horiz',
            'color': '#00A896',
          });
        }
      });
    }
  }

  Color _parseColor(dynamic c) {
    if (c == null) return primaryOrange;
    if (c is int) return Color(c);
    if (c is String) {
      String s = c.trim();
      if (s.startsWith('#')) s = '0xFF${s.substring(1)}';
      return Color(int.tryParse(s) ?? 0xFFFF6B00);
    }
    return primaryOrange;
  }

  IconData _parseIcon(dynamic i) {
    if (i == null) return Icons.assured_workload;
    if (i is IconData) return i;
    String iconStr = i.toString().trim();
    switch (iconStr) {
      case 'electricity':
      case 'bolt':
        return Icons.bolt_rounded;
      case 'dth':
      case 'tv':
        return Icons.tv_rounded;
      case 'landline':
      case 'phone_in_talk':
        return Icons.phone_in_talk;
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
        return Icons.assured_workload;
    }
  }

  String _imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return '';
    String path = relativePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiService.baseUrl;
    if (base.endsWith('/api')) {
      final root = base.substring(0, base.length - 4);
      if (path.startsWith('/')) path = path.substring(1);
      return '$root/$path';
    } else {
      if (path.startsWith('/')) path = path.substring(1);
      return '$base/$path';
    }
  }

  // ==================== SERVICE TAP WITH POPUP ====================
  Future<void> _onServiceTap(Map<String, dynamic> service) async {
    final sId = (service['id'] ?? '').toString();
    final name = (service['name'] ?? '').toString().toLowerCase();

    if (sId == 'travel_irtc' || sId == 'travel_flight' || name.contains('irtc') || name.contains('flight booking')) {
      showComingSoonDialog(context);
      return;
    }

    if (sId == 'travel_bus' || name.contains('bus booking') || name.contains('bus ticket')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BusBookingScreen()),
      );
      return;
    }

    final portalUrl = service['url']?.toString();
    if (portalUrl != null && portalUrl.trim().isNotEmpty) {
      final uri = Uri.parse(portalUrl.trim());
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      return;
    }

    final category = (service['category'] ?? '').toString().toLowerCase();

    if (name.contains('landline') || category.contains('landline')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LandlineScreen()),
      );
      return;
    }

    if (name.contains('dth') || category.contains('dth')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DTHScreen()),
      );
      return;
    }

    if (name.contains('electricity') || category.contains('electricity')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ElectricityScreen()),
      );
      return;
    }

    if (name.contains('piped gas') || category.contains('piped gas')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PipedGasBillScreen()),
      );
      return;
    }

    if (name.contains('cylinder') ||
        category.contains('cylinder') ||
        name.contains('lpg')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GasCylinderScreen()),
      );
      return;
    }

    if (name.contains('water') || category.contains('water')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WaterScreen()),
      );
      return;
    }

    if (name.contains('education') ||
        name.contains('school') ||
        category.contains('education')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EducationScreen()),
      );
      return;
    }

    if (name.contains('loan') ||
        name.contains('repayment') ||
        category.contains('loan')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoanPaymentScreen()),
      );
      return;
    }

    if (name.contains('fastag') ||
        name.contains('toll') ||
        category.contains('fastag')) {
      if (name.contains('purchase')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FastagPurchaseScreen(
              service: service,
              isGuest: widget.isGuest,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FastagScreen()),
        );
      }
      return;
    }

    if (name.contains('metro') ||
        name.contains('subway') ||
        category.contains('metro')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MetroCardScreen()),
      );
      return;
    }

    if (name.contains('broadband') ||
        name.contains('fiber') ||
        category.contains('broadband')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BroadbandScreen()),
      );
      return;
    }

    if (name.contains('insurance') ||
        name.contains('policy') ||
        category.contains('insurance')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsuranceScreen()),
      );
      return;
    }

    if (name.contains('money') ||
        name.contains('dmt') ||
        name.contains('transfer') ||
        category.contains('payment')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoneyTransferScreen()),
      );
      return;
    }

    if (name.contains('housing') ||
        name.contains('society') ||
        category.contains('housing')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HousingSocietyScreen()),
      );
      return;
    }

    if ((name.contains('recharge') || category.contains('recharge')) &&
        !name.contains('fastag') &&
        !name.contains('dth') &&
        !name.contains('metro')) {
      final opts = [
        {
          'title': 'Prepaid Mobile Recharge',
          'subtitle': 'Recharge your prepaid mobile number',
          'icon': Icons.phone_android_rounded,
          'icon_bg': const Color(0xFFE0F2FE),
          'icon_color': const Color(0xFF0284C7),
          'section_data': {'id': 901, 'section_name': 'Prepaid', 'is_postpaid': false},
        },
        {
          'title': 'Postpaid Mobile Recharge',
          'subtitle': 'Pay your postpaid mobile bills',
          'icon': Icons.receipt_long_rounded,
          'icon_bg': const Color(0xFFFCE7F3),
          'icon_color': const Color(0xFFDB2777),
          'section_data': {'id': 902, 'section_name': 'Postpaid', 'is_postpaid': true},
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    final rawId = service['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    List<Map<String, dynamic>> sections = [];

    if (intId != null) {
      try {
        final result = await _api
            .getServiceSections(intId)
            .timeout(const Duration(milliseconds: 1500));
        sections =
            (result['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } catch (_) {}
    }

    if (sections.isEmpty) {
      final sName = (service['name'] ?? '').toString().toLowerCase();
      if (sName.contains('voter')) {
        sections = [
          {'id': 101, 'section_name': 'New Voter ID Application'},
          {'id': 102, 'section_name': 'Voter ID Correction / Update'},
          {'id': 103, 'section_name': 'Download E-Voter Card'},
        ];
      } else if (sName.contains('pan')) {
        sections = [
          {'id': 201, 'section_name': 'New PAN Card Application'},
          {'id': 202, 'section_name': 'Correction / Update PAN'},
          {'id': 203, 'section_name': 'Foreign PAN Application'},
        ];
      } else if (sName.contains('gst')) {
        sections = [
          {'id': 301, 'section_name': 'GST Registration'},
        ];
      } else if (sName.contains('aadhaar') || sName.contains('aadhar')) {
        sections = [
          {'id': 401, 'section_name': 'Soft Copy'},
          {'id': 402, 'section_name': 'Hard Copy'},
        ];
      } else if (sName.contains('aeps')) {
        sections = [
          {'id': 501, 'section_name': 'Cash Withdrawal'},
          {'id': 502, 'section_name': 'Balance Enquiry'},
          {'id': 503, 'section_name': 'Mini Statement'},
        ];
      }
    }

    if (!mounted) return;

    if (sections.length > 1) {
      _showSectionPopup(service, sections);
    } else {
      _openDetailScreen(
        service,
        sections.isNotEmpty ? Map<String, dynamic>.from(sections.first) : null,
      );
    }
  }

  void _openDetailScreen(
    Map<String, dynamic> service,
    Map<String, dynamic>? section,
  ) {
    final sName = (service['name'] ?? '').toString().toLowerCase();
    Widget targetScreen;

    if (sName.contains('aadhaar') || sName.contains('aadhar')) {
      targetScreen = AadhaarServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('pan')) {
      targetScreen = PanServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('mobile recharge') || (sName.contains('recharge') && !sName.contains('fastag') && !sName.contains('dth') && !sName.contains('metro'))) {
      targetScreen = RechargeScreen(
        initialIsPostpaid: section?['is_postpaid'] == true,
      );
    } else if (sName.contains('gst')) {
      targetScreen = GstServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('voter')) {
      targetScreen = VoterIdServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('fastag')) {
      targetScreen = FastagPurchaseScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('dsc')) {
      targetScreen = DscServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('msme') || sName.contains('udyam')) {
      targetScreen = MsmeServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('fssai') || sName.contains('food')) {
      targetScreen = FssaiServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else if (sName.contains('passport')) {
      targetScreen = PassportServiceScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    } else {
      targetScreen = ServiceDetailScreen(
        service: service,
        isGuest: widget.isGuest,
        preselectedSectionId: section != null ? section['id'] as int? : null,
        preselectedSectionData: section,
      );
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => targetScreen,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showModernServicePopup(Map<String, dynamic> service, List<Map<String, dynamic>> options) {
    final sName = (service['name'] ?? 'Service').toString();
    final lower = sName.toLowerCase();

    // Default icon
    String logoAsset = 'assets/Explore.png';
    if (lower.contains('aadhaar') || lower.contains('aadhar')) {
      logoAsset = 'assets/Aadhaar.png';
    } else if (lower.contains('pan')) logoAsset = 'assets/PAN.png';
    else if (lower.contains('voter')) logoAsset = 'assets/Voter.png';
    else if (lower.contains('passport')) logoAsset = 'assets/Passport.png';

    // Subtitle
    String subtitle = 'Choose the type of $sName service you need';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFF), // Very light purple/blue tint
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 40, offset: Offset(0, -10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Top header row with close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Color(0xFF7C6CF0), size: 24),
                  ),
                ),

                // Logo Container
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                Text(
                  '$sName Services',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF161A3A)),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9698B5)),
                ),
                const SizedBox(height: 24),

                // Options List
                ...options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openDetailScreen(service, opt['section_data'] as Map<String, dynamic>?); // Pass the original section object
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x0F7C6CF0)),
                          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 15, offset: Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            // Option Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: opt['icon_bg'] as Color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(opt['icon'] as IconData, color: opt['icon_color'] as Color, size: 22),
                            ),
                            const SizedBox(width: 16),
                            // Option Texts
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['title'].toString(),
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF161A3A)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    opt['subtitle'].toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9698B5)),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow Button
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [(opt['icon_color'] as Color).withValues(alpha: 0.8), (opt['icon_color'] as Color)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF7C6CF0), size: 18),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Secure & Trusted',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF7C6CF0)),
                          ),
                          Text(
                            'Your data is safe with us',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9698B5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSectionPopup(Map<String, dynamic> service, List<dynamic> sections) {
    const tealPrimary = Color(0xFF00A896);
    const tealDark = Color(0xFF0284C7);

    final serviceName = (service['name'] ?? '').toString().toLowerCase();

    // 1. Aadhaar
    if (serviceName.contains('aadhaar') || serviceName.contains('aadhar')) {
      final opts = [
        {
          'title': 'Aadhaar Soft Copy',
          'subtitle': 'Get your Aadhaar card soft copy (PDF)',
          'icon': Icons.description_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'section_data': {'id': 401, 'section_name': 'Soft Copy'},
        },
        {
          'title': 'Aadhaar Hard Copy',
          'subtitle': 'Order your Aadhaar card hard copy by post',
          'icon': Icons.mail_rounded,
          'icon_bg': const Color(0xFFFCE7F3),
          'icon_color': const Color(0xFFDB2777),
          'section_data': {'id': 402, 'section_name': 'Hard Copy'},
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    // 2. PAN
    if (serviceName.contains('pan')) {
      final opts = [
        {
          'title': 'New PAN Card',
          'subtitle': 'Apply for a brand new PAN card',
          'icon': Icons.add_card_rounded,
          'icon_bg': const Color(0xFFECFDF5),
          'icon_color': const Color(0xFF059669),
          'section_data': {'id': 201, 'section_name': 'New PAN'},
        },
        {
          'title': 'Correction PAN',
          'subtitle': 'Update or correct existing PAN details',
          'icon': Icons.edit_document,
          'icon_bg': const Color(0xFFFFF7ED),
          'icon_color': const Color(0xFFEA580C),
          'section_data': {'id': 202, 'section_name': 'Correction PAN'},
        },
        {
          'title': 'Foreign PAN',
          'subtitle': 'Apply for foreign citizen PAN card',
          'icon': Icons.public_rounded,
          'icon_bg': const Color(0xFFEFF6FF),
          'icon_color': const Color(0xFF2563EB),
          'section_data': {'id': 203, 'section_name': 'Foreign PAN'},
        },
        {
          'title': 'Find PAN',
          'subtitle': 'Retrieve lost or forgotten PAN details',
          'icon': Icons.search_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'section_data': {'id': 204, 'section_name': 'Find PAN'},
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    // 3. Voter ID
    if (serviceName.contains('voter')) {
      final opts = [
        {
          'title': 'New Voter ID',
          'subtitle': 'Apply for a new Voter ID card',
          'icon': Icons.how_to_reg_rounded,
          'icon_bg': const Color(0xFFEFF6FF),
          'icon_color': const Color(0xFF2563EB),
          'section_data': {'id': 101, 'section_name': 'New Voter ID Application'},
        },
        {
          'title': 'Correction Voter ID',
          'subtitle': 'Update existing Voter ID details',
          'icon': Icons.edit_note_rounded,
          'icon_bg': const Color(0xFFFFF7ED),
          'icon_color': const Color(0xFFEA580C),
          'section_data': {'id': 102, 'section_name': 'Voter ID Correction / Update'},
        },
        {
          'title': 'Voter Print Hard Copy',
          'subtitle': 'Order a physical PVC Voter ID card',
          'icon': Icons.credit_card_rounded,
          'icon_bg': const Color(0xFFFCE7F3),
          'icon_color': const Color(0xFFDB2777),
          'section_data': {'id': 103, 'section_name': 'Voter Print Hard Copy'},
        },
        {
          'title': 'Voter Print Soft Copy',
          'subtitle': 'Download digital Voter ID (e-EPIC)',
          'icon': Icons.download_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'section_data': {'id': 104, 'section_name': 'Download E-Voter Card'},
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    // 4. Passport
    if (serviceName.contains('passport')) {
      final opts = [
        {
          'title': 'New Passport',
          'subtitle': 'Apply for a new Indian passport',
          'icon': Icons.flight_takeoff_rounded,
          'icon_bg': const Color(0xFFECFDF5),
          'icon_color': const Color(0xFF059669),
          'section_data': {'id': 1, 'section_name': 'Normal (passport)'},
        },
        {
          'title': 'Correction Passport',
          'subtitle': 'Update existing passport details',
          'icon': Icons.history_edu_rounded,
          'icon_bg': const Color(0xFFFFF7ED),
          'icon_color': const Color(0xFFEA580C),
          'section_data': {'id': 4, 'section_name': '1st Correction / Renewal passport'},
        },
        {
          'title': 'Minor Passport',
          'subtitle': 'Apply for passport for minors',
          'icon': Icons.child_care_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'section_data': {'id': 3, 'section_name': 'Minor Passport'},
        },
        {
          'title': 'PCC',
          'subtitle': 'Police Clearance Certificate',
          'icon': Icons.local_police_rounded,
          'icon_bg': const Color(0xFFF0FDF4),
          'icon_color': const Color(0xFF16A34A),
          'section_data': {'id': 7, 'section_name': 'PCC'},
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    List<dynamic> effectiveSections = List.from(sections);

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(190),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: tealPrimary.withAlpha(60),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Banner with Teal Gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tealPrimary, tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _parseIcon(service['icon']),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (service['name'] ?? 'Service Option').toString(),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Select an option to proceed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // List of Section Options with Modern Cards
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: effectiveSections.map((sec) {
                      final section = Map<String, dynamic>.from(sec);
                      final secName = (section['section_name'] ?? '').toString();
                      final isSoft = secName.toLowerCase().contains('soft');
                      final isHard = secName.toLowerCase().contains('hard');
                      final isFind = secName.toLowerCase().contains('find');
                      final isNew = secName.toLowerCase().contains('new');
                      final isForeign = secName.toLowerCase().contains('foreign');

                      IconData secIcon = Icons.credit_card_rounded;
                      String subtitle = 'Complete application details';
                      if (isSoft) {
                        secIcon = Icons.picture_as_pdf_rounded;
                        subtitle = 'Instant E-Aadhaar Digital Soft Copy';
                      } else if (isHard) {
                        secIcon = Icons.credit_card_rounded;
                        subtitle = 'Physical PVC Card Delivered to Address';
                      } else if (isFind) {
                        secIcon = Icons.search_rounded;
                        subtitle = 'Find existing PAN by Aadhaar number';
                      } else if (isNew) {
                        secIcon = Icons.add_card_rounded;
                        subtitle = 'Apply for new PAN card';
                      } else if (isForeign) {
                        secIcon = Icons.language_rounded;
                        subtitle = 'Apply for Foreign PAN card';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _openDetailScreen(service, section);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: tealPrimary.withAlpha(50),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: tealPrimary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(secIcon, color: tealPrimary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          secName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: tealPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLoginPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => setState(() {}));
  }

  void _viewAllServices() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _navigateWithAnimation(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = !auth.isLoggedIn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            setState(() => _selectedIndex = 0);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgCream,
          extendBody: true,
          drawer: _selectedIndex == 0 ? _buildDrawer(isGuest) : null,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeBody(isGuest),
                // Tab 1: Categories (All Services)
                AllServicesScreen(
                  key: ValueKey('services_${_allServices.length}'),
                  services: _allServices,
                  isGuest: isGuest,
                  showBackButton: false,
                ),
                // Tab 2: My Service Requests
                const MyApplicationsScreen(showBackButton: false),
                // Tab 3: Profile / You
                const ProfileScreen(showBackButton: false),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  // ==================== HOME TAB BODY CONTENT ====================
  Widget _buildHomeBody(bool isGuest) {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: cardWhite,
      onRefresh: () async => _loadData(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurvedHeaderSection(isGuest),
                _buildSearchBarOverlay(),
                _buildSectionTitle(
                  'Premium Services',
                  onViewAll: _viewAllServices,
                ),
                const SizedBox(height: 16),
                _buildServicesGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('Why Choose Us'),
                const SizedBox(height: 16),
                _buildWhyChooseUs(),
                const SizedBox(height: 32),
                _buildStatsWithAnimation(),
                const SizedBox(height: 32),
                _buildPoweredBySlider(),
                const SizedBox(height: 38),
                _buildTestimonialsCarousel(),
                const SizedBox(height: 32),
                _buildContactCTA(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== IMAGE-EXACT STYLISH TOP APP BAR ====================
  Widget _buildCurvedHeaderSection(bool isGuest) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBFAFF), Color(0xFFF0ECFE), Color(0xFFF8F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F7C6CF0),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Nav Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Logo & Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 4), // Padding where icon used to be
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DZI Infinity',
                            style: TextStyle(
                              color: Color(0xFF161A3A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'PRO ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFF9698B5),
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right Actions
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0x14161A3A)),
                            boxShadow: const [BoxShadow(color: Color(0x141E1B4B), blurRadius: 30, offset: Offset(0, 10))],
                          ),
                          child: const Icon(Icons.menu, color: Color(0xFF161A3A), size: 19),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _navigateWithAnimation(const NotificationsScreen()),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0x14161A3A)),
                            boxShadow: const [BoxShadow(color: Color(0x141E1B4B), blurRadius: 30, offset: Offset(0, 10))],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_none_rounded, color: Color(0xFF161A3A), size: 20),
                              if (_notificationCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [kAccentPink, kAccentPurple]),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Color(0x73E23E7B), blurRadius: 10, offset: Offset(0, 4))],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_notificationCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 22),

              // Eyebrow
              Row(
                children: const [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: kAccentPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Headline
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "Let's explore\n",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF161A3A), height: 1.18),
                    ),
                    const TextSpan(
                      text: "DZI Infinity ",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF161A3A), height: 1.18),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              // Moving shine effect
                              return LinearGradient(
                                colors: const [
                                  Color(0xFF5544D6),
                                  Color(0xFFE23E7B), // Add pink/rose for more vibrant animation
                                  Color(0xFFB9AFFF),
                                  Color(0xFF5544D6),
                                ],
                                stops: [
                                  0.0,
                                  0.3 + (_pulseController.value * 0.4),
                                  0.6 + (_pulseController.value * 0.4),
                                  1.0,
                                ],
                                begin: Alignment(-1.0 + (_pulseController.value * 2), -1.0),
                                end: Alignment(1.0 + (_pulseController.value * 2), 1.0),
                              ).createShader(bounds);
                            },
                            child: const Text(
                              "PRO",
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.18),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x237C6CF0)),
                      boxShadow: const [BoxShadow(color: Color(0x141E1B4B), blurRadius: 30, offset: Offset(0, 10))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: kAccentPink,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: kAccentPink, blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'All systems online',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B5E82)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x237C6CF0)),
                      boxShadow: const [BoxShadow(color: Color(0x141E1B4B), blurRadius: 30, offset: Offset(0, 10))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('⚡', style: TextStyle(fontSize: 10)),
                        SizedBox(width: 6),
                        Text(
                          'Instant service',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B5E82)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SEARCH BAR OVERLAY ====================
  Widget _buildSearchBarOverlay() {
    return Transform.translate(
      offset: const Offset(0, -26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x1E7C6CF0)),
            boxShadow: const [BoxShadow(color: Color(0x281E1B4B), blurRadius: 45, offset: Offset(0, 20))],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF9698B5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF161A3A)),
                  decoration: const InputDecoration(
                    hintText: "Search 'Services'",
                    hintStyle: TextStyle(color: Color(0xFF9698B5), fontSize: 14.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C6CF0), Color(0xFFB9AFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [BoxShadow(color: Color(0x597C6CF0), blurRadius: 14, offset: Offset(0, 6))],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SIDE NAVIGATION DRAWER ====================
  Widget _buildDrawer(bool isGuest) {
    final auth = Provider.of<AuthProvider>(context);
    final name = isGuest ? 'Guest User' : (auth.userName ?? 'User');
    final email = isGuest
        ? 'Tap login to access all services'
        : (auth.userEmail ?? '');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC), // very light blue/grey
      child: Column(
        children: [
          // Sleek Modern Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDFC5FE), Color(0xFFC084FC)], // Purplish accent
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Drawer Menu List Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                _drawerTile(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                if (isGuest)
                  _drawerTile(
                    icon: Icons.login_rounded,
                    title: 'Login / Sign Up',
                    accentColor: const Color.fromARGB(255, 182, 145, 227), // Pink accent
                    onTap: () {
                      Navigator.pop(context);
                      _showLoginPage();
                    },
                  ),
                _drawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'My Applications',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateWithAnimation(const MyApplicationsScreen());
                  },
                ),
                _drawerTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateWithAnimation(const NotificationsScreen());
                  },
                ),
                _drawerTile(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateWithAnimation(const ProfileScreen());
                  },
                ),
                _drawerTile(
                  icon: Icons.work_rounded,
                  title: 'Career & Opportunities',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateWithAnimation(const CareerScreen());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFE2E8F0)),
                ),
                _drawerTile(
                  icon: Icons.headset_mic_rounded,
                  title: '24/7 Customer Support',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateWithAnimation(const HelpSupportScreen());
                  },
                ),
                if (!isGuest)
                  _drawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    accentColor: const Color(0xFFEF4444), // Red for logout
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Version 2.4.0 • Secure Portal',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8), 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final Color defaultColor = const Color(0xFF334155); // Slate 700
    final Color actualColor = accentColor ?? defaultColor;
    final bool isHighlighted = accentColor != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: actualColor.withValues(alpha: 0.1),
        highlightColor: actualColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isHighlighted ? actualColor.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: actualColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: actualColor,
                    fontSize: 15,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: actualColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SECTION TITLE ====================
  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8733F), Color(0xFFE23E7B)], // Amber to Rose
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF161A3A), // Dark text for light background
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x19FF7A3D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8733F),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFFE8733F),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getServiceGradientColors(String lowerName) {
    if (lowerName.contains('aadhaar')) return const [Color(0xFFFF7A3D), Color(0xFFFFB35E)];
    if (lowerName.contains('pan')) return const [Color(0xFF12B886), Color(0xFF4FD8AE)];
    if (lowerName.contains('gst')) return const [Color(0xFF4361EE), Color(0xFF7C6CF0)];
    if (lowerName.contains('voter')) return const [Color(0xFFE23E7B), Color(0xFFFF7AA8)];
    if (lowerName.contains('fastag')) return const [Color(0xFFF6B93B), Color(0xFFFFD873)];
    if (lowerName.contains('landline')) return const [Color(0xFF6C5CE7), Color(0xFFA29BFE)];
    // default
    return const [Color(0xFF4361EE), Color(0xFF7C6CF0)];
  }

  // ==================== SERVICES GRID ====================
  Widget _buildServicesGrid() {
    // Filter services by search query
    final services = _searchQuery.isEmpty
        ? _homeServices
        : _homeServices.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase().trim());
          }).toList();

    if (services.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No services found for "$_searchQuery"',
                style: const TextStyle(color: textLight, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              const Text(
                'No services available',
                style: TextStyle(color: textLight),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          // Responsive: 3 columns for most phones, 4 for tablets/large phones
          final crossAxisCount = screenWidth > 500 ? 4 : 3;
          final spacing = 14.0;
          final totalSpacing = spacing * (crossAxisCount - 1);
          final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
          // Scale aspect ratio based on card width for a squarer, shorter look
          final childAspectRatio = cardWidth < 95 ? 0.68 : (cardWidth > 130 ? 0.78 : 0.72);
          // Responsive font and icon scaling
          final scaleFactor = (screenWidth / 375.0).clamp(0.85, 1.2);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: 16,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              final String name = (s['name'] ?? '').toString();
              final Color color = _parseColor(s['color']);
              final IconData icon = _parseIcon(s['icon']);
              final String imageUrl = _imageUrl(s['image_url']?.toString());
              final lowerName = name.toLowerCase();

              final isEnlargedTarget =
                  lowerName.contains('dth') ||
                  lowerName.contains('electricity') ||
                  lowerName.contains('piped') ||
                  lowerName.contains('gas') ||
                  lowerName.contains('water') ||
                  lowerName.contains('education') ||
                  lowerName.contains('loan') ||
                  lowerName.contains('municipal') ||
                  lowerName.contains('recharge') ||
                  lowerName.contains('mobile') ||
                  lowerName.contains('house') ||
                  lowerName.contains('housing') ||
                  lowerName.contains('fastag') ||
                  lowerName.contains('metro') ||
                  lowerName.contains('broad') ||
                  lowerName.contains('insurance');
              final double baseLogo = isEnlargedTarget ? 76.0 : 64.0;
              final double logoSize = baseLogo * scaleFactor;

              final assetImg = (s['asset_image'] ?? '').toString();
              String localAsset = assetImg;
              if (localAsset.isEmpty) {
                if (lowerName.contains('landline')) localAsset = 'assets/Landline.png';
                if (lowerName.contains('dth')) localAsset = 'assets/DTH.png';
                if (lowerName.contains('electricity')) localAsset = 'assets/Electricity.png';
                if (lowerName.contains('piped gas')) localAsset = 'assets/Piped Gas Bill.jpg';
              }

              return GestureDetector(
                onTap: () => _onServiceTap(s),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10 * scaleFactor, 10 * scaleFactor, 10 * scaleFactor, 4 * scaleFactor),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0 * scaleFactor),
                              child: _buildServiceLogoWidget(
                                name,
                                color,
                                icon,
                                localAsset,
                                imageUrl,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 48 * scaleFactor,
                        padding: EdgeInsets.fromLTRB(10 * scaleFactor, 4 * scaleFactor, 10 * scaleFactor, 12 * scaleFactor),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: (11.5 * scaleFactor).clamp(10.0, 14.0),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4 * scaleFactor),
                            Container(
                              padding: EdgeInsets.all(4 * scaleFactor),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3E8FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 12 * scaleFactor,
                                color: const Color(0xFF9333EA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceLogoWidget(
    String name,
    Color color,
    IconData icon,
    String localAsset,
    String imageUrl,
  ) {
    final lower = name.toLowerCase();

    // Always do name-based asset lookup FIRST so known services never flash
    String assetPath = '';
    if (lower.contains('aadhaar')) assetPath = 'assets/Aadhaar.png';
    if (lower.contains('pan')) assetPath = 'assets/PAN.png';
    if (lower.contains('gst')) assetPath = 'assets/GST.png';
    if (lower.contains('voter')) assetPath = 'assets/Voter.png';
    if (lower.contains('fastag')) assetPath = 'assets/Fastag.png';
    if (lower.contains('landline')) assetPath = 'assets/Landline.png';
    if (lower.contains('dth')) assetPath = 'assets/DTH.png';
    if (lower.contains('electricity')) assetPath = 'assets/Electricity.png';
    if (lower.contains('piped gas')) {
      assetPath = 'assets/Piped Gas Bill.png';
    } else if (lower.contains('gas') || lower.contains('cylinder')) {
      assetPath = 'assets/GAS.png';
    }
    if (lower.contains('dsc')) assetPath = 'assets/DSC.png';
    if (lower.contains('msme') || lower.contains('udyam')) assetPath = 'assets/MSME.png';
    if (lower.contains('fssai') || lower.contains('food')) assetPath = 'assets/FSSAI.png';
    if (lower.contains('passport')) assetPath = 'assets/PassPort.png';
    if (lower.contains('metro')) assetPath = 'assets/Metro card Recharge.png';
    if (lower.contains('broadband') || lower.contains('fiber')) assetPath = 'assets/Broadband.png';
    if (lower.contains('insurance') || lower.contains('premium')) assetPath = 'assets/Insurance premium.png';
    if (lower.contains('money') || lower.contains('transfer')) assetPath = 'assets/Money Transfer.png';
    if (lower.contains('municipal') || lower.contains('tax')) assetPath = 'assets/Muncipal Taxes.png';
    if (lower.contains('recharge') || lower.contains('postpaid') || lower.contains('mobile')) {
      assetPath = 'assets/Postpaid Mobile Recharges.png';
    }

    // Fall back to the localAsset provided by the service data
    if (assetPath.isEmpty && localAsset.isNotEmpty) {
      assetPath = localAsset;
    }

    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) {
          // If asset fails, try a network URL before showing icon
          if (imageUrl.isNotEmpty) {
            return Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (c2, e2, s2) => _buildFallbackIconBadge(icon, color),
            );
          }
          return _buildFallbackIconBadge(icon, color);
        },
      );
    }

    // Only use network as last resort (no loadingBuilder flash)
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s2) => _buildFallbackIconBadge(icon, color),
      );
    }

    return _buildFallbackIconBadge(icon, color);
  }

  Widget _buildFallbackIconBadge(IconData icon, Color color) {
    return Icon(icon, color: color, size: 50);
  }

  

  // ==================== WHY CHOOSE US ====================
  Widget _buildWhyChooseUs() {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.rocket_launch_rounded,
        'title': 'Fast Processing',
        'subtitle': 'Experience seamless, instant updates.',
        'colors': [
          const Color(0xFF2DD4BF),
          const Color(0xFF06B6D4),
        ],
      },
      {
        'icon': Icons.shield_rounded,
        'title': '100% Secure',
        'subtitle': 'Bank-grade encryption for your data.',
        'colors': [
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
        ],
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Trusted Partner',
        'subtitle': 'Millions of satisfied customers nationwide.',
        'colors': [
          const Color.fromARGB(255, 209, 73, 112),
          const Color.fromARGB(255, 185, 44, 133),
        ],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) {
          final List<Color> colors = item['colors'] as List<Color>;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  // ==================== STATS CARDS (DISNEY / ALPONA CARD STYLE) ====================
  Widget _buildStatsWithAnimation() {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Active Users',
        'subtitle': '10L+ Verified Users',
        'image': 'assets/stats_active_users.jpg',
        'bannerColor': const Color(0xFFECE9FE), // Soft Lavender
        'textColor': const Color(0xFF4C1D95),
      },
      {
        'title': 'Pan India',
        'subtitle': '28 States & UTs',
        'image': 'assets/stats_pan_india.jpg',
        'bannerColor': const Color(0xFFE0F2FE), // Soft Sky Blue
        'textColor': const Color(0xFF0369A1),
      },
      {
        'title': 'Online Help',
        'subtitle': '24/7 Dedicated Desk',
        'image': 'assets/stats_online_help.jpg',
        'bannerColor': const Color(0xFFDCFCE7), // Soft Mint
        'textColor': const Color(0xFF15803D),
      },
      {
        'title': 'Encrypted',
        'subtitle': '100% Bank Grade',
        'image': 'assets/stats_encrypted.jpg',
        'bannerColor': const Color(0xFFFEF3C7), // Soft Amber
        'textColor': const Color(0xFFB45309),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.76,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final s = stats[index];
          final String title = s['title'] as String;
          final String subtitle = s['subtitle'] as String;
          final String imagePath = s['image'] as String;
          final Color bannerColor = s['bannerColor'] as Color;
          final Color textColor = s['textColor'] as Color;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // Top 74% HD Image Section (Matching Screenshot 2 Disney/Alpona structure)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                      ),
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) {
                          return Container(
                            color: bannerColor.withValues(alpha: 0.3),
                            child: Center(
                              child: Icon(Icons.image_rounded, color: textColor, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom 26% Pastel Banner Box (Matching Screenshot 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: bannerColor,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== POWERED BY SLIDER ====================
  Widget _buildPoweredBySlider() {
    final List<Map<String, dynamic>> logosData = [
      {
        'path': 'assets/AePS logo.png',
        'width': 100.0,
        'height': 45.0,
        'paddingRight': 30.0, // Space more between AePS and utipan
      },
      {
        'path': 'assets/utipan.png',
        'width': 110.0,
        'height': 45.0,
        'paddingRight': 20.0,
      },
      {
        'path': 'assets/LIC.png',
        'width': 130.0, // Increased size for LIC
        'height': 55.0, // Increased size for LIC
        'paddingRight': 20.0,
      },
      {
        'path': 'assets/Digital India.png',
        'width': 110.0,
        'height': 45.0,
        'paddingRight': 20.0,
      },
      {
        'path': 'assets/Bharat BillPay.png',
        'width': 110.0,
        'height': 45.0,
        'paddingRight': 20.0,
      },
      {
        'path': 'assets/NSDL.png',
        'width': 130.0, // Increased size for NSDL
        'height': 55.0, // Increased size for NSDL
        'paddingRight': 20.0,
      },
    ];

    // Calculate total width of one set of logos for accurate marquee offset
    final double totalWidth = logosData.fold(0.0, (sum, item) => sum + item['width'] + item['paddingRight']);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8733F), Color(0xFFE23E7B)], // Amber to Rose
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Powered By',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF161A3A), // Dark text for light background
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 70, // Increased height slightly to accommodate larger logos
          child: AnimatedBuilder(
            animation: _marqueeController,
            builder: (context, child) {
              final double offset = -(_marqueeController.value * totalWidth);
              return Stack(
                children: [
                  Positioned(
                    left: offset,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      children: [
                        ...logosData,
                        ...logosData,
                        ...logosData,
                      ].map((item) {
                        return Container(
                          width: item['width'] + item['paddingRight'],
                          padding: EdgeInsets.only(right: item['paddingRight']),
                          alignment: Alignment.center,
                          child: Image.asset(
                            item['path'],
                            height: item['height'],
                            width: item['width'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, color: Colors.grey);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== IMAGE-2 EXACT CUSTOMER REVIEWS SLIDER ====================
  Widget _buildTestimonialsCarousel() {
    final List<Map<String, dynamic>> list = [
      {
        'n': 'Guy Hawkins',
        'handle': '@guyhawkins',
        'r': 'Impressed by the professionalism and attention to detail.',
        'asset': 'assets/Priya.png',
      },
      {
        'n': 'Karla Lynn',
        'handle': '@karlalynn98',
        'r': 'A seamless experience from start to finish. Highly recommend!',
        'asset': 'assets/Sneha.png',
      },
      {
        'n': 'Jane Cooper',
        'handle': '@janecooper',
        'r': 'Reliable and trustworthy. Made my life so much easier!',
        'asset': 'assets/Deepa.png',
      },
      {
        'n': 'Amit Patel',
        'handle': '@amitpatel',
        'r': 'Most reliable platform for all my business documentation and tax needs.',
        'asset': 'assets/Amit.png',
      },
      {
        'n': 'Vikram Rao',
        'handle': '@vikramrao',
        'r': 'ITR filing was effortless. Professional team with deep expertise.',
        'asset': 'assets/Vikram.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Customer Reviews'),
        const SizedBox(height: 16),
        SizedBox(
          height: 225,
          child: PageView.builder(
            controller: _reviewController,
            itemCount: list.length,
            onPageChanged: (index) => setState(() => _currentReview = index),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final t = list[index];
              final String name = t['n'] as String;
              final String handle = t['handle'] as String;
              final String review = t['r'] as String;
              final String assetPath = t['asset'] as String;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x14161A3A), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quotes Icon and Stars at Top
                    Row(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 40,
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            3,
                            (index) => const Icon(
                              Icons.star_rounded,
                              color: Color.fromARGB(255, 246, 185, 2),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Review Body Text
                    Expanded(
                      child: Text(
                        review,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bottom Profile Notch / Handle Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: ClipOval(
                            child: Image.asset(
                              assetPath,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF64748B),
                                  size: 22,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              handle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Indicator Dots (Image 2 style)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(list.length, (index) {
            final isSelected = _currentReview == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 22 : 7,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? kAccentPink : kFieldColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==================== MODERN HORIZONTAL NEED ASSISTANCE CARD ====================
  Widget _buildContactCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF9F4), Color(0xFFFFEADA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0x28E8733F),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141E1B4B),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -60,
              top: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x38E8733F), Colors.transparent],
                    stops: [0.0, 0.7],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x4CE8733F)),
                  ),
                  child: const Text(
                    '24/7 SUPPORT',
                    style: TextStyle(
                      color: Color(0xFFE8733F),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Need Assistance?',
                      style: TextStyle(
                        color: Color(0xFF161A3A),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our care team is online to guide you with any service query.',
                  style: TextStyle(
                    color: Color(0xFF5B5E82),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _horizontalContactBtn(
                        Icons.phone_in_talk_rounded,
                        'Call Us',
                        true,
                      ),
                      const SizedBox(width: 8),
                      _horizontalContactBtn(
                        Icons.chat_bubble_outline_rounded,
                        'Live Chat',
                        false,
                      ),
                      const SizedBox(width: 8),
                      _horizontalContactBtn(
                        Icons.email_outlined,
                        'Email',
                        false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAccentPink, kAccentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33EC4899),
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalContactBtn(IconData icon, String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(colors: [Color(0xFFE8733F), Color(0xFFFFAE72)])
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? Colors.transparent : const Color(0x14161A3A),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141E1B4B),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF161A3A), size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : const Color(0xFF161A3A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION BAR (SCREENSHOT-MATCHING STYLE) ====================
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14161A3A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1E1B4B),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.grid_view_rounded, Icons.grid_view, 'Services')),
              Expanded(child: _buildNavItem(2, Icons.assignment_rounded, Icons.assignment_outlined, 'Orders')),
              Expanded(child: _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF8B3DFF), Color(0xFFFF4B91)]) // Purple to Pink
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF8B3DFF).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CUSTOM CLIPPER FOR TOP CURVED HEADER (MATCHING SCREENSHOT) ====================
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 65);
    final firstControlPoint = Offset(size.width * 0.28, size.height + 15);
    final firstEndPoint = Offset(size.width * 0.65, size.height - 35);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint = Offset(size.width * 0.88, size.height - 75);
    final secondEndPoint = Offset(size.width, size.height - 25);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
