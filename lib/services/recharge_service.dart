import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RechargeService {
  static const String _baseUrl = 'https://dzi-backend.onrender.com/api';

  static Future<Map<String, dynamic>> _get(String pathWithQuery, {int timeoutSeconds = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final res = await http
          .get(Uri.parse('$_baseUrl$pathWithQuery'), headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {int timeoutSeconds = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  // 1. Get Operators (type can be 'prepaid' or 'postpaid')
  static Future<Map<String, dynamic>> getOperators(String type) async {
    return _get('/recharge/operators?type=$type');
  }

  // 2. Get Circles
  static Future<Map<String, dynamic>> getCircles() async {
    return _get('/recharge/circles');
  }

  // 3. Browse Plans
  static Future<Map<String, dynamic>> browsePlans(String operatorId, String circle, String mobileNumber) async {
    final queryParams = 'operator_id=$operatorId&circle=$circle&mobile_number=$mobileNumber';
    return _get('/recharge/plans?$queryParams');
  }

  // 4. Get Postpaid Bill
  static Future<Map<String, dynamic>> getBill(Map<String, dynamic> requestBody) async {
    return _post('/recharge/bill', requestBody);
  }

  // 5. Submit Recharge
  static Future<Map<String, dynamic>> submitRecharge(Map<String, dynamic> requestBody) async {
    return _post('/recharge', requestBody);
  }

  // 6. Check Recharge Status
  static Future<Map<String, dynamic>> checkStatus(String merchantTxnId) async {
    return _get('/recharge/status/$merchantTxnId');
  }

  // 7. Submit Dispute
  static Future<Map<String, dynamic>> submitDispute(Map<String, dynamic> requestBody) async {
    return _post('/recharge/dispute', requestBody);
  }
}
