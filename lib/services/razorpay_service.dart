import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Fallback test key if backend is unreachable
  static String _activeKeyId = 'rzp_test_Tb4zmMRS7gw1ts';

  static String get razorpayKeyId => _activeKeyId;

  /// Fetches the current active Razorpay Key ID (Live or Test) from backend
  static Future<String> fetchActiveKeyId() async {
    try {
      final res = await ApiService.get('/payment/config');
      if (res['success'] == true && res['keyId'] != null && res['keyId'].toString().isNotEmpty) {
        _activeKeyId = res['keyId'].toString().trim();
        debugPrint('💳 Razorpay Key dynamically loaded from backend: $_activeKeyId');
      }
    } catch (e) {
      debugPrint('Notice loading Razorpay config from backend: $e');
    }
    return _activeKeyId;
  }

  Function(PaymentSuccessResponse)? onSuccessCallback;
  Function(PaymentFailureResponse)? onErrorCallback;

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
  }) {
    _razorpay = Razorpay();
    onSuccessCallback = onSuccess;
    onErrorCallback = onError;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amountInRupees,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String description,
    String? razorpayOrderId,
    String? paymentMethod,
    String? upiApp,
  }) {
    final prefillMap = <String, dynamic>{
      'contact': customerPhone,
      'email': customerEmail,
      'name': customerName,
    };

    final options = <String, dynamic>{
      'key': _activeKeyId,
      'amount': (amountInRupees * 100).toInt(), // Amount in paise
      if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) 'order_id': razorpayOrderId,
      'name': 'Kechi Posters',
      'description': description,
      'prefill': prefillMap,
      'theme': {
        'color': '#8B0000', // Kechi crimson brand color
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe']
      }
    };

    // If customer selected UPI in our UI, trigger Direct UPI Intent flow (Swiggy / Zomato style)
    if (paymentMethod == 'UPI') {
      prefillMap['method'] = 'upi';
      options['_'] = {'flow': 'intent'};

      if (upiApp != null) {
        final lower = upiApp.toLowerCase();
        if (lower.contains('google') || lower.contains('gpay')) {
          options['upi_app'] = 'com.google.android.apps.nbu.paisa.user';
        } else if (lower.contains('phonepe')) {
          options['upi_app'] = 'com.phonepe.app';
        } else if (lower.contains('paytm')) {
          options['upi_app'] = 'net.one97.paytm';
        } else if (lower.contains('bhim')) {
          options['upi_app'] = 'in.org.npci.upiapp';
        } else if (lower.contains('cred')) {
          options['upi_app'] = 'com.dreamplug.androidapp';
        }
      }
    } else if (paymentMethod == 'Card') {
      prefillMap['method'] = 'card';
    } else if (paymentMethod == 'NetBanking') {
      prefillMap['method'] = 'netbanking';
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('🎉 Razorpay Payment Success: ${response.paymentId}');
    if (onSuccessCallback != null) {
      onSuccessCallback!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Razorpay Payment Error: ${response.code} | ${response.message}');
    if (onErrorCallback != null) {
      onErrorCallback!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('👛 Razorpay External Wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }
}
