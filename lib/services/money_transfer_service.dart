import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Secure Money Transfer Service (Domestic Money Transfer - DMT).
/// All operations proxy through the secure Python backend where API keys,
/// IP whitelisting, and encryption secrets are strictly protected.
class MoneyTransferService {
  /// 1. Fetch Bank Details API (via Secure Backend Proxy)
  static Future<Map<String, dynamic>> fetchBanksResponse() async {
    try {
      final backendRes = await http.get(
        Uri.parse('${ApiService.baseUrl}/dmt/banks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (backendRes.statusCode == 200) {
        final json = jsonDecode(backendRes.body);
        if (json['data'] is List && (json['data'] as List).isNotEmpty) {
          return {
            'success': true,
            'banks': List<Map<String, dynamic>>.from(json['data']),
            'message': 'Banks fetched from API',
          };
        }
      }
      return {
        'success': false,
        'banks': <Map<String, dynamic>>[],
        'message': 'Unable to load banks at this time',
      };
    } catch (e) {
      debugPrint('[Backend Banks API Error]: $e');
      return {
        'success': false,
        'banks': <Map<String, dynamic>>[],
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBanks() async {
    final res = await fetchBanksResponse();
    return res['banks'] as List<Map<String, dynamic>>;
  }

  /// 2. Fetch Remitter Profile API
  static Future<Map<String, dynamic>> fetchRemitterProfile(String mobileNumber) async {
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/remitter-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber, 'txnMode': 'ALL', 'iftEnable': 'YES'}),
      ).timeout(const Duration(seconds: 12));

      final json = jsonDecode(backendRes.body);
      return json;
    } catch (e) {
      debugPrint('[Remitter Profile Error]: $e');
      return {'statuscode': 'RNF', 'status': 'Remitter not found or network error'};
    }
  }

  /// 3. Remitter Registration API
  static Future<Map<String, dynamic>> registerRemitter({
    required String mobileNumber,
    required String encryptedAadhaar,
    required String referenceKey,
  }) async {
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/remitter-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'encryptedAadhaar': encryptedAadhaar,
          'referenceKey': referenceKey,
        }),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Remitter Register Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Failed to initiate registration: $e'};
    }
  }

  /// 4. Remitter Registration Verify API
  static Future<Map<String, dynamic>> verifyRemitterRegistration({
    required String mobileNumber,
    required String otp,
    required String referenceKey,
  }) async {
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/remitter-register-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'otp': otp,
          'referenceKey': referenceKey,
        }),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Remitter Verify Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Verification failed: $e'};
    }
  }

  /// 5. Remitter eKYC API
  static Future<Map<String, dynamic>> remitterEkyc({
    required String mobileNumber,
    required String referenceKey,
    String latitude = '28.5093',
    String longitude = '77.2973',
    String? externalRef,
    String consentTaken = 'Y',
    String captureType = 'FINGER',
    Map<String, dynamic>? biometricData,
  }) async {
    final ref = externalRef ?? 'EKYC${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'mobileNumber': mobileNumber,
      'referenceKey': referenceKey,
      'latitude': latitude,
      'longitude': longitude,
      'externalRef': ref,
      'consentTaken': consentTaken,
      'captureType': captureType,
      'biometricData': biometricData ?? {},
    };

    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/remitter-ekyc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Remitter eKYC Error]: $e');
      return {'statuscode': 'ERR', 'status': 'eKYC failed: $e'};
    }
  }

  /// 6. Beneficiary Registration API
  static Future<Map<String, dynamic>> addBeneficiary({
    required String remitterMobileNumber,
    required String beneficiaryMobileNumber,
    required String accountNumber,
    required String ifsc,
    required String name,
    String? bankId,
    String? bankName,
  }) async {
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/beneficiary-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'remitterMobileNumber': remitterMobileNumber,
          'beneficiaryMobileNumber': beneficiaryMobileNumber,
          'accountNumber': accountNumber,
          'ifsc': ifsc,
          'bankId': bankId ?? '',
          'bankName': bankName ?? '',
          'name': name,
        }),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Beneficiary Add Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Failed to add beneficiary: $e'};
    }
  }

  /// 7. Beneficiary Registration Verify API
  static Future<Map<String, dynamic>> verifyBeneficiaryRegistration({
    required String remitterMobileNumber,
    required String beneficiaryId,
    required String otp,
    required String referenceKey,
  }) async {
    final payload = {
      'remitterMobileNumber': remitterMobileNumber,
      'beneficiaryId': beneficiaryId,
      'otp': otp,
      'referenceKey': referenceKey,
    };
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/beneficiary-register-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Beneficiary Verify Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Beneficiary verification failed: $e'};
    }
  }

  /// 8. Beneficiary Delete API
  static Future<Map<String, dynamic>> deleteBeneficiary({
    required String remitterMobileNumber,
    required String beneficiaryId,
  }) async {
    final payload = {
      'remitterMobileNumber': remitterMobileNumber,
      'beneficiaryId': beneficiaryId,
    };
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/beneficiary-delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Beneficiary Delete Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Failed to delete beneficiary: $e'};
    }
  }

  /// 9. Beneficiary Delete Verify API
  static Future<Map<String, dynamic>> verifyDeleteBeneficiary({
    required String remitterMobileNumber,
    required String beneficiaryId,
    required String otp,
    required String referenceKey,
  }) async {
    final payload = {
      'remitterMobileNumber': remitterMobileNumber,
      'beneficiaryId': beneficiaryId,
      'otp': otp,
      'referenceKey': referenceKey,
    };
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/beneficiary-delete-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Beneficiary Delete Verify Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Delete verification failed: $e'};
    }
  }

  /// 10. Generate Transaction OTP API
  static Future<Map<String, dynamic>> generateTransactionOtp({
    required String remitterMobileNumber,
    required String amount,
    required String referenceKey,
  }) async {
    final payload = {
      'remitterMobileNumber': remitterMobileNumber,
      'amount': amount,
      'referenceKey': referenceKey,
    };
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/generate-transaction-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Generate Txn OTP Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Failed to send transaction OTP: $e'};
    }
  }

  /// 11. Execute Transaction API (Production Secure)
  static Future<Map<String, dynamic>> executeTransaction({
    required String remitterMobileNumber,
    required String accountNumber,
    required String ifsc,
    required String transferMode,
    required String transferAmount,
    required String referenceKey,
    required String otp,
    String? externalRef,
    String latitude = '28.5093',
    String longitude = '77.2973',
  }) async {
    final ref = externalRef ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'remitterMobileNumber': remitterMobileNumber,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'transferMode': transferMode,
      'transferAmount': transferAmount,
      'referenceKey': referenceKey,
      'otp': otp,
      'externalRef': ref,
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Execute Transaction Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Transaction request failed: $e'};
    }
  }

  /// 12. Transaction Refund OTP API
  static Future<Map<String, dynamic>> generateTransactionRefundOtp({
    required String ipayId,
  }) async {
    final payload = {'ipayId': ipayId};
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/transaction-refund-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Refund OTP Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Failed to send refund OTP: $e'};
    }
  }

  /// 13. Transaction Refund API
  static Future<Map<String, dynamic>> transactionRefund({
    required String ipayId,
    required String referenceKey,
    required String otp,
  }) async {
    final payload = {
      'ipayId': ipayId,
      'referenceKey': referenceKey,
      'otp': otp,
    };
    try {
      final backendRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/dmt/transaction-refund'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));

      return jsonDecode(backendRes.body);
    } catch (e) {
      debugPrint('[Transaction Refund Error]: $e');
      return {'statuscode': 'ERR', 'status': 'Refund failed: $e'};
    }
  }
}
