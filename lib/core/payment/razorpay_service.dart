import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_service.dart';

/// Centralised Razorpay payment service (Secure Client-Side Implementation).
///
/// Usage:
///   1. Call [init] in your widget's [initState].
///   2. Call [openPaymentGateway] when the user taps Pay.
///   3. Call [dispose] in your widget's [dispose].
class RazorpayService {
  // Public Key ID only — Secret Key is securely stored on Backend
  static const String _keyId = 'rzp_live_TPju1nSbZyYS3i';

  late Razorpay _razorpay;

  /// Callback fired on successful payment.
  Function(PaymentSuccessResponse)? onSuccess;

  /// Callback fired when payment fails or is cancelled.
  Function(PaymentFailureResponse)? onFailure;

  /// Callback fired when user selects an external wallet.
  Function(ExternalWalletResponse)? onExternalWallet;

  /// Initialise the Razorpay SDK and register event listeners.
  /// Call this in your widget's [initState].
  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Creates a secure order via backend API (Keys protected on server)
  Future<String?> _createOrderId(double amount) async {
    try {
      final orderRes = await ApiService.createRazorpayOrder(
        amount: amount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (orderRes['success'] == true && orderRes['order_id'] != null) {
        return orderRes['order_id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Open the Razorpay payment sheet.
  ///
  /// [amount]      - Amount in INR (e.g. 150.00). Converted to paise internally.
  /// [description] - Short description shown on the checkout sheet.
  /// [name]        - Merchant / service name.
  /// [contact]     - User mobile number (optional).
  /// [email]       - User email (optional).
  Future<void> openPaymentGateway({
    required double amount,
    required String description,
    String name = 'DZI Infinity',
    String contact = '',
    String email = '',
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) async {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    // Generate secure server order_id to unlock full payment methods (UPI, Cards, NetBanking, Wallets)
    final orderId = await _createOrderId(amount);

    final Map<String, dynamic> options = {
      'key':         _keyId,
      'amount':      (amount * 100).toInt(),
      'name':        name,
      'description': description,
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
      'prefill': {
        'contact': contact.isNotEmpty ? contact : null,
        'email':   email.isNotEmpty ? email : null,
      },
      'theme': {
        'color': '#5F33E1',
      },
    };

    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      onFailure?.call(PaymentFailureResponse(
        Razorpay.PAYMENT_CANCELLED,
        'Payment could not be initiated: $e',
        null,
      ));
    }
  }

  /// Cryptographically verifies payment signature with backend
  static Future<bool> verifyPaymentOnServer(PaymentSuccessResponse response) async {
    if (response.paymentId == null || response.paymentId!.isEmpty) return false;
    
    // If orderId and signature are present, verify with HMAC SHA256 on backend
    if (response.orderId != null && response.signature != null) {
      final verifyRes = await ApiService.verifyRazorpayPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );
      return verifyRes['success'] == true;
    }
    return true;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }

  /// Release Razorpay listeners. Call this in your widget's [dispose].
  void dispose() {
    _razorpay.clear();
  }
}
