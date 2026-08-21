import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'service_detail_screen.dart';
import 'Home Product/Aadhaar/aadhaar_service_screen.dart';
import 'Home Product/Pan/pan_service_screen.dart';
import 'Home Product/Gst/gst_service_screen.dart';
import 'Home Product/Voter Id/voter_id_service_screen.dart';
import 'BBPS Services/Recharge/recharge_screen.dart';
import 'BBPS Services/Landline/Landline.dart';
import 'BBPS Services/DTH/DTH.dart';
import 'BBPS Services/Electricity/Electricity.dart';
import 'BBPS Services/Piped Gas Bill/Piped Gas Bill.dart';
import 'BBPS Services/Gas Cylinder/Gas Cylinder.dart';
import 'BBPS Services/Water/Water.dart';
import 'BBPS Services/Education/Education.dart';
import 'BBPS Services/Loan Payment/Loan Payment.dart';
import 'BBPS Services/Municipal Taxes/Municipal Taxes.dart';
import 'BBPS Services/Housing Society/Housing Society.dart';
import 'BBPS Services/Metro Card/Metro Card.dart';
import 'BBPS Services/Broadband/Broadband.dart';
import 'BBPS Services/Insurance/Insurance.dart';
import 'BBPS Services/Fastag/Fastag.dart';
import 'Home Product/Fastag/fastag_purchase_screen.dart';
import 'Home Product/Dsc/dsc_service_screen.dart';
import 'Home Product/Msme/msme_service_screen.dart';
import 'Home Product/Fssai/fssai_service_screen.dart';
import 'Home Product/Passport/passport_service_screen.dart';
import 'Payment Services/Money Transfer/Money Transfer.dart';
import 'E Government Services/e_government_screen.dart';
import 'Travels/bus_booking_screen.dart';

class AllServicesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final bool isGuest;
  final bool showBackButton;
  const AllServicesScreen({
    super.key,
    required this.services,
    this.isGuest = false,
    this.showBackButton = true,
  });

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Home Product';
  bool _loadingSections = false;

  static const Color primaryTeal = Color(0xFFFF6B00);
  static const Color darkTeal = Color(0xFF7C6CF0);
  static const Color bgCream = Color(0xFFF6F0FE);
  static const Color textDark = Color(0xFF161A3A);

  Color _parseColor(dynamic c) {
    if (c == null) return primaryTeal;
    if (c is int) return Color(c);
    if (c is String) {
      String s = c.trim();
      if (s.startsWith('0x') || s.startsWith('0X')) {
        final v = int.tryParse(s);
        if (v != null) return Color(v);
      }
      if (s.startsWith('#')) {
        final v = int.tryParse('0xFF${s.substring(1)}');
        if (v != null) return Color(v);
      }
    }
    return primaryTeal;
  }

  IconData _parseIcon(dynamic i) {
    if (i == null) return Icons.assured_workload;
    switch ((i ?? '').toString().trim()) {
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

  List<Map<String, dynamic>> get _allCombinedServices {
    final eGovernmentServicesList = [
      {'id': 'e_gov_kerala_bhoomi', 'name': 'Kerala Bhoomi', 'category': 'E-Government', 'asset_image': 'assets/Kerala Bhoomi.png', 'color': '#0284C7', 'url': 'https://entebhoomi.kerala.gov.in/web/home'},
      {'id': 'e_gov_kerala_lottery', 'name': 'Kerala Lottery', 'category': 'E-Government', 'asset_image': 'assets/Kerala Lottery.png', 'color': '#00A896', 'url': 'https://statelottery.kerala.gov.in/'},
      {'id': 'e_gov_kerala_state', 'name': 'Kerala State', 'category': 'E-Government', 'asset_image': 'assets/Kerala State.png', 'color': '#F97316', 'url': 'https://highereducation.kerala.gov.in/index.php/academic/scholarships'},
      {'id': 'e_gov_k_town', 'name': 'K Town', 'category': 'E-Government', 'asset_image': 'assets/K Town.png', 'color': '#8B5CF6', 'url': 'https://k2.karnataka.gov.in/K2/'},
      {'id': 'e_gov_kaveri', 'name': 'Kaveri Portal', 'category': 'E-Government', 'asset_image': 'assets/Kaveri.png', 'color': '#059669'},
      {'id': 'e_gov_land_build', 'name': 'Land & Build', 'category': 'E-Government', 'asset_image': 'assets/Land Build.png', 'color': '#2563EB'},
      {'id': 'e_gov_meesav_telan', 'name': 'Meesava Telangana', 'category': 'E-Government', 'asset_image': 'assets/Meesav Telan.png', 'color': '#E11D48'},
      {'id': 'e_gov_nadakacheri', 'name': 'Nadakacheri', 'category': 'E-Government', 'asset_image': 'assets/Nadakacheri.png', 'color': '#D97706', 'url': 'https://ajsk.karnataka.gov.in/nk5_online/Login/Login_Public'},
      {'id': 'e_gov_panchayat_tax', 'name': 'Panchayat Tax', 'category': 'E-Government', 'asset_image': 'assets/Panchayat Tax.png', 'color': '#4F46E5'},
      {'id': 'e_gov_revenu', 'name': 'Revenue Dept', 'category': 'E-Government', 'asset_image': 'assets/Revenu.png', 'color': '#00A896'},
      {'id': 'e_gov_rtc_mr', 'name': 'RTC MR', 'category': 'E-Government', 'asset_image': 'assets/RTC MR.png', 'color': '#0284C7', 'url': 'https://landrecords.karnataka.gov.in/service2/RTC.aspx'},
      {'id': 'e_gov_sakala', 'name': 'Sakala', 'category': 'E-Government', 'asset_image': 'assets/Sakala.png', 'color': '#F59E0B', 'url': 'https://www.sakala.kar.nic.in/Index.aspx'},
      {'id': 'e_gov_sc_st', 'name': 'SC ST Portal', 'category': 'E-Government', 'asset_image': 'assets/SC ST.png', 'color': '#7C3AED'},
      {'id': 'e_gov_sc_st_kerala', 'name': 'SC ST Kerala', 'category': 'E-Government', 'asset_image': 'assets/Sc St Kerala.png', 'color': '#EC4899', 'url': 'https://scdd.kerala.gov.in/index.php/schemes'},
      {'id': 'e_gov_sc_st_tn', 'name': 'SC ST Tamil Nadu', 'category': 'E-Government', 'asset_image': 'assets/Sc st TN.png', 'color': '#10B981'},
      {'id': 'e_gov_ssp', 'name': 'SSP Portal', 'category': 'E-Government', 'asset_image': 'assets/SSP.png', 'color': '#3B82F6'},
      {'id': 'e_gov_tn_govt', 'name': 'TN Govt Services', 'category': 'E-Government', 'asset_image': 'assets/TN GOVT.png', 'color': '#0F766E'},
      {'id': 'e_gov_tn_land_survey', 'name': 'TN Land Survey', 'category': 'E-Government', 'asset_image': 'assets/TN Land Survey.png', 'color': '#D97706', 'url': 'https://tnlandsurvey.tn.gov.in/'},
      {'id': 'e_gov_tn_scholarship', 'name': 'TN Scholarship', 'category': 'E-Government', 'asset_image': 'assets/TN Scholarship.png', 'color': '#8B5CF6', 'url': 'https://ssp24-25.tnega.org/institute/dashboard.html?details=undefined'},
      {'id': 'e_gov_tn_urban_tax', 'name': 'TN Urban Tax', 'category': 'E-Government', 'asset_image': 'assets/TN Urban Tax.png', 'color': '#EF4444', 'url': 'https://tnurbanepay.tn.gov.in/'},
      {'id': 'e_gov_traffic_payment', 'name': 'Traffic Fine Payment', 'category': 'E-Government', 'asset_image': 'assets/Traffic Payment.png', 'color': '#F97316'},
      {'id': 'e_gov_ap_scholar', 'name': 'AP Scholarship', 'category': 'E-Government', 'asset_image': 'assets/AP Schlor.png', 'color': '#0284C7'},
      {'id': 'e_gov_bbmp', 'name': 'BBMP Taxes', 'category': 'E-Government', 'asset_image': 'assets/BBMP.png', 'color': '#10B981'},
      {'id': 'e_gov_chennai_corp', 'name': 'Chennai Corp', 'category': 'E-Government', 'asset_image': 'assets/Chennai Corp.png', 'color': '#6366F1', 'url': 'https://chennaicorporation.gov.in/gcc/'},
      {'id': 'e_gov_edu_loan', 'name': 'Edu Loan', 'category': 'E-Government', 'asset_image': 'assets/Edu Loan.png', 'color': '#F59E0B', 'url': 'https://pmvidyalaxmi.co.in/'},
      {'id': 'e_gov_eswathu', 'name': 'Eswathu Portal', 'category': 'E-Government', 'asset_image': 'assets/Eswathu.png', 'color': '#00A896'},
      {'id': 'e_gov_jalanidhi', 'name': 'Jalanidhi', 'category': 'E-Government', 'asset_image': 'assets/Jalanidhi.png', 'color': '#0284C7', 'url': 'http://www.mrc.gov.in/jalanidhi/'},
    ];

    final travelsServicesList = [
      {'id': 'travel_bus', 'name': 'Bus Booking', 'category': 'Travels', 'asset_image': 'assets/Bus booking.png', 'icon': 'directions_bus', 'color': '#059669'},
      {'id': 'travel_flight', 'name': 'Flight Booking', 'category': 'Travels', 'asset_image': 'assets/Flight Booking.png', 'icon': 'flight', 'color': '#0284C7'},
      {'id': 'travel_irctc', 'name': 'IRCTC', 'category': 'Travels', 'asset_image': 'assets/IRCTC.png', 'icon': 'train', 'color': '#E11D48'},
    ];

    final targetServices = [
      {'id': 'pan', 'name': 'PAN', 'category': 'Home Product', 'asset_image': 'assets/PAN.png', 'icon': 'credit_card', 'color': '#00A896'},
      {'id': 'aadhaar', 'name': 'Aadhaar', 'category': 'Home Product', 'asset_image': 'assets/Aadhaar.png', 'icon': 'fingerprint', 'color': '#0284C7'},
      {'id': 'voter', 'name': 'Voter ID', 'category': 'Home Product', 'asset_image': 'assets/Voter.png', 'icon': 'how_to_vote', 'color': '#F97316'},
      {'id': 'gst', 'name': 'GST', 'category': 'Home Product', 'asset_image': 'assets/GST.png', 'icon': 'receipt_long', 'color': '#E11D48'},
      {'id': 'fastag_purchase', 'name': 'Fastag Purchase', 'category': 'Home Product', 'asset_image': 'assets/Fastag Purchase.png', 'icon': 'directions_car', 'color': '#059669'},
      {'id': 'dsc', 'name': 'DSL', 'category': 'Home Product', 'asset_image': 'assets/DSC.png', 'icon': 'edit_document', 'color': '#8B5CF6'},
      {'id': 'msme', 'name': 'MSME', 'category': 'Home Product', 'asset_image': 'assets/MSME.png', 'icon': 'storefront', 'color': '#0284C7'},
      {'id': 'fssai', 'name': 'FSSAI', 'category': 'Home Product', 'asset_image': 'assets/FSSAI.png', 'icon': 'restaurant', 'color': '#F97316'},
      {'id': 'passport', 'name': 'Passport', 'category': 'Home Product', 'asset_image': 'assets/PassPort.png', 'icon': 'flight_takeoff', 'color': '#00A896'},
      {'id': 'landline_bbps', 'name': 'Landline', 'category': 'BBPS Services', 'asset_image': 'assets/Landline.png', 'icon': 'phone_in_talk', 'color': '#2563EB'},
      {'id': 'dth_bbps', 'name': 'DTH', 'category': 'BBPS Services', 'asset_image': 'assets/DTH.png', 'icon': 'tv', 'color': '#6D28D9'},
      {'id': 'electricity_bbps', 'name': 'Electricity', 'category': 'BBPS Services', 'asset_image': 'assets/Electricity.png', 'icon': 'bolt', 'color': '#0284C7'},
      {'id': 'piped_gas_bbps', 'name': 'Piped Gas', 'category': 'BBPS Services', 'asset_image': 'assets/Piped Gas Bill.png', 'icon': 'propane_tank', 'color': '#0EA5E9'},
      {'id': 'gas_cylinder_bbps', 'name': 'Gas', 'category': 'BBPS Services', 'asset_image': 'assets/GAS.png', 'icon': 'propane_tank', 'color': '#E11D48'},
      {'id': 'water_bbps', 'name': 'Water', 'category': 'BBPS Services', 'asset_image': 'assets/Waters.png', 'icon': 'water_drop', 'color': '#0284C7'},
      {'id': 'education_bbps', 'name': 'Education Fees', 'category': 'BBPS Services', 'asset_image': 'assets/Education.png', 'icon': 'school', 'color': '#4F46E5'},
      {'id': 'loan_payment_bbps', 'name': 'Loan Repayment', 'category': 'BBPS Services', 'asset_image': 'assets/Loan Payment.png', 'icon': 'account_balance_wallet', 'color': '#FF5722'},
      {'id': 'municipal_taxes_bbps', 'name': 'Municipal Taxes', 'category': 'BBPS Services', 'asset_image': 'assets/Muncipal Taxes.png', 'icon': 'location_city', 'color': '#F97316'},
      {'id': 'recharge', 'name': 'Mobile Recharge', 'category': 'BBPS Services', 'asset_image': 'assets/Postpaid Mobile Recharges.png', 'icon': 'phone_android', 'color': '#059669'},
      {'id': 'housing_society_bbps', 'name': 'Housing Society', 'category': 'BBPS Services', 'asset_image': 'assets/Housing Society.png', 'icon': 'home_work', 'color': '#5A80F6'},
      {'id': 'fastag_bbps', 'name': 'FASTag', 'category': 'BBPS Services', 'asset_image': 'assets/Fastag.png', 'icon': 'directions_car', 'color': '#FF2D6C'},
      {'id': 'metro_card_bbps', 'name': 'Metro Card Recharge', 'category': 'BBPS Services', 'asset_image': 'assets/Metro card Recharge.png', 'icon': 'subway', 'color': '#FF7D54'},
      {'id': 'broadband_bbps', 'name': 'Broadband', 'category': 'BBPS Services', 'asset_image': 'assets/Broadband.png', 'icon': 'router', 'color': '#6366F1'},
      {'id': 'insurance_bbps', 'name': 'Insurance Premium', 'category': 'BBPS Services', 'asset_image': 'assets/Insurance premium.png', 'icon': 'health_and_safety', 'color': '#A855F7'},
      {'id': 'money_transfer_payment', 'name': 'Money Transfer', 'category': 'Payment Services', 'asset_image': 'assets/Money Transfer.png', 'icon': 'swap_horiz', 'color': '#00A896'},
      {'id': 'aeps', 'name': 'AEPS', 'category': 'Payment Services', 'asset_image': 'assets/AEPS.png', 'icon': 'account_balance', 'color': '#0284C7'},
    ];
    targetServices.addAll(eGovernmentServicesList);
    targetServices.addAll(travelsServicesList);

    final result = <Map<String, dynamic>>[];
    final rawList = List<Map<String, dynamic>>.from(widget.services);

    for (final item in targetServices) {
      final nameKey = item['id'].toString();

      final match = rawList.firstWhere((s) {
        final n = (s['name'] ?? '').toString().toLowerCase();
        if (n == nameKey) return true;
        if (nameKey == 'pan' && n.contains('pan')) return true;
        if (nameKey == 'aadhaar' && (n.contains('aadhaar') || n.contains('aadhar'))) return true;
        if (nameKey == 'voter' && n.contains('voter')) return true;
        if (nameKey == 'gst' && n.contains('gst')) return true;
        if (nameKey == 'dsc' && (n.contains('dsc') || n.contains('dsl') || n.contains('digital'))) return true;
        if (nameKey == 'msme' && (n.contains('msme') || n.contains('umbrella'))) return true;
        if (nameKey == 'fssai' && n.contains('fssai')) return true;
        if (nameKey == 'passport' && n.contains('passport')) return true;
        if (nameKey == 'landline_bbps' && n.contains('landline')) return true;
        if (nameKey == 'dth_bbps' && n.contains('dth')) return true;
        if (nameKey == 'electricity_bbps' && n.contains('electricity')) return true;
        if (nameKey == 'piped_gas_bbps' && n.contains('piped gas')) return true;
        if (nameKey == 'gas_cylinder_bbps' && (n.contains('cylinder') || n.contains('lpg'))) return true;
        if (nameKey == 'water_bbps' && n.contains('water')) return true;
        if (nameKey == 'education_bbps' && n.contains('education')) return true;
        if (nameKey == 'loan_payment_bbps' && (n.contains('loan') || n.contains('repayment'))) return true;
        if (nameKey == 'municipal_taxes_bbps' && (n.contains('municipal') || n.contains('tax'))) return true;
        if (nameKey == 'recharge' && !n.contains('fastag') && !n.contains('metro') && !n.contains('dth') && (n.contains('recharge') || n.contains('mobile'))) return true;
        if (nameKey == 'housing_society_bbps' && (n.contains('housing') || n.contains('society'))) return true;
        if (nameKey == 'fastag_purchase' && n.contains('fastag') && n.contains('purchase')) return true;
        if (nameKey == 'fastag_bbps' && n.contains('fastag') && (n.contains('recharge') || n.contains('toll') || !n.contains('purchase'))) return true;
        if (nameKey == 'metro_card_bbps' && (n.contains('metro') || n.contains('subway'))) return true;
        if (nameKey == 'broadband_bbps' && (n.contains('broadband') || n.contains('fiber'))) return true;
        if (nameKey == 'insurance_bbps' && (n.contains('insurance') || n.contains('policy'))) return true;
        if (nameKey == 'money_transfer_payment' && (n.contains('money') || n.contains('dmt') || n.contains('transfer'))) return true;
        return false;
      }, orElse: () => item);

      final merged = Map<String, dynamic>.from(match);
      merged['category'] = item['category'];
      if (item['asset_image'] != null && (item['asset_image'] as String).isNotEmpty) {
        merged['asset_image'] = item['asset_image'];
      }
      result.add(merged);
    }
    return result;
  }

  List<Map<String, dynamic>> get _filteredServices {
    final list = _allCombinedServices;
    return list.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final cat = (s['category'] ?? '').toString();
      String mappedCat = cat;
      if (cat == 'E-Gov') mappedCat = 'E-Government';

      final matchesCategory = _selectedCategory == 'All Services' || mappedCat == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase().trim());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _categoriesWithCount {
    final list = _allCombinedServices;
    final Map<String, int> counts = {
      'Home Product': 0,
      'BBPS Services': 0,
      'Payment Services': 0,
      'E-Government': 0,
      'Travels': 0,
    };

    for (final s in list) {
      final cat = (s['category'] ?? '').toString();
      String mappedCat = cat;
      if (cat == 'E-Gov') mappedCat = 'E-Government';

      if (counts.containsKey(mappedCat)) {
        counts[mappedCat] = counts[mappedCat]! + 1;
      }
    }

    return [
      {'name': 'Home Product', 'count': counts['Home Product'] ?? 0},
      {'name': 'BBPS Services', 'count': counts['BBPS Services'] ?? 0},
      {'name': 'Payment Services', 'count': counts['Payment Services'] ?? 0},
      {'name': 'E-Government', 'count': counts['E-Government'] ?? 0},
      {'name': 'Travels', 'count': counts['Travels'] ?? 0},
    ];
  }

  // ==================== SERVICE CHECKS ====================
  bool _isMunicipalTaxesService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('municipal') || name.contains('tax') || category.contains('municipal');
  }

  bool _isLoanPaymentService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('loan') || name.contains('repayment') || category.contains('loan');
  }

  bool _isWaterService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('water') || category.contains('water');
  }

  bool _isEducationService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('education') || name.contains('school') || name.contains('college') || category.contains('education');
  }

  bool _isLandlineService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('landline') || category.contains('landline');
  }

  bool _isDthService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('dth') || category.contains('dth');
  }

  bool _isElectricityService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('electricity') || category.contains('electricity');
  }

  bool _isPipedGasService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('piped gas') || category.contains('piped gas');
  }

  bool _isGasCylinderService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('gas') || name.contains('cylinder') || category.contains('gas') || category.contains('cylinder') || name.contains('lpg');
  }

  bool _isRechargeService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    if (name.contains('fastag') || name.contains('dth') || name.contains('metro')) return false;
    return name.contains('recharge') || category.contains('recharge');
  }

  bool _isHousingSocietyService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('housing') || name.contains('society') || category.contains('housing');
  }

  bool _isFastagPurchaseService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final id = (service['id'] ?? '').toString().toLowerCase();
    return id == 'fastag_purchase' || (name.contains('fastag') && name.contains('purchase'));
  }

  bool _isFastagRechargeService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final id = (service['id'] ?? '').toString().toLowerCase();
    if (_isFastagPurchaseService(service)) return false;
    return id == 'fastag_bbps' || (name.contains('fastag') && (name.contains('recharge') || name.contains('toll')));
  }

  bool _isMetroCardService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('metro') || name.contains('subway') || category.contains('metro');
  }

  bool _isBroadbandService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('broadband') || name.contains('fiber') || category.contains('broadband');
  }

  bool _isInsuranceService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('insurance') || name.contains('policy') || category.contains('insurance');
  }

  bool _isMoneyTransferService(Map<String, dynamic> service) {
    final name = (service['name'] ?? '').toString().toLowerCase();
    final category = (service['category'] ?? '').toString().toLowerCase();
    return name.contains('money') || name.contains('dmt') || name.contains('transfer') || category.contains('money');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final filtered = _filteredServices;
    final categories = _categoriesWithCount;

    final content = Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExploreHeaderAndSearch(),
            if (categories.isNotEmpty) _buildCategoryChips(categories),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty ? _buildEmptyState() : _buildImageGrid(filtered),
            ),
          ],
        ),
        if (_loadingSections)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            ),
          ),
      ],
    );

    if (widget.showBackButton) {
      return Scaffold(
        backgroundColor: bgCream,
        appBar: AppBar(
          backgroundColor: bgCream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: primaryTeal, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Explore All Services',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ),
        body: content,
      );
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }

  // ==================== HEADER (MATCHING HOME SCREEN HERO CARD) ====================
  Widget _buildExploreHeaderAndSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Hero Card with BackgrounddziA.png ───
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/BackgrounddziA.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Row: DZI Logo & Pro Account Badge
                  Row(
                    children: [
                      // Gradient DZI Infinity Logo
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'DZI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              '∞',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                height: 0.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DZI Infinity',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRO ACCOUNT',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Welcome Back Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3E8FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                          blurRadius: 6,
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
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('👋', style: TextStyle(fontSize: 10.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Main Hero Heading
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Let's explore",
                        style: TextStyle(
                          fontSize: 22,
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
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(7),
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
                                fontSize: 11,
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

                  const SizedBox(height: 10),

                  // 4. Status Chips
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'All systems online',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 12),
                            SizedBox(width: 3),
                            Text(
                              'Instant service',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Modern Rounded Search Bar ───
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Start finding services (e.g., PAN, DTH...)',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Discover our comprehensive range of services',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CATEGORY CHIPS ====================
  Widget _buildCategoryChips(List<Map<String, dynamic>> categories) {
    final allCats = [
      {'name': 'Home Product', 'icon': Icons.home_outlined},
      {'name': 'BBPS Services', 'icon': Icons.account_balance_outlined},
      {'name': 'Payment Services', 'icon': Icons.credit_card_outlined},
      {'name': 'E-Government', 'icon': Icons.gavel_outlined},
      {'name': 'Travels', 'icon': Icons.flight_takeoff_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allCats.length,
          itemBuilder: (context, index) {
            final cat = allCats[index];
            final name = cat['name'] as String;
            final icon = cat['icon'] as IconData;
            final isSelected = _selectedCategory == name;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = name),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF8B3DFF), Color(0xFFFF4B91)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B3DFF).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No services found',
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ==================== NEUMORPHIC 3D SERVICE CARDS GRID ====================
  Widget _buildImageGrid(List<Map<String, dynamic>> services) {
    final bottomPadding = widget.showBackButton ? 40.0 : 140.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.76, // Slightly wider to fix text wrap
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              final String name = (s['name'] ?? '').toString().trim();
              final Color color = _parseColor(s['color']);
              final IconData icon = _parseIcon(s['icon']);
              final String assetImg = (s['asset_image'] ?? '').toString();

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
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _buildLogoWidget(name, color, icon, assetImg),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3E8FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: Color(0xFF9333EA),
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
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildLogoWidget(String name, Color color, IconData icon, String assetImg) {
    if (assetImg.isNotEmpty) {
      return Image.asset(
        assetImg,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Icon(icon, color: color, size: 28),
      );
    }
    return Icon(icon, color: color, size: 28);
  }

  // ==================== SERVICE TAP ROUTING & POPUPS ====================
  void _onServiceTap(Map<String, dynamic> service) async {
    final sName = (service['name'] ?? '').toString().toLowerCase();

    // Check if the service has a direct URL (e.g. E-Government links)
    final portalUrl = service['url']?.toString();
    if (portalUrl != null && portalUrl.trim().isNotEmpty) {
      final uri = Uri.parse(portalUrl.trim());
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        try { await launchUrl(uri, mode: LaunchMode.platformDefault); } catch (_) {}
      }
      return;
    }

    // 1. Direct BBPS Navigation
    if (_isLandlineService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlineScreen()));
      return;
    }
    if (_isDthService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DTHScreen()));
      return;
    }
    if (_isElectricityService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectricityScreen()));
      return;
    }
    if (_isPipedGasService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PipedGasBillScreen()));
      return;
    }
    if (_isGasCylinderService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GasCylinderScreen()));
      return;
    }
    if (_isWaterService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen()));
      return;
    }
    if (_isEducationService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationScreen()));
      return;
    }
    if (_isLoanPaymentService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanPaymentScreen()));
      return;
    }
    if (_isMunicipalTaxesService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MunicipalTaxesScreen()));
      return;
    }
    if (_isHousingSocietyService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HousingSocietyScreen()));
      return;
    }
    if (_isFastagRechargeService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FastagScreen()));
      return;
    }
    if (_isMetroCardService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MetroCardScreen()));
      return;
    }
    if (_isBroadbandService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadbandScreen()));
      return;
    }
    if (_isInsuranceService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InsuranceScreen()));
      return;
    }
    if (_isMoneyTransferService(service)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyTransferScreen()));
      return;
    }
    if (_isRechargeService(service)) {
      final opts = [
        {
          'title': 'Prepaid Mobile Recharge',
          'subtitle': 'Recharge your prepaid mobile number',
          'icon': Icons.phone_android_rounded,
          'icon_bg': const Color(0xFFEFF6FF),
          'icon_color': const Color(0xFF2563EB),
          'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen(initialIsPostpaid: false))),
        },
        {
          'title': 'Postpaid Mobile Recharge',
          'subtitle': 'Pay your postpaid mobile bills easily',
          'icon': Icons.receipt_long_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen(initialIsPostpaid: true))),
        },
      ];
      _showModernServicePopup(service, opts);
      return;
    }

    // 2. Direct E-Gov & Travels Navigation
    if (sName.contains('flight') || sName.contains('irctc')) {
      showComingSoonDialog(context);
      return;
    }
    if (sName.contains('bus')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BusBookingScreen()));
      return;
    }
    if ((service['category'] ?? '') == 'E-Government' || (service['category'] ?? '') == 'E-Gov') {
      final url = (service['url'] ?? '').toString();
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EGovernmentServicesScreen()));
      }
      return;
    }


    // 4. Section Selector or Direct Detail Flow
    final rawId = service['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    List<Map<String, dynamic>> sections = [];
    if (intId != null) {
      setState(() => _loadingSections = true);
      try {
        final result = await _api.getServiceSections(intId).timeout(const Duration(milliseconds: 1500));
        sections = (result['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loadingSections = false);
    }

    if (sections.isEmpty) {
      if (sName.contains('voter')) {
        sections = [
          {'id': 101, 'section_name': 'Apply New Voter ID'},
          {'id': 102, 'section_name': 'Correction Voter ID'},
          {'id': 103, 'section_name': 'Hard Copy'},
          {'id': 104, 'section_name': 'Soft Copy'},
        ];
      } else if (sName.contains('pan')) {
        sections = [
          {'id': 201, 'section_name': 'Correction PAN'},
          {'id': 202, 'section_name': 'New PAN Card'},
          {'id': 203, 'section_name': 'Foreign PAN Card'},
          {'id': 204, 'section_name': 'Find PAN Card'},
        ];
      } else if (sName.contains('aadhaar') || sName.contains('aadhar')) {
        sections = [
          {'id': 401, 'section_name': 'Soft Copy'},
          {'id': 402, 'section_name': 'Hard Copy'},
        ];
      }
    }

    if (sections.length > 1) {
      _showSectionPopup(service, sections);
    } else {
      _openDetail(service, sections.isNotEmpty ? Map<String, dynamic>.from(sections.first) : null);
    }
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
    else if (lower.contains('passport')) logoAsset = 'assets/PassPort.png';
    else if (lower.contains('recharge')) logoAsset = 'assets/Mobile.png';

    // Subtitle
    String subtitle = 'Choose the type of $sName service you need';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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

                ...options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (opt.containsKey('onTap')) {
                          (opt['onTap'] as VoidCallback)();
                        } else {
                          _openDetail(service, opt['section_data'] as Map<String, dynamic>?);
                        }
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
          'section_data': {'id': 101, 'section_name': 'Apply New Voter ID'},
        },
        {
          'title': 'Correction Voter ID',
          'subtitle': 'Update existing Voter ID details',
          'icon': Icons.edit_note_rounded,
          'icon_bg': const Color(0xFFFFF7ED),
          'icon_color': const Color(0xFFEA580C),
          'section_data': {'id': 102, 'section_name': 'Correction Voter ID'},
        },
        {
          'title': 'Voter Print Hard Copy',
          'subtitle': 'Order a physical PVC Voter ID card',
          'icon': Icons.credit_card_rounded,
          'icon_bg': const Color(0xFFFCE7F3),
          'icon_color': const Color(0xFFDB2777),
          'section_data': {'id': 103, 'section_name': 'Hard Copy'},
        },
        {
          'title': 'Voter Print Soft Copy',
          'subtitle': 'Download digital Voter ID (e-EPIC)',
          'icon': Icons.download_rounded,
          'icon_bg': const Color(0xFFF3E8FF),
          'icon_color': const Color(0xFF9333EA),
          'section_data': {'id': 104, 'section_name': 'Soft Copy'},
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

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text((service['name'] ?? 'Select Section').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: sections.map((sec) {
                    final section = Map<String, dynamic>.from(sec);
                    final secName = (section['section_name'] ?? '').toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          _openDetail(service, section);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: darkTeal.withValues(alpha: 0.2))),
                        tileColor: const Color(0xFFF8FAFC),
                        title: Text(secName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textDark)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: darkTeal),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetail(Map<String, dynamic> service, Map<String, dynamic>? section) {
    final sName = (service['name'] ?? '').toString().toLowerCase();
    Widget targetScreen;

    if (sName.contains('aadhaar') || sName.contains('aadhar')) {
      targetScreen = AadhaarServiceScreen(service: service, isGuest: widget.isGuest, preselectedSectionId: section?['id'] as int?, preselectedSectionData: section);
    } else if (sName.contains('pan')) {
      targetScreen = PanServiceScreen(service: service, isGuest: widget.isGuest, preselectedSectionId: section?['id'] as int?, preselectedSectionData: section);
    } else if (sName.contains('gst')) {
      targetScreen = GstServiceScreen(service: service, isGuest: widget.isGuest, preselectedSectionId: section?['id'] as int?, preselectedSectionData: section);
    } else if (sName.contains('voter')) {
      targetScreen = VoterIdServiceScreen(service: service, isGuest: widget.isGuest, preselectedSectionId: section?['id'] as int?, preselectedSectionData: section);
    } else if (sName.contains('fastag') && sName.contains('purchase')) {
      targetScreen = FastagPurchaseScreen(service: service, isGuest: widget.isGuest);
    } else if (sName.contains('dsc') || sName.contains('dsl') || sName.contains('digital')) {
      targetScreen = DscServiceScreen(service: service, isGuest: widget.isGuest);
    } else if (sName.contains('msme') || sName.contains('umbrella')) {
      targetScreen = MsmeServiceScreen(service: service, isGuest: widget.isGuest);
    } else if (sName.contains('fssai')) {
      targetScreen = FssaiServiceScreen(service: service, isGuest: widget.isGuest);
    } else if (sName.contains('passport')) {
      targetScreen = PassportServiceScreen(service: service, isGuest: widget.isGuest, preselectedSectionId: section?['id'] as int?, preselectedSectionData: section);
    } else if (sName.contains('gas') || sName.contains('cylinder') || sName.contains('piped gas') || sName.contains('lpg')) {
      targetScreen = const GasCylinderScreen();
    } else if (sName.contains('money') || sName.contains('transfer') || sName.contains('remitter') || sName.contains('dmt')) {
      targetScreen = const MoneyTransferScreen();
    } else {
      targetScreen = ServiceDetailScreen(service: service, isGuest: widget.isGuest);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
  }
}