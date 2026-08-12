import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MetroApiService {
  static const String _productionBaseUrl = 'https://dzi-backend.onrender.com/api';

  static Future<Map<String, dynamic>> _get(String pathWithQuery, {int timeoutSeconds = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final res = await http
          .get(Uri.parse('$_productionBaseUrl$pathWithQuery'), headers: headers)
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
            Uri.parse('$_productionBaseUrl$path'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  // 1. Get Operators
  static Future<Map<String, dynamic>> getOperators() async {
    return _get('/metro-card/operators');
  }

  // 2. Pay/Recharge Metro Card
  static Future<Map<String, dynamic>> pay(Map<String, dynamic> requestBody) async {
    return _post('/metro-card/pay', requestBody);
  }
}
