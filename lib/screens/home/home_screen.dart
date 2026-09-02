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
import 'bottom_navbar/bottom_navbar_screen.dart';
import 'customer_reviews/customer_reviews_section.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final int initialIndex;
  const HomeScreen({super.key, this.isGuest = false, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();
  int _selectedIndex = 0;
  int _ordersRefreshKey = 0;
  List<Map<String, dynamic>> _allServices = [];
  int _notificationCount = 0;
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isCallDropdownExpanded = false;
  bool _isEmailDropdownExpanded = false;

  late AnimationController _pulseController;
  late AnimationController _partnerMarqueeController;
  late AnimationController _floatAnimationController;

  // Design Tokens
  static const Color kAccentPurple = Color(0xFF7C3AED);
  static const Color primaryOrange = Color(0xFFEC4899);
  static const Color bgCream = Colors.white;
  static const Color textLight = Color(0xFFB3A8CC);

  List<Map<String, dynamic>> get _homeServices {
    final defaultOrder = [
      {'id': 'pan', 'name': 'PAN', 'category': 'Home Product', 'icon': 'description', 'color': '#2563EB', 'asset_image': 'assets/PAN.png'},
      {'id': 'gst', 'name': 'GST', 'category': 'Home Product', 'icon': 'receipt_long', 'color': '#059669', 'asset_image': 'assets/GST.png'},
      {'id': 'msme', 'name': 'MSME', 'category': 'Home Product', 'icon': 'business', 'color': '#8B5CF6', 'asset_image': 'assets/MSME.png'},
      {'id': 'aadhaar', 'name': 'Aadhaar', 'category': 'Home Product', 'icon': 'fingerprint', 'color': '#D97706', 'asset_image': 'assets/Aadhaar.png'},
      {'id': 'travel_bus', 'name': 'Bus Booking', 'category': 'Travels', 'icon': 'directions_bus', 'color': '#EC4899', 'asset_image': 'assets/Bus booking.png'},
      {'id': 'recharge', 'name': 'Mobile Recharge', 'category': 'BBPS Services', 'asset_image': 'assets/Postpaid Mobile Recharges.png', 'icon': 'phone_android', 'color': '#059669'},
    ];

    final result = <Map<String, dynamic>>[];
    for (final item in defaultOrder) {
      final nameKey = item['name'].toString().toLowerCase().split(' ').first;
      final itemId = item['id'].toString().toLowerCase();
      final match = _allServices.firstWhere(
        (s) => (s['name'] ?? '').toString().toLowerCase().contains(nameKey) ||
               (s['id'] ?? '').toString().toLowerCase() == itemId,
        orElse: () => item,
      );
      result.add(match);
    }
    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAssets();
  }

  void _precacheAssets() {
    try {
      const assetImages = [
        'assets/Backgrounddzi.png',
        'assets/Aadhaar.png',
        'assets/PAN.png',
        'assets/GST.png',
        'assets/Voter.png',
        'assets/Fastag Purchase.png',
        'assets/Fastag.png',
        'assets/Landline.png',
        'assets/Call ful.png',
      ];
      for (final asset in assetImages) {
        precacheImage(AssetImage(asset), context).catchError((_) {});
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _partnerMarqueeController = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();

    _floatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _pulseController.dispose();
    _partnerMarqueeController.dispose();
    _floatAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Helpline: $phoneNumber'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Helpline: $phoneNumber'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF7C3AED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=Hello%20DreamZone%20Support%2C%20I%20need%20assistance');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WhatsApp Helpline: +91 9880885551'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('WhatsApp Helpline: +91 9880885551'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Assistance%20Request%20-%20DZI%20App');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Support Email: $email'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support Email: $email'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1B4B),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _normalizeCategory(String? cat) {
    if (cat == null) return 'E-Government';
    final s = cat.trim();
    final lower = s.toLowerCase();
    if (lower.contains('banking')) return 'Payment Services';
    if (lower.contains('business') || lower.contains('government') || lower.contains('goverment')) {
      return 'E-Government';
    }
    if (lower.contains('financial')) return '';
    if (lower.contains('travel')) return 'Travels';
    return s;
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    _api.getAnnouncementCount().then((count) {
      if (mounted) setState(() => _notificationCount = count);
    }).catchError((_) {});

    await auth.loadServices();

    if (mounted) {
      setState(() {
        final seen = <String>{};
        _allServices = auth.services.map((s) {
          final item = Map<String, dynamic>.from(s);
          item['category'] = _normalizeCategory(item['category']?.toString());
          return item;
        }).where((s) {
          if ((s['category'] as String).isEmpty) return false;
          final name = (s['name'] ?? '').toString();
          if (seen.contains(name)) return false;
          seen.add(name);
          return true;
        }).toList();

        _ensureServiceExists('recharge', 'Mobile Recharge', 'BBPS Services', 'assets/Postpaid Mobile Recharges.png', 'phone_android', '#059669');
        _ensureServiceExists('landline_bbps', 'Landline', 'BBPS Services', 'assets/Landline.png', 'phone_in_talk', '#2563EB');
        _ensureServiceExists('dth_bbps', 'DTH Recharge', 'BBPS Services', 'assets/DTH.png', 'tv', '#6D28D9');
        _ensureServiceExists('electricity_bbps', 'Electricity Bill', 'BBPS Services', 'assets/Electricity.png', 'bolt', '#0284C7');
        _ensureServiceExists('piped_gas_bbps', 'Piped Gas Bill', 'BBPS Services', 'assets/Piped Gas Bill.jpg', 'propane_tank', '#0EA5E9');
        _ensureServiceExists('gas_cylinder_bbps', 'Gas Cylinder', 'BBPS Services', 'assets/GAS.png', 'propane_tank', '#E11D48');
        _ensureServiceExists('housing_society_bbps', 'Housing Society', 'BBPS Services', 'assets/Housing Society.png', 'home_work', '#5A80F6');
        _ensureServiceExists('fastag_bbps', 'FASTag', 'BBPS Services', 'assets/Fastag.png', 'directions_car', '#FF2D6C');
        _ensureServiceExists('metro_card_bbps', 'Metro Card Recharge', 'BBPS Services', 'assets/Metro card Recharge.png', 'subway', '#FF7D54');
        _ensureServiceExists('broadband_bbps', 'Broadband Bill', 'BBPS Services', 'assets/Broadband.png', 'router', '#6366F1');
        _ensureServiceExists('insurance_bbps', 'Insurance Premium', 'BBPS Services', 'assets/Insurance premium.png', 'health_and_safety', '#A855F7');
        _ensureServiceExists('money_transfer_payment', 'Money Transfer', 'Payment Services', 'assets/Money Transfer.png', 'swap_horiz', '#00A896');
      });
    }
  }

  void _ensureServiceExists(String id, String name, String category, String asset, String icon, String color) {
    final key = name.toLowerCase().split(' ').first;
    final exists = _allServices.any((s) => (s['name'] ?? '').toString().toLowerCase().contains(key));
    if (!exists) {
      _allServices.add({
        'id': id,
        'name': name,
        'category': category,
        'asset_image': asset,
        'icon': icon,
        'color': color,
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

  // ==================== SERVICE NAVIGATION ====================
  Future<void> _onServiceTap(Map<String, dynamic> service) async {
    final sId = (service['id'] ?? '').toString();
    final name = (service['name'] ?? '').toString().toLowerCase();

    if (sId == 'travel_irtc' || sId == 'travel_flight' || name.contains('irtc') || name.contains('flight booking')) {
      showComingSoonDialog(context);
      return;
    }

    if (sId == 'travel_bus' || name.contains('bus booking') || name.contains('bus ticket')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BusBookingScreen()));
      return;
    }

    final portalUrl = service['url']?.toString();
    if (portalUrl != null && portalUrl.trim().isNotEmpty) {
      final uri = Uri.parse(portalUrl.trim());
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      return;
    }

    final category = (service['category'] ?? '').toString().toLowerCase();

    if (name.contains('landline') || category.contains('landline')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlineScreen()));
      return;
    }
    if (name.contains('dth') || category.contains('dth')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DTHScreen()));
      return;
    }
    if (name.contains('electricity') || category.contains('electricity')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectricityScreen()));
      return;
    }
    if (name.contains('piped gas') || category.contains('piped gas') || name.contains('gas') || category.contains('gas') || name.contains('cylinder') || category.contains('cylinder') || name.contains('lpg')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GasCylinderScreen()));
      return;
    }
    if (name.contains('water') || category.contains('water')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen()));
      return;
    }
    if (name.contains('education') || name.contains('school') || category.contains('education')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationScreen()));
      return;
    }
    if (name.contains('loan') || name.contains('repayment') || category.contains('loan')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanPaymentScreen()));
      return;
    }
    if (name.contains('fastag') || name.contains('toll') || category.contains('fastag')) {
      if (name.contains('purchase')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FastagPurchaseScreen(service: service, isGuest: widget.isGuest)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FastagScreen()));
      }
      return;
    }
    if (name.contains('metro') || name.contains('subway') || category.contains('metro')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MetroCardScreen()));
      return;
    }
    if (name.contains('broadband') || name.contains('fiber') || category.contains('broadband')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadbandScreen()));
      return;
    }
    if (name.contains('insurance') || name.contains('policy') || category.contains('insurance')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InsuranceScreen()));
      return;
    }
    if (name.contains('money') || name.contains('dmt') || name.contains('transfer') || category.contains('payment')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyTransferScreen()));
      return;
    }
    if (name.contains('housing') || name.contains('society') || category.contains('housing')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HousingSocietyScreen()));
      return;
    }

    if ((name.contains('recharge') || category.contains('recharge')) && !name.contains('fastag') && !name.contains('dth') && !name.contains('metro')) {
      _showModernServicePopup(service, [
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
      ]);
      return;
    }

    final rawId = service['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    List<Map<String, dynamic>> sections = [];
    if (intId != null) {
      try {
        final result = await _api.getServiceSections(intId).timeout(const Duration(milliseconds: 1500));
        sections = (result['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
        sections = [{'id': 301, 'section_name': 'GST Registration'}];
      } else if (sName.contains('aadhaar') || sName.contains('aadhar')) {
        sections = [
          {'id': 401, 'section_name': 'Soft Copy'},
          {'id': 402, 'section_name': 'Hard Copy'},
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

  void _openDetailScreen(Map<String, dynamic> service, Map<String, dynamic>? section) {
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
      targetScreen = RechargeScreen(initialIsPostpaid: section?['is_postpaid'] == true);
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
    } else if (sName.contains('gas') || sName.contains('cylinder') || sName.contains('piped gas') || sName.contains('lpg')) {
      targetScreen = const GasCylinderScreen();
    } else if (sName.contains('money') || sName.contains('transfer') || sName.contains('remitter') || sName.contains('dmt')) {
      targetScreen = const MoneyTransferScreen();
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
              position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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

    String logoAsset = 'assets/Explore.png';
    if (lower.contains('aadhaar') || lower.contains('aadhar')) {
      logoAsset = 'assets/Aadhaar.png';
    } else if (lower.contains('pan')) {
      logoAsset = 'assets/PAN.png';
    } else if (lower.contains('voter')) {
      logoAsset = 'assets/Voter.png';
    } else if (lower.contains('passport')) {
      logoAsset = 'assets/Passport.png';
    }

    String subtitle = 'Choose the type of $sName service you need';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: screenHeight * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFF),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 40, offset: Offset(0, -10))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Color(0xFF7C6CF0), size: 24),
                  ),
                ),
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
                ...options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openDetailScreen(service, opt['section_data'] as Map<String, dynamic>?);
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
        ),
      );
    },
  );
}

  void _showSectionPopup(Map<String, dynamic> service, List<dynamic> sections) {
    final serviceName = (service['name'] ?? '').toString().toLowerCase();

    if (serviceName.contains('aadhaar') || serviceName.contains('aadhar')) {
      _showModernServicePopup(service, [
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
      ]);
      return;
    }

    if (serviceName.contains('pan')) {
      _showModernServicePopup(service, [
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
      ]);
      return;
    }

    if (serviceName.contains('voter')) {
      _showModernServicePopup(service, [
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
      ]);
      return;
    }

    if (serviceName.contains('passport')) {
      _showModernServicePopup(service, [
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
      ]);
      return;
    }

    final opts = sections.map((sec) {
      final s = Map<String, dynamic>.from(sec);
      return {
        'title': s['section_name'] ?? 'Section',
        'subtitle': 'Complete application details',
        'icon': Icons.description_outlined,
        'icon_bg': const Color(0xFFF3E8FF),
        'icon_color': const Color(0xFF9333EA),
        'section_data': s,
      };
    }).toList();

    _showModernServicePopup(service, opts);
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
    setState(() => _selectedIndex = 1);
  }

  void _navigateWithAnimation(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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
          if (!didPop) setState(() => _selectedIndex = 0);
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
                AllServicesScreen(
                  key: ValueKey('services_${_allServices.length}'),
                  services: _allServices,
                  isGuest: isGuest,
                  showBackButton: false,
                ),
                MyApplicationsScreen(
                  key: ValueKey('applications_$_ordersRefreshKey'),
                  showBackButton: false,
                ),
                ProfileScreen(
                  key: ValueKey('profile_$_ordersRefreshKey'),
                  showBackButton: false,
                ),
              ],
            ),
          ),
          bottomNavigationBar: HomeBottomNavBar(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() {
                if (index == 2 || index == 3) {
                  _ordersRefreshKey++;
                }
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // ==================== HOME TAB BODY CONTENT ====================
  Widget _buildHomeBody(bool isGuest) {
    return RefreshIndicator(
      color: kAccentPurple,
      backgroundColor: Colors.white,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        controller: _homeScrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurvedHeaderSection(isGuest),
            _buildSearchBarOverlay(),
            _buildSectionTitle('Premium Services', onViewAll: _viewAllServices),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildServicesGrid()),
            const SizedBox(height: 32),
            _buildSectionTitle('Why Choose Us'),
            const SizedBox(height: 16),
            RepaintBoundary(child: _buildWhyChooseUs()),
            const SizedBox(height: 32),
            RepaintBoundary(child: _buildStatsWithAnimation()),
            const SizedBox(height: 32),
            _buildPoweredByPlatform(),
            const SizedBox(height: 54),
            const RepaintBoundary(child: CustomerReviewsSection()),
            const SizedBox(height: 48),
            RepaintBoundary(child: _buildContactCTA()),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER SECTION (COMPACT & PROPORTIONAL) ====================
  Widget _buildCurvedHeaderSection(bool isGuest) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF3EDFF),
          image: DecorationImage(
            image: AssetImage('assets/Backgrounddzi.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top Bar: Left Drawer (Glass) & Right Bell (Glass) ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Left Side: Hamburger Drawer Menu Button (Glass/Mirror Design)
                    InkWell(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                      ),
                    ),

                    // 2. Far Right: Notification Bell Icon (Glass/Mirror Design)
                    InkWell(
                      onTap: () => _navigateWithAnimation(const NotificationsScreen()),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF0F172A),
                              size: 21,
                            ),
                            Positioned(
                              right: 7,
                              top: 7,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF43F5E),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x60F43F5E),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                alignment: Alignment.center,
                                child: Text(
                                  _notificationCount > 0 ? '$_notificationCount' : '5',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── Welcome Badge (Glass Mirror) ───────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'WELCOME BACK!',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('👋', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Main Hero Heading ───────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Let's explore",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [Color(0xFF5F33E1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  "DZI Infinity ",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ─── Status Chips (Line by Line - Glass Mirror) ─────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: All Systems Online
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'All systems online',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Line 2: Instant Service
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Instant service',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SEARCH BAR OVERLAY ====================
  Widget _buildSearchBarOverlay() {
    return RepaintBoundary(
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            height: 52,
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: "Search 'Services'",
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SIDE NAVIGATION DRAWER ====================
  Widget _buildDrawer(bool isGuest) {
    final auth = Provider.of<AuthProvider>(context);
    final name = isGuest ? 'Guest User' : (auth.userName ?? 'User');
    final email = isGuest ? 'Tap login to access all services' : (auth.userEmail ?? '');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDFC5FE), Color(0xFFC084FC)],
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
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
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
                    accentColor: const Color.fromARGB(255, 182, 145, 227),
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
                    accentColor: const Color(0xFFEF4444),
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.logout();
                      if (mounted) {
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
                children: const [
                  Icon(Icons.shield_rounded, size: 14, color: Color(0xFF94A3B8)),
                  SizedBox(width: 6),
                  Text(
                    'Version 2.4.0 • Secure Portal',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
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
    final Color defaultColor = const Color(0xFF334155);
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
    final bool isPremiumServices = title.toLowerCase().contains('premium');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Vertical Pink Bar
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                // Crown / Star Icon Container if Premium Services
                if (isPremiumServices) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SERVICES GRID ====================
  Widget _buildServicesGrid() {
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
          final crossAxisCount = screenWidth > 500 ? 4 : 3;
          final spacing = 14.0;
          final totalSpacing = spacing * (crossAxisCount - 1);
          final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
          final childAspectRatio = cardWidth < 95 ? 0.68 : (cardWidth > 130 ? 0.78 : 0.72);
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
              final assetImg = (s['asset_image'] ?? '').toString();

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
                                assetImg,
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
      assetPath = 'assets/Piped Gas Bill.jpg';
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
    if (lower.contains('recharge') || lower.contains('postpaid') || lower.contains('mobile')) {
      assetPath = 'assets/Postpaid Mobile Recharges.png';
    }

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
          if (imageUrl.isNotEmpty) {
            return Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (c2, e2, s2) => Icon(icon, color: color, size: 50),
            );
          }
          return Icon(icon, color: color, size: 50);
        },
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s2) => Icon(icon, color: color, size: 50),
      );
    }

    return Icon(icon, color: color, size: 50);
  }

  // ==================== WHY CHOOSE US WITH SMOOTH SCROLL ENTRANCE ====================
  Widget _buildWhyChooseUs() {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.rocket_launch_rounded,
        'title': 'Fast Processing',
        'subtitle': 'Experience seamless, instant updates.',
        'fromLeft': true,
        'colors': [const Color(0xFF2DD4BF), const Color(0xFF06B6D4)],
      },
      {
        'icon': Icons.shield_rounded,
        'title': '100% Secure',
        'subtitle': 'Bank-grade encryption for your data.',
        'fromLeft': false,
        'colors': [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Trusted Partner',
        'subtitle': 'Millions of satisfied customers nationwide.',
        'fromLeft': true,
        'colors': [const Color.fromARGB(255, 209, 73, 112), const Color.fromARGB(255, 185, 44, 133)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) {
          final List<Color> colors = item['colors'] as List<Color>;
          final bool fromLeft = item['fromLeft'] as bool;

          return _ScrollEntranceCard(
            scrollController: _homeScrollController,
            fromLeft: fromLeft,
            child: Container(
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
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== STATS CARDS ====================
  Widget _buildStatsWithAnimation() {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Active Users',
        'subtitle': '10L+ Verified Users',
        'image': 'assets/stats_active_users.jpg',
        'bannerColor': const Color(0xFFECE9FE),
        'textColor': const Color(0xFF4C1D95),
      },
      {
        'title': 'Pan India',
        'subtitle': '28 States & UTs',
        'image': 'assets/stats_pan_india.jpg',
        'bannerColor': const Color(0xFFE0F2FE),
        'textColor': const Color(0xFF0369A1),
      },
      {
        'title': 'Online Help',
        'subtitle': '24/7 Dedicated Desk',
        'image': 'assets/stats_online_help.jpg',
        'bannerColor': const Color(0xFFDCFCE7),
        'textColor': const Color(0xFF15803D),
      },
      {
        'title': 'Encrypted',
        'subtitle': '100% Bank Grade',
        'image': 'assets/stats_encrypted.jpg',
        'bannerColor': const Color(0xFFFEF3C7),
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
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(color: bannerColor),
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

  // ==================== POWERED BY PARTNER CAROUSEL (CLEAN & OPTIMIZED) ====================
  Widget _buildPoweredByPlatform() {
    final List<Map<String, String>> partners = [
      {'name': 'LIC', 'asset': 'assets/LIC.png'},
      {'name': 'NSDL', 'asset': 'assets/NSDL.png'},
      {'name': 'AEPS', 'asset': 'assets/AePS logo.png'},
      {'name': 'UTI', 'asset': 'assets/utipan.png'},
      {'name': 'IRDAI', 'asset': 'assets/Insurance premium.png'},
      {'name': 'Digital India', 'asset': 'assets/Digital India.png'},
      {'name': 'Bharat BillPay', 'asset': 'assets/Bharat BillPay.png'},
    ];

    const double cardWidth = 105.0;
    const double cardSpacing = 12.0;
    final double singleSetWidth = partners.length * (cardWidth + cardSpacing);

    return RepaintBoundary(
      child: Column(
        children: [
          // ⚡ Powered By Pill Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE9D5FF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.bolt_rounded, color: Color(0xFF7C3AED), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Powered By',
                    style: TextStyle(
                      color: Color(0xFF5F33E1),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Smooth Continuous Automatic Horizontal Slider
          SizedBox(
            height: 100,
            child: AnimatedBuilder(
              animation: _partnerMarqueeController,
              builder: (context, child) {
                final double offset = -(_partnerMarqueeController.value * singleSetWidth);
                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: offset,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            ...partners,
                            ...partners,
                            ...partners,
                            ...partners,
                          ].map((p) {
                            return Container(
                              width: cardWidth,
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      p['asset']!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(Icons.verified_user_rounded, color: Color(0xFF7C3AED), size: 26),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p['name']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
    );
  }

  // ==================== ASSISTANCE CTA SECTION (MODERN 3D REDESIGN) ====================
  Widget _buildContactCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Left Titles & Subtitle, Right 3D Headset Illustration (Call ful.png)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF161A3A),
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Assistance?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We’re here to help you\n24/7 anytime, anywhere!',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // High Quality 3D Headset Artwork with Floating Animation
              AnimatedBuilder(
                animation: _floatAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -6 * _floatAnimationController.value),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/Call ful.png',
                  width: 145,
                  height: 135,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 1. Call Us (Expandable Dropdown with 9880885551)
          _buildExpandableSupportCard(
            title: 'Call Us',
            subtitle: _isCallDropdownExpanded ? 'Helpline: +91 9880885551' : 'Click to view helpline number',
            iconType: _SupportIconType.phone,
            accentColor: const Color(0xFF7C3AED),
            isExpanded: _isCallDropdownExpanded,
            onToggle: () {
              setState(() {
                _isCallDropdownExpanded = !_isCallDropdownExpanded;
              });
            },
            dropdownContent: _buildCallDropdownContent(),
          ),
          const SizedBox(height: 12),

          // 2. WhatsApp (Direct click opens WhatsApp to 9880885551 with NO dropdown)
          _buildSupportCard(
            title: 'WhatsApp',
            subtitle: 'Chat directly on +91 9880885551',
            iconType: _SupportIconType.whatsapp,
            accentColor: const Color(0xFF10B981),
            isOnline: true,
            onTap: () => _openWhatsApp('9880885551'),
          ),
          const SizedBox(height: 12),

          // 3. Gmail Support (Expandable Dropdown with dreamzone.infinity@gmail.com)
          _buildExpandableSupportCard(
            title: 'Gmail Support',
            subtitle: _isEmailDropdownExpanded ? 'dreamzone.infinity@gmail.com' : 'Click to view support email',
            iconType: _SupportIconType.email,
            accentColor: const Color(0xFF2563EB),
            isExpanded: _isEmailDropdownExpanded,
            onToggle: () {
              setState(() {
                _isEmailDropdownExpanded = !_isEmailDropdownExpanded;
              });
            },
            dropdownContent: _buildEmailDropdownContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallDropdownContent() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Direct Helpline Number',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '+91 9880885551',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('+919880885551'),
                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Call Now',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard('9880885551', 'Helpline number copied!'),
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF7C3AED)),
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC084FC), width: 1.2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF9333EA)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Available Mon - Sat | 9:00 AM - 7:00 PM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDropdownContent() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Official Support Email',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'dreamzone.infinity@gmail.com',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _sendEmail('dreamzone.infinity@gmail.com'),
                  icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    'Send Email',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard('dreamzone.infinity@gmail.com', 'Email copied!'),
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF93C5FD), width: 1.2),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2563EB)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Average response within 2-4 business hours',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSupportCard({
    required String title,
    required String subtitle,
    required _SupportIconType iconType,
    required Color accentColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget dropdownContent,
    bool isOnline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExpanded ? accentColor.withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
          width: isExpanded ? 1.5 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? accentColor.withValues(alpha: 0.08)
                : const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: isExpanded ? 20 : 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _build3DSupportIcon(iconType),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOnline) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x6610B981),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Online',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isExpanded ? accentColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpanded ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: accentColor,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: dropdownContent,
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                  sizeCurve: Curves.easeInOutCubic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required String title,
    required String subtitle,
    required _SupportIconType iconType,
    required Color accentColor,
    required VoidCallback onTap,
    bool isOnline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _build3DSupportIcon(iconType),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1B4B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x6610B981),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Online',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DSupportIcon(_SupportIconType type) {
    List<Color> gradientColors;
    Color glowColor;
    Widget innerIcon;

    switch (type) {
      case _SupportIconType.phone:
        gradientColors = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
        glowColor = const Color(0xFF7C3AED);
        innerIcon = const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 26);
        break;
      case _SupportIconType.whatsapp:
        gradientColors = const [Color(0xFF25D366), Color(0xFF128C7E)];
        glowColor = const Color(0xFF10B981);
        innerIcon = const Icon(Icons.chat_rounded, color: Colors.white, size: 25);
        break;
      case _SupportIconType.email:
        gradientColors = const [Color(0xFF60A5FA), Color(0xFF2563EB)];
        glowColor = const Color(0xFF2563EB);
        innerIcon = const Icon(Icons.mail_rounded, color: Colors.white, size: 25);
        break;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Specular light gloss shine at top-left
          Positioned(
            top: 3,
            left: 5,
            child: Container(
              width: 22,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          innerIcon,
        ],
      ),
    );
  }
}

// ==================== SCROLL-BASED ENTRANCE ANIMATION WRAPPER ====================
class _ScrollEntranceCard extends StatefulWidget {
  final ScrollController scrollController;
  final bool fromLeft;
  final Widget child;

  const _ScrollEntranceCard({
    required this.scrollController,
    required this.fromLeft,
    required this.child,
  });

  @override
  State<_ScrollEntranceCard> createState() => _ScrollEntranceCardState();
}

class _ScrollEntranceCardState extends State<_ScrollEntranceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _isInViewport = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final beginOffset = widget.fromLeft ? const Offset(-0.35, 0.0) : const Offset(0.35, 0.0);
    _slideAnim = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    widget.scrollController.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      final cardTop = position.dy;
      final cardBottom = position.dy + renderBox.size.height;

      final isVisible = cardTop < (screenHeight - 30) && cardBottom > 20;

      if (isVisible) {
        if (!_isInViewport) {
          _isInViewport = true;
          _animController.forward(from: 0.0);
        }
      } else {
        if (_isInViewport) {
          _isInViewport = false;
          _animController.reset();
        }
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: widget.child,
      ),
    );
  }
}

enum _SupportIconType {
  phone,
  whatsapp,
  email,
}


