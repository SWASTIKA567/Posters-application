import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Insert your Razorpay Live or Test Key ID here (from dashboard.razorpay.com)
  static const String razorpayKeyId = 'rzp_test_YOUR_KEY_HERE';

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
  }) {
    final options = {
      'key': razorpayKeyId,
      'amount': (amountInRupees * 100).toInt(), // Razorpay expects amount in paise (1 INR = 100 paise)
      'name': 'Kechi Posters',
      'description': description,
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {
        'color': '#8B0000', // Kechi crimson brand color
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe']
      }
    };

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
