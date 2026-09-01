import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BbpsBillDetails {
  final String account;
  final String customerName;
  final double dueAmount;
  final String dueDate;
  final String billDate;
  final String billNumber;
  final String billPeriod;
  final String refId;
  final String fetchBillId;
  final bool isSuccess;
  final String message;
  final Map<String, dynamic> raw;

  BbpsBillDetails({
    required this.account,
    required this.customerName,
    required this.dueAmount,
    required this.dueDate,
    required this.billDate,
    required this.billNumber,
    required this.billPeriod,
    required this.refId,
    required this.fetchBillId,
    required this.isSuccess,
    required this.message,
    required this.raw,
  });

  factory BbpsBillDetails.fromJson(Map<String, dynamic> json, String accountFallback) {
    final bill = (json['bill'] is Map) ? Map<String, dynamic>.from(json['bill'] as Map) : json;
    
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      final str = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(str) ?? 0.0;
    }

    final dueAmt = parseAmount(bill['due_amount'] ?? bill['dueamount'] ?? bill['DUEAMOUNT'] ?? bill['amount'] ?? bill['Amount']);
    final custName = (bill['customer_name'] ?? bill['customername'] ?? bill['CUSTOMERNAME'] ?? bill['CustomerName'] ?? '').toString().trim();
    final dDate = (bill['due_date'] ?? bill['duedate'] ?? bill['DUEDATE'] ?? bill['DueDate'] ?? '').toString().trim();
    final bDate = (bill['bill_date'] ?? bill['billdate'] ?? bill['BILLDATE'] ?? bill['BillDate'] ?? '').toString().trim();
    final bNum = (bill['bill_number'] ?? bill['billnumber'] ?? bill['BILLNUMBER'] ?? bill['BillNumber'] ?? '').toString().trim();
    final bPeriod = (bill['bill_period'] ?? bill['bilperiod'] ?? bill['BILPERIOD'] ?? bill['BillPeriod'] ?? '').toString().trim();
    final rId = (bill['ref_id'] ?? bill['refid'] ?? bill['REFID'] ?? bill['RefID'] ?? '').toString().trim();
    final fbId = (bill['fetch_bill_id'] ?? bill['fetchBillID'] ?? bill['FETCHBILLID'] ?? bill['FetchBillID'] ?? '').toString().trim();
    
    final status = (json['status'] ?? bill['status'] ?? bill['STATUS'] ?? '').toString();
    final msg = (json['message'] ?? bill['msg'] ?? bill['MSG'] ?? bill['Message'] ?? '').toString();
    final bool success = json['success'] == true || status == '2' || (dueAmt > 0 && status != '3');

    return BbpsBillDetails(
      account: (bill['account'] ?? accountFallback).toString().trim(),
      customerName: custName.isNotEmpty ? custName : 'Consumer Account',
      dueAmount: dueAmt,
      dueDate: dDate,
      billDate: bDate,
      billNumber: bNum,
      billPeriod: bPeriod,
      refId: rId,
      fetchBillId: fbId,
      isSuccess: success,
      message: msg.isNotEmpty ? msg : (success ? 'Bill fetched successfully' : 'No pending bill found or failed to fetch'),
      raw: json,
    );
  }
}

class BbpsApiService {
  static const String roundpayUserId = '5311';
  static const String roundpayToken = '60bbee0aa84d1559faf315815efd03e4';
  static const String roundpayOutletId = '12345';
  static const String defaultGeocode = '12.9716,77.5946';
  static const String defaultPincode = '560037';

  /// Fetches bill details using Backend or Direct Roundpay API
  static Future<BbpsBillDetails> fetchBill({
    required String spKey,
    required String account,
    String? customerNumber,
    String? optional1,
    String? optional2,
    String? optional3,
    String? optional4,
  }) async {
    final cleanAccount = account.trim();
    final cleanSpKey = spKey.trim();
    final cleanDigits = (customerNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPhone = (cleanDigits.length >= 10 && RegExp(r'^[6-9]').hasMatch(cleanDigits.substring(cleanDigits.length - 10)))
        ? cleanDigits.substring(cleanDigits.length - 10)
        : '9800855244';

    // 1. Try via Backend API first
    try {
      final res = await ApiService.postApi('/bbps/fetch-bill', {
        'account': cleanAccount,
        'spkey': cleanSpKey,
        'customer_number': cleanPhone,
        'optional1': optional1 ?? '',
        'optional2': optional2 ?? '',
        'optional3': optional3 ?? '',
        'optional4': optional4 ?? '',
        'pincode': defaultPincode,
        'geocode': defaultGeocode,
      }, timeoutSeconds: 25);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        return BbpsBillDetails.fromJson(decoded, cleanAccount);
      }
    } catch (_) {
      // If backend fails, fallback to direct RoundPay API
    }

    // 2. Direct Fallback to RoundPay API
    try {
      final reqId = 'FB${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse(
        'https://api.roundpay.net/API/FetchBill?UserId=$roundpayUserId&Token=$roundpayToken&Account=${Uri.encodeComponent(cleanAccount)}&Amount=0&SPKey=${Uri.encodeComponent(cleanSpKey)}&APIRequestID=$reqId&Optional1=${Uri.encodeComponent(optional1 ?? '')}&Optional2=${Uri.encodeComponent(optional2 ?? '')}&Optional3=${Uri.encodeComponent(optional3 ?? '')}&Optional4=${Uri.encodeComponent(optional4 ?? '')}&GEOCode=$defaultGeocode&CustomerNumber=${Uri.encodeComponent(cleanPhone)}&Pincode=$defaultPincode&Format=1&OutletID=$roundpayOutletId',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return BbpsBillDetails.fromJson(decoded, cleanAccount);
    } catch (e) {
      return BbpsBillDetails(
        account: cleanAccount,
        customerName: '',
        dueAmount: 0.0,
        dueDate: '',
        billDate: '',
        billNumber: '',
        billPeriod: '',
        refId: '',
        fetchBillId: '',
        isSuccess: false,
        message: 'Could not fetch bill from provider. Please check the account number and try again.',
        raw: {'error': e.toString()},
      );
    }
  }

  /// Submits Bill Payment to Backend
  static Future<Map<String, dynamic>> payBill({
    required int userId,
    required String category,
    required String account,
    required String spKey,
    required String operatorName,
    required double amount,
    String? fetchBillId,
    String? refId,
    String? customerName,
    String? billNumber,
    String? dueDate,
    String? customerPhone,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    try {
      final res = await ApiService.postApi('/bbps/pay-bill', {
        'user_id': userId,
        'category': category,
        'account': account.trim(),
        'spkey': spKey.trim(),
        'operator_name': operatorName,
        'amount': amount,
        'fetch_bill_id': fetchBillId ?? '',
        'ref_id': refId ?? '',
        'customer_name': customerName ?? '',
        'bill_number': billNumber ?? '',
        'due_date': dueDate ?? '',
        'customer_phone': customerPhone ?? account,
        'razorpay_payment_id': razorpayPaymentId ?? '',
        'razorpay_order_id': razorpayOrderId ?? '',
      }, timeoutSeconds: 30);

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'status': 'failed',
        'message': 'Bill payment network error: $e',
      };
    }
  }
}
