import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://dzi-backend.onrender.com/api';
  static const String localBaseUrl = 'http://127.0.0.1:5000/api';
  static const String adminBaseUrl = 'https://dzi-backend.onrender.com/api/admin';

  /// On Mobile (APK / iOS), localhost:5000 is inaccessible (refers to phone itself).
  /// So Mobile immediately targets the cloud production backend.
  /// On Chrome Web, it tests localhost:5000 first, falling back to Render.
  static List<String> get _baseUrls => kIsWeb
      ? const [
          'http://127.0.0.1:5000/api',
          'http://localhost:5000/api',
          'https://dzi-backend.onrender.com/api',
        ]
      : const [
          'http://10.0.2.2:5000/api',
          'http://192.168.1.13:5000/api',
          'https://dzi-backend.onrender.com/api',
        ];

  /// Centralized GET request that scans appropriate backends.
  static Future<http.Response> fetchApi(String path, {int timeoutSeconds = 15}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    for (final base in _baseUrls) {
      try {
        final timeout = base.contains('5000') ? 3 : timeoutSeconds;
        final res = await http
            .get(Uri.parse('$base$path'), headers: headers)
            .timeout(Duration(seconds: timeout));
        if (res.statusCode != 404 && res.statusCode != 502) {
          return res;
        }
      } catch (_) {
        // Try next base URL
      }
    }

    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(Duration(seconds: timeoutSeconds));
      return res;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  /// Centralized POST request that scans local backend first, falling back to Render.
  static Future<http.Response> postApi(String path, Map<String, dynamic> body, {int timeoutSeconds = 25}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    for (final base in _baseUrls) {
      try {
        final timeout = base.contains('5000') ? 4 : timeoutSeconds;
        final res = await http
            .post(Uri.parse('$base$path'), headers: headers, body: jsonEncode(body))
            .timeout(Duration(seconds: timeout));
        if (res.statusCode != 404 && res.statusCode != 502) {
          return res;
        }
      } catch (_) {
        // Try next base URL
      }
    }

    try {
      final res = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)).timeout(Duration(seconds: timeoutSeconds));
      return res;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  // Helper with 25s timeout and multi-backend fallback
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await fetchApi(endpoint, timeoutSeconds: 25);
      
      if (response.body.trim().isEmpty) {
        return {'success': false, 'message': 'Empty response from server (HTTP ${response.statusCode})'};
      }
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        return {'success': false, 'message': 'Invalid response from server (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      print('GET ERROR on $endpoint: $e');
      return {'success': false, 'message': 'Server not reachable: ${e.toString().replaceAll("FormatException: ", "")}'};
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));
      
      if (response.body.trim().isEmpty) {
        return {'success': false, 'message': 'Empty response from server (HTTP ${response.statusCode})'};
      }
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        return {'success': false, 'message': 'Invalid response from server (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      print('POST ERROR on $endpoint: $e');
      return {'success': false, 'message': 'Server not reachable: ${e.toString().replaceAll("FormatException: ", "")}'};
    }
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> register(String name, String mobile, String email, String password) async {
    return _post('/register', {'name': name, 'mobile': mobile, 'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> verifyRegisterOtp(String email, String otp) async {
    return _post('/verify-register-otp', {'email': email, 'otp': otp});
  }

  Future<Map<String, dynamic>> resendOtp(String email, {String purpose = 'registration'}) async {
    return _post('/resend-otp', {'email': email, 'purpose': purpose});
  }

  Future<Map<String, dynamic>> login(String loginId, String password) async {
    return _post('/login', {'login_id': loginId, 'password': password});
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _post('/forgot-password', {'email': email});
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    return _post('/reset-password', {'email': email, 'otp': otp, 'new_password': newPassword});
  }

  // ==================== SERVICES ====================

  Future<Map<String, dynamic>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services'),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'services': []};
    }
  }

  Future<Map<String, dynamic>> getServiceForm(int serviceId) async {
    return _get('/service-form/$serviceId');
  }

  // ==================== RECHARGE ====================

  Future<Map<String, dynamic>> getRechargeOperators(String type) async {
    return _get('/recharge/operators?type=$type');
  }

  Future<Map<String, dynamic>> getRechargeCircles() async {
    return _get('/recharge/circles');
  }

  Future<Map<String, dynamic>> getRechargePlans(String operatorCode, String circle) async {
    final op = Uri.encodeComponent(operatorCode);
    final c = Uri.encodeComponent(circle);
    return _get('/recharge/plans?operator=$op&circle=$c');
  }

  // Section list for a service (used by AllServicesScreen popup)
  Future<Map<String, dynamic>> getServiceSections(int serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId/sections'),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'sections': []};
    }
  }

  // Builds a full, browser-loadable URL from a relative DB path
  // e.g. "uploads/service_images/x.jpg" -> "https://dzi-backend.onrender.com/uploads/service_images/x.jpg"
  static String imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return '';
    String path = relativePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final root = ApiService.baseUrl.endsWith('/api')
        ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 4)
        : ApiService.baseUrl;
    if (path.startsWith('/')) path = path.substring(1);
    return '$root/$path';
  }

  // ==================== PROFILE ====================

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    return _get('/user/$userId');
  }

  Future<Map<String, dynamic>> updateProfile(int userId, String name, String mobile, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId'),
        headers: headers,
        body: jsonEncode({'name': name, 'mobile': mobile, 'email': email}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed'};
    }
  }

  Future<void> saveSubmittedApplication(Map<String, dynamic> app) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'local_submitted_applications';
      final existingJson = prefs.getString(key);
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          list = jsonDecode(existingJson);
        } catch (_) {
          list = [];
        }
      }
      list.removeWhere((item) =>
          item is Map &&
          ((item['application_no'] != null && item['application_no'] == app['application_no']) ||
              (item['tracking_id'] != null && item['tracking_id'] == app['tracking_id'])));
      list.insert(0, app);
      if (list.length > 100) {
        list = list.sublist(0, 100);
      }
      await prefs.setString(key, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getLocalSubmittedApplications(int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'local_submitted_applications';
      final existingJson = prefs.getString(key);
      if (existingJson == null || existingJson.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(existingJson);
      final apps = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (userId == null || map['user_id'] == null || map['user_id'].toString() == userId.toString()) {
            apps.add(map);
          }
        }
      }
      return apps;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserApplications(int userId) async {
    return _get('/user/$userId/applications');
  }

  Future<Map<String, dynamic>> getUserCareerApplications(int userId) async {
    return _get('/user/$userId/career-applications');
  }

  Future<Map<String, dynamic>> getUserAllApplications(int userId) async {
    List<Map<String, dynamic>> remoteApps = [];
    try {
      final res = await _get('/user/$userId/all-applications');
      if (res['success'] == true && res['applications'] != null) {
        remoteApps = List<Map<String, dynamic>>.from(res['applications']);
      }
    } catch (_) {}

    final localApps = await getLocalSubmittedApplications(userId);

    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    for (final app in [...localApps, ...remoteApps]) {
      final ref = (app['application_no'] ?? app['tracking_id'] ?? app['id'])?.toString() ?? '';
      if (ref.isNotEmpty && seen.contains(ref)) continue;
      if (ref.isNotEmpty) seen.add(ref);
      merged.add(app);
    }

    return {'success': true, 'applications': merged};
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>> getUserSettings(int userId) async {
    return _get('/user/$userId/settings');
  }

  Future<Map<String, dynamic>> updateUserSettings(int userId, Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/settings'),
        headers: headers,
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount(int userId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/delete'),
        headers: headers,
        body: jsonEncode({'password': password}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed'};
    }
  }

  // ==================== ANNOUNCEMENTS ====================

  Future<Map<String, dynamic>> getAnnouncements() async {
    return _get('/announcements');
  }

  Future<int> getAnnouncementCount() async {
    try {
      final data = await _get('/announcements/count');
      return data['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ==================== FAQs ====================

  Future<Map<String, dynamic>> getFaqs() async {
    return _get('/faqs');
  }

  Future<Map<String, dynamic>> getFaqCategories() async {
    return _get('/faq-categories');
  }

  // ==================== SUPPORT TICKETS ====================

  Future<Map<String, dynamic>> submitTicket(int userId, String subject, String message, {String priority = 'medium'}) async {
    return _post('/support-tickets', {'user_id': userId, 'subject': subject, 'message': message, 'priority': priority});
  }

  Future<Map<String, dynamic>> getUserTickets(int userId) async {
    return _get('/user/$userId/tickets');
  }

  // ==================== CAREER ====================

  Future<Map<String, dynamic>> getCareerJobs() async {
    return _get('/career/jobs');
  }

  // ==================== BANNERS & COUPONS ====================

  Future<Map<String, dynamic>> getBanners() async {
    return _get('/banners');
  }

  Future<Map<String, dynamic>> getCoupons() async {
    return _get('/coupons');
  }

  // ==================== CONTACT ====================

  Future<Map<String, dynamic>> submitContact(String name, String email, String mobile, String message) async {
    return _post('/contact', {'name': name, 'email': email, 'mobile': mobile, 'message': message});
  }

  // ==================== USER SAVED DETAILS ====================

  Future<Map<String, dynamic>> getUserSavedDetails(int userId) async {
    return _get('/user/$userId/saved-details');
  }

  Future<Map<String, dynamic>> saveUserDetails(int userId, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/saved-details'),
        headers: headers,
        body: jsonEncode(details),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed'};
    }
  }

  // ==================== USER DOCUMENTS ====================

  Future<Map<String, dynamic>> getUserDocuments(int userId) async {
    return _get('/user/$userId/documents');
  }

  Future<Map<String, dynamic>> uploadUserDocument(int userId, String docType, Uint8List fileBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/$userId/documents'));
      request.fields['doc_type'] = docType;
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final response = await request.send().timeout(const Duration(seconds: 60));
      final result = await http.Response.fromStream(response);
      return jsonDecode(result.body);
    } catch (e) {
      return {'success': false, 'message': 'Upload failed'};
    }
  }

  Future<Map<String, dynamic>> deleteUserDocument(int userId, int docId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/documents/$docId'),
        headers: headers,
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed'};
    }
  }

  // ==================== PAYMENT & ORDER SECURITY ====================

  /// Creates a secure Razorpay order on backend
  static Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? receipt,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final res = await postApi('/payment/create-order', {
        'amount': amount,
        'currency': 'INR',
        ...?receipt != null ? {'receipt': receipt} : null,
        ...?notes != null ? {'notes': notes} : null,
      }, timeoutSeconds: 12);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'message': 'Failed to create payment order'};
    } catch (e) {
      return {'success': false, 'message': 'Payment service error: $e'};
    }
  }

  /// Cryptographically verifies payment signature with backend HMAC-SHA256
  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final res = await postApi('/payment/verify', {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }, timeoutSeconds: 12);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      final err = jsonDecode(res.body);
      return {'success': false, 'message': err['message'] ?? 'Payment verification failed'};
    } catch (e) {
      return {'success': false, 'message': 'Payment verification error: $e'};
    }
  }
}

