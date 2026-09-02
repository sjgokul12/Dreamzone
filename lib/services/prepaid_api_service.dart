import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PrepaidApiService {
  static const String _apiUserId = '7400';
  static const String _apiPassword = 'Dream@786';

  /// 1. Operator & Circle Auto-Check Request (Direct Live API)
  static Future<Map<String, dynamic>> fetchOperatorAndCircle(String mobileNo) async {
    final cleanMobile = mobileNo.replaceAll('+91', '').replaceAll(' ', '').trim();
    if (cleanMobile.length < 10) {
      return {'success': false, 'message': 'Please enter a valid 10-digit mobile number'};
    }

    // 1. Try Backend API
    try {
      final res = await ApiService.fetchApi('/recharge/fetch-operator?mobile=$cleanMobile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final op = data['operator']?.toString().trim() ?? '';
        final circle = data['circle']?.toString().trim() ?? '';
        if (data['success'] == true && op.isNotEmpty && op != 'null') {
          return {
            'success': true,
            'mobile': cleanMobile,
            'operator': op,
            'opcode': data['opcode']?.toString() ?? '',
            'circle': circle,
            'circle_code': data['circle_code']?.toString() ?? '',
            'message': data['message'] ?? 'Operator detected from API'
          };
        }
      }
    } catch (_) {}

    // 2. Direct PlanAPI Call
    try {
      final uri = Uri.parse(
        'https://planapi.in/api/Mobile/OperatorFetchNew?ApiUserID=$_apiUserId&ApiPassword=$_apiPassword&Mobileno=$cleanMobile',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = data['Message']?.toString() ?? '';
        final op = (data['Operator'] ?? data['Operator '])?.toString().trim() ?? '';
        final circle = (data['Circle'] ?? data['Circle '])?.toString().trim() ?? '';
        final opcode = (data['OpCode'] ?? data['OpCode '])?.toString().trim() ?? '';
        final circleCode = (data['CircleCode'] ?? data['CircleCode '])?.toString().trim() ?? '';

        if (op.isNotEmpty && op != 'null') {
          return {
            'success': true,
            'mobile': cleanMobile,
            'operator': op,
            'opcode': opcode,
            'circle': circle,
            'circle_code': circleCode,
            'message': msg.isNotEmpty ? msg : 'Operator & Circle detected successfully'
          };
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'message': 'Could not detect operator from API. Please choose operator manually.'
    };
  }

  static String mapToPlanApiOpcode(String raw) {
    final u = raw.toUpperCase().trim();
    if (u.contains('JIO') || u == '116' || u == '11') return '11';
    if (u.contains('AIRTEL') || u == '3' || u == '2') return '2';
    if (u.contains('VI') || u.contains('VODAFONE') || u.contains('IDEA') || u == '37' || u == '23' || u == '6') return '23';
    if (u.contains('BSNL') || u == '4' || u == '5') return '5';
    return raw.isNotEmpty ? raw : '2';
  }

  static String mapToPlanApiCircle(String raw) {
    final u = raw.toUpperCase().trim();
    const map = {
      'TAMIL NADU': '94', 'CHENNAI': '40', 'KARNATAKA': '06', 'KERALA': '95',
      'ANDHRA PRADESH': '49', 'TELANGANA': '49', 'DELHI': '10', 'DELHI NCR': '10',
      'MUMBAI': '92', 'MAHARASHTRA': '90', 'MAHARASHTRA & GOA': '90', 'MAHARASHTRA AND GOA': '90',
      'GUJARAT': '98', 'RAJASTHAN': '70', 'WEST BENGAL': '51', 'KOLKATA': '31', 'KOLKATTA': '31',
      'PUNJAB': '02', 'HARYANA': '96', 'UP EAST': '54', 'UP WEST': '97',
      'UP(EAST)': '54', 'UP(WEST)': '97', 'UP WEST & UTTARAKHAND': '97',
      'BIHAR & JHARKHAND': '52', 'BIHAR': '52', 'ODISHA': '53', 'ORISSA': '53',
      'ASSAM': '56', 'NORTH EAST': '16', 'NESA': '16', 'HIMACHAL PRADESH': '03', 'HP': '03',
      'JAMMU & KASHMIR': '55', 'J&K': '55', 'MADHYA PRADESH & CHHATTISGARH': '93',
      'MADHYA PRADESH': '93', 'MP': '93', 'CHHATTISGARH': '101', 'GOA': '102',
    };
    return map[u] ?? (raw.isNotEmpty ? raw : '94');
  }

  /// 2. Fetch R-OFFER (Live API from PlanAPI)
  static Future<List<Map<String, dynamic>>> fetchROffers({
    required String mobileNo,
    required String operatorCode,
  }) async {
    final cleanMobile = mobileNo.replaceAll('+91', '').replaceAll(' ', '').trim();
    final opCode = mapToPlanApiOpcode(operatorCode);

    // 1. Try Backend Proxy API
    try {
      final res = await ApiService.fetchApi('/recharge/r-offer?mobile=$cleanMobile&operator_code=$opCode');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['offers'] is List && (data['offers'] as List).isNotEmpty) {
          return List<Map<String, dynamic>>.from(data['offers']);
        }
      }
    } catch (_) {}

    // 2. Direct PlanAPI Call
    try {
      final uri = Uri.parse(
        'https://planapi.in/api/Mobile/RofferCheck?apimember_id=$_apiUserId&api_password=$_apiPassword&operator_code=$opCode&mobile_no=$cleanMobile',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['ERROR']?.toString() ?? data['error']?.toString() ?? '';
        final status = data['STATUS']?.toString() ?? data['status']?.toString() ?? '';

        if ((err == '0' || status == '1') && data['RDATA'] is List) {
          final List<Map<String, dynamic>> offers = [];
          for (var item in data['RDATA']) {
            if (item is Map) {
              final priceRaw = item['price']?.toString() ?? item['rs']?.toString() ?? '0';
              final numPrice = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
              final ofrtext = item['ofrtext']?.toString() ?? item['desc']?.toString() ?? '';
              final logdesc = item['logdesc']?.toString() ?? '';

              offers.add({
                'category': 'Special R-Offer',
                'plan_name': 'Special R-Offer (₹$priceRaw)',
                'price': numPrice,
                'validity': item['validity']?.toString() ?? 'Active',
                'desc': ofrtext.isNotEmpty ? ofrtext : logdesc,
                'is_roffer': true,
              });
            }
          }
          return offers;
        }
      }
    } catch (_) {}

    return [];
  }

  /// 3. Fetch Mobile Recharge Plans / Packages (Live API from PlanAPI)
  static Future<List<Map<String, dynamic>>> fetchMobilePlans({
    required String operatorCode,
    required String circleCode,
  }) async {
    final opCode = mapToPlanApiOpcode(operatorCode);
    final cCode = mapToPlanApiCircle(circleCode);

    // 1. Try Backend API
    try {
      final res = await ApiService.fetchApi(
        '/recharge/plans?operator_id=$opCode&circle=$cCode',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['plans'] is List) {
          return (data['plans'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}

    // 2. Direct PlanAPI Call
    try {
      final uri = Uri.parse(
        'https://planapi.in/api/Mobile/MobileRechargePlan?apimember_id=$_apiUserId&api_password=$_apiPassword&operatorcode=$opCode&cricle=$cCode',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['ERROR']?.toString() ?? data['error']?.toString() ?? '';
        final status = data['STATUS']?.toString() ?? data['status']?.toString() ?? '';

        if ((err == '0' || status == '0') && data['RDATA'] != null && data['RDATA'] is Map) {
          final rdata = data['RDATA'] as Map<String, dynamic>;
          final parsed = _parseRData(rdata);
          return parsed;
        }
      }
    } catch (_) {}

    return [];
  }

  static List<Map<String, dynamic>> _parseRData(Map<String, dynamic> rdata) {
    final List<Map<String, dynamic>> list = [];

    rdata.forEach((categoryKey, items) {
      if (items is List) {
        for (var item in items) {
          if (item is Map) {
            final priceRaw = item['rs']?.toString() ?? item['price']?.toString() ?? '0';
            final numPrice = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            final validity = item['validity']?.toString() ?? 'Standard';
            final desc = item['desc']?.toString() ?? item['description']?.toString() ?? '';

            list.add({
              'category': categoryKey,
              'plan_name': '$categoryKey - ₹$priceRaw',
              'price': numPrice,
              'validity': validity,
              'desc': desc,
            });
          }
        }
      }
    });

    return list;
  }

  /// 4. Fetch Operators from Database / API
  static Future<List<Map<String, dynamic>>> fetchOperators({String type = 'prepaid'}) async {
    try {
      final res = await ApiService.fetchApi('/recharge/operators?type=$type');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['operators'] is List) {
          return List<Map<String, dynamic>>.from(data['operators']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// 5. Fetch Circles from Database / API
  static Future<List<String>> fetchCircles() async {
    try {
      final res = await ApiService.fetchApi('/recharge/circles');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['circles'] is List) {
          return List<String>.from(data['circles']);
        }
      }
    } catch (_) {}
    return [];
  }
}
