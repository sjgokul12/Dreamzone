import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class DthApiService {
  static const String _apiMemberId = '7400';
  static const String _apiPassword = 'Dream@786';

  // PlanAPI OpCode mapping (supports Name, Code, and official RoundPay SPKey)
  static const Map<String, String> operatorCodes = {
    'AIRTEL': '24',
    '51': '24',
    'DISH': '25',
    '53': '25',
    'RELIANCE': '26',
    'SUN': '27',
    '54': '27',
    'TATA': '28',
    '55': '28',
    'VIDEOCON': '29',
    '56': '29',
    'D2H': '29',
  };

  static String getOpCode(String opNameOrCode) {
    final upper = opNameOrCode.toUpperCase().trim();
    if (operatorCodes.containsKey(upper)) {
      return operatorCodes[upper]!;
    }
    for (var entry in operatorCodes.entries) {
      if (upper.contains(entry.key)) {
        return entry.value;
      }
    }
    // Check if it's already a numeric PlanAPI opcode
    if (['24', '25', '26', '27', '28', '29'].contains(opNameOrCode)) {
      return opNameOrCode;
    }
    return '24'; // Default to Airtel
  }

  /// 1. Operator & Circle Check Request via PlanAPI
  /// Endpoint 1: https://planapi.in/api/Mobile/DthOperatorFetch?apimember_id=7400&api_password=Dream@786&dth_number=...
  /// Endpoint 2: https://planapi.in/api/Mobile/OperatorFetchNew?ApiUserID=7400&ApiPassword=Dream@786&Mobileno=...
  static Future<Map<String, dynamic>> fetchOperatorAndCircle(String mobileOrCustomerId) async {
    final cleanInput = mobileOrCustomerId.trim();
    if (cleanInput.isEmpty) {
      return {'success': false, 'message': 'Please enter a valid Customer ID / Mobile number'};
    }

    // Try DthOperatorFetch first
    try {
      final uri = Uri.parse('https://planapi.in/api/Mobile/DthOperatorFetch?apimember_id=$_apiMemberId&api_password=$_apiPassword&dth_number=$cleanInput');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['ERROR']?.toString() ?? '';
        final status = data['STATUS']?.toString() ?? '';
        final dthName = data['DthName']?.toString() ?? '';
        final dthOpCode = data['DthOpCode']?.toString() ?? '';

        if ((err == '0' || status == '1') && dthName.isNotEmpty && dthName != 'null') {
          return {
            'success': true,
            'mobile': cleanInput,
            'operator': dthName,
            'opcode': dthOpCode,
            'message': data['Message'] ?? 'Operator detected successfully'
          };
        }
      }
    } catch (_) {}

    // Try OperatorFetchNew fallback
    try {
      final uri = Uri.parse('https://planapi.in/api/Mobile/OperatorFetchNew?ApiUserID=$_apiMemberId&ApiPassword=$_apiPassword&Mobileno=$cleanInput');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final error = data['ERROR']?.toString() ?? '';
        final status = data['STATUS']?.toString() ?? '';
        final op = data['Operator']?.toString() ?? data['Operator ']?.toString() ?? '';
        final circle = data['Circle']?.toString() ?? data['Circle ']?.toString() ?? '';
        final opcode = data['OpCode']?.toString() ?? data['OpCode ']?.toString() ?? '';
        final circleCode = data['CircleCode']?.toString() ?? data['CircleCode ']?.toString() ?? '';

        if (error == '0' || status == '1' || (op.isNotEmpty && op != 'null')) {
          return {
            'success': true,
            'mobile': cleanInput,
            'operator': op,
            'opcode': opcode,
            'circle': circle,
            'circle_code': circleCode,
            'message': data['Message'] ?? 'Successfully fetched operator details'
          };
        }
      }
    } catch (_) {}

    // Fallback to backend API
    try {
      final res = await ApiService.fetchApi('/dth/fetch-operator?mobile=$cleanInput');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) return data;
      }
    } catch (_) {}

    return {
      'success': false,
      'message': 'Could not auto-detect operator. Please select your operator manually.'
    };
  }

  /// 2. Fetch DTH Customer Info & Subscription Details
  /// Request: https://planapi.in/api/Mobile/DTHINFOCheck?apimember_id=7400&api_password=Dream@786&mobile_no=...&Opcode=...
  /// Fallback: https://planapi.in/api/Mobile/DTHBasicDetails
  static Future<Map<String, dynamic>> fetchCustomerInfo({
    required String customerId,
    required String operatorNameOrCode,
  }) async {
    final cleanId = customerId.trim();
    final opCode = getOpCode(operatorNameOrCode);

    String? lastErrorMessage;

    // Try DTHINFOCheck
    try {
      final uri = Uri.parse('https://planapi.in/api/Mobile/DTHINFOCheck?apimember_id=$_apiMemberId&api_password=$_apiPassword&mobile_no=$cleanId&Opcode=$opCode');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['error']?.toString() ?? data['ERROR']?.toString() ?? '';
        final msg = data['Message']?.toString() ?? data['MESSAGE']?.toString() ?? '';

        if (err == '0' && data['DATA'] != null && data['DATA'] is Map) {
          final d = Map<String, dynamic>.from(data['DATA'] as Map);
          return {
            'success': true,
            'customer_info': {
              'customer_id': d['VC']?.toString() ?? cleanId,
              'customer_name': d['Name']?.toString() ?? 'Subscriber',
              'rmn': d['Rmn']?.toString() ?? '',
              'status': 'Active',
              'current_balance': d['Balance']?.toString() != null && d['Balance'].toString().isNotEmpty ? '₹ ${d['Balance']}' : '₹ 0.00',
              'monthly_recharge': d['Monthly']?.toString() != null && d['Monthly'].toString().isNotEmpty ? '₹ ${d['Monthly']}' : '',
              'next_recharge_date': d['Next Recharge Date']?.toString() ?? '',
              'plan_name': d['Plan']?.toString() != null && d['Plan'].toString().isNotEmpty ? d['Plan'].toString() : 'Active Pack',
              'address': d['Address']?.toString() ?? '',
              'city': d['City']?.toString() ?? '',
              'pin_code': d['PIN Code']?.toString() ?? '',
              'operator': operatorNameOrCode,
            },
            'message': msg.isNotEmpty ? msg : 'Details Fetch Successfully'
          };
        } else if (msg.isNotEmpty) {
          lastErrorMessage = msg;
        }
      }
    } catch (_) {}

    // Try DTHBasicDetails
    try {
      final uri = Uri.parse('https://planapi.in/api/Mobile/DTHBasicDetails?apimember_id=$_apiMemberId&api_password=$_apiPassword&mobile_no=$cleanId&Opcode=$opCode');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['error']?.toString() ?? data['ERROR']?.toString() ?? '';
        final msg = data['Message']?.toString() ?? data['MESSAGE']?.toString() ?? '';

        if (err == '0' && data['DATA'] != null && data['DATA'] is Map) {
          final d = Map<String, dynamic>.from(data['DATA'] as Map);
          return {
            'success': true,
            'customer_info': {
              'customer_id': d['VC']?.toString() ?? cleanId,
              'customer_name': d['Name']?.toString() ?? 'Subscriber',
              'rmn': d['Rmn']?.toString() ?? '',
              'status': 'Active',
              'current_balance': '₹ 0.00',
              'monthly_recharge': '',
              'next_recharge_date': '',
              'plan_name': 'Active Pack',
              'address': d['Address']?.toString() ?? '',
              'operator': operatorNameOrCode,
            },
            'message': msg.isNotEmpty ? msg : 'Basic details fetched successfully'
          };
        } else if (msg.isNotEmpty) {
          lastErrorMessage = msg;
        }
      }
    } catch (_) {}

    // Backend proxy fallback
    try {
      final res = await ApiService.postApi('/dth/customer-info', {
        'customer_id': cleanId,
        'operator_id': opCode,
        'operator_name': operatorNameOrCode,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['customer_info'] != null) {
          return data;
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'message': lastErrorMessage ?? 'Could not fetch customer info. Please check your Customer ID for this operator.'
    };
  }

  /// 3. Fetch DTH Plans / Packages via PlanAPI & Database
  /// Request: https://planapi.in/api/Mobile/DthPlans?apimember_id=7400&api_password=Dream@786&operatorcode=...
  static Future<List<Map<String, dynamic>>> fetchPlans(String operatorNameOrCode) async {
    final opCode = getOpCode(operatorNameOrCode);

    // Try direct PlanAPI DthPlans
    try {
      final uri = Uri.parse('https://planapi.in/api/Mobile/DthPlans?apimember_id=$_apiMemberId&api_password=$_apiPassword&operatorcode=$opCode');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final err = data['ERROR']?.toString() ?? '';
        final status = data['STATUS']?.toString() ?? '';

        if ((err == '0' || status == '0') && data['RDATA'] != null && data['RDATA'] is Map) {
          final rdata = data['RDATA'] as Map<String, dynamic>;
          final List<Map<String, dynamic>> parsedList = [];

          // Parse Combo packages
          if (rdata['Combo'] is List) {
            for (var combo in rdata['Combo']) {
              final lang = combo['Language']?.toString() ?? 'General';
              if (combo['Details'] is List) {
                for (var det in combo['Details']) {
                  final planName = det['PlanName']?.toString() ?? 'DTH Plan';
                  final channels = det['Channels']?.toString() ?? '';
                  final paidChannels = det['PaidChannels']?.toString() ?? '';
                  final hdChannels = det['HdChannels']?.toString() ?? '';

                  if (det['PricingList'] is List) {
                    for (var pr in det['PricingList']) {
                      final amountRaw = pr['Amount']?.toString() ?? '0';
                      final numPrice = double.tryParse(amountRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                      final monthStr = pr['Month']?.toString() ?? '1 Month';

                      parsedList.add({
                        'category': monthStr,
                        'language': lang,
                        'plan_name': planName,
                        'price': numPrice,
                        'validity': monthStr,
                        'channels': channels.isNotEmpty ? channels : '$paidChannels | $hdChannels',
                        'desc': '$lang Entertainment pack with $channels',
                      });
                    }
                  }
                }
              }
            }
          }

          // Parse Plan list if present
          if (rdata['Plan'] is List) {
            for (var pl in rdata['Plan']) {
              final planName = pl['PlanName']?.toString() ?? 'DTH Plan';
              final priceRaw = pl['Amount']?.toString() ?? '0';
              final numPrice = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
              final monthStr = pl['Validity']?.toString() ?? '1 Month';
              final desc = pl['Description']?.toString() ?? '';

              parsedList.add({
                'category': monthStr,
                'plan_name': planName,
                'price': numPrice,
                'validity': monthStr,
                'channels': pl['Channels']?.toString() ?? '',
                'desc': desc,
              });
            }
          }

          if (parsedList.isNotEmpty) {
            return parsedList;
          }
        }
      }
    } catch (_) {}

    // Try backend database API
    try {
      final res = await ApiService.fetchApi('/dth/plans?operator=${Uri.encodeComponent(operatorNameOrCode)}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['plans'] is List) {
          return (data['plans'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}

    return [];
  }
}
