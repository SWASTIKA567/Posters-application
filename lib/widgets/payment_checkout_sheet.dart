import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../controller/order_controller.dart';
import '../controller/notification_controller.dart';
import '../controller/profile_controller.dart';
import '../services/api_service.dart';
import '../services/email_service.dart';
import '../services/razorpay_service.dart';
import 'order_tracking_screen.dart';
import '../views/privacy_policy_view.dart';
import '../views/terms_conditions_view.dart';
import '../utils/ncr_helper.dart';

class PaymentCheckoutSheet extends StatefulWidget {
  final OrderController ctrl;

  const PaymentCheckoutSheet({super.key, required this.ctrl});

  @override
  State<PaymentCheckoutSheet> createState() => _PaymentCheckoutSheetState();
}

class _PaymentCheckoutSheetState extends State<PaymentCheckoutSheet> {
  String _selectedMethod = 'UPI'; // UPI, Card, NetBanking, COD
  String _selectedUpiApp = 'Google Pay';
  String _selectedBank = 'HDFC Bank';

  late RazorpayService _razorpayService;
  bool _isProcessing = false;

  // Guard: prevent double order placement if Razorpay fires success
  // spuriously when user returns from UPI app without paying
  bool _orderFinalized = false;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.init(
      onSuccess: _onRazorpaySuccess,
      onError: _onRazorpayError,
    );
    // Fetch latest active key (Live or Test) from backend
    RazorpayService.fetchActiveKeyId();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) async {
    // Guard: if already finalized (e.g. spurious duplicate callback), ignore
    if (_orderFinalized) {
      debugPrint('⚠️ Ignoring duplicate Razorpay success callback');
      return;
    }

    final methodLabel = _selectedMethod == 'UPI'
        ? 'UPI ($_selectedUpiApp)'
        : _selectedMethod == 'Card'
            ? 'Credit / Debit Card'
            : 'Net Banking ($_selectedBank)';

    // Strict: all three fields must be present for a real payment
    if (response.orderId == null || response.paymentId == null || response.signature == null) {
      if (mounted) setState(() => _isProcessing = false);
      Get.snackbar(
        'Payment Incomplete',
        'Payment details could not be verified by the banking server. No order was placed.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      final verifyRes = await ApiService.post('/payment/verify', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyRes == null || verifyRes['success'] != true) {
        throw Exception(verifyRes?['message'] ?? 'Payment verification failed.');
      }
      debugPrint('✅ Payment signature 100% verified on server');
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      Get.snackbar(
        'Payment Verification Failed',
        'Your transaction could not be verified securely. No order was created.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    _finalizeOrder(
      paymentMethod: methodLabel,
      paymentStatus: 'Paid',
      razorpayPaymentId: response.paymentId,
      razorpayOrderId: response.orderId,
    );
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isProcessing = false);

    // Reset guard so user can retry
    _orderFinalized = false;

    // Error code 2 = user dismissed / pressed back from payment app
    // Don't show scary error in that case
    final code = response.code ?? 0;
    if (code == Razorpay.PAYMENT_CANCELLED || code == 2) {
      // User simply went back — show soft message
      Get.snackbar(
        'Payment Cancelled',
        'You returned without completing the payment. No order was placed.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final cleanMsg = ApiService.cleanErrorMessage(
      response.message,
      defaultMessage: 'Payment was cancelled or could not be processed.',
    );
    Get.snackbar(
      'Payment Notice',
      cleanMsg,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
    );
  }

  Future<void> _handlePayment() async {
    if (widget.ctrl.deliveryAddress.value == null) {
      Get.snackbar(
        'Address Required',
        'Please select a delivery address first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final addr = widget.ctrl.deliveryAddress.value!;
    if (!isNcrRegion(state: addr.state, district: addr.city, pincode: addr.pincode)) {
      Get.snackbar(
        'Delivery Coming Soon',
        'Delivery is currently available only across the Delhi-NCR region. We will arrive in ${addr.city} soon!',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.access_time_rounded, color: Colors.white),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _orderFinalized = false; // Reset for fresh payment attempt

    // If Online Payment (UPI, Card, NetBanking), trigger Razorpay Checkout
    String userEmail = 'customer@gmail.com';
    if (Get.isRegistered<ProfileController>() && ProfileController.to.emailCtrl.text.isNotEmpty) {
      userEmail = ProfileController.to.emailCtrl.text.trim();
    }

    // Create server Razorpay Order before checkout
    String? serverOrderId;
    try {
      final orderRes = await ApiService.post('/payment/create-order', {
        'amountInRupees': widget.ctrl.grandTotal,
        'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      });
      if (orderRes['success'] == true && orderRes['orderId'] != null) {
        serverOrderId = orderRes['orderId'].toString();
      }
    } catch (e) {
      debugPrint('Server order creation notice: $e');
    }

    // Open Razorpay Native Payment Gateway with active Key & Direct Intent
    _razorpayService.openCheckout(
      amountInRupees: widget.ctrl.grandTotal,
      customerName: addr.name,
      customerPhone: addr.phone,
      customerEmail: userEmail,
      description: 'Kechi Poster Order Payment',
      razorpayOrderId: serverOrderId,
      paymentMethod: _selectedMethod,
      upiApp: _selectedUpiApp,
    );
  }

  Future<void> _finalizeOrder({
    required String paymentMethod,
    required String paymentStatus,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    // Prevent double execution
    if (_orderFinalized) return;
    _orderFinalized = true;
    final success = await widget.ctrl.placeOrder(
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
    );

    if (mounted) setState(() => _isProcessing = false);

    if (success) {
      Get.back(); // close bottom sheet

      final latestOrder = widget.ctrl.orders.isNotEmpty ? widget.ctrl.orders.first : null;
      final trackingCode = latestOrder != null ? latestOrder['trackingCode'] ?? 'KCH-84920' : 'KCH-84920';

      // Push Notification
      if (Get.isRegistered<NotificationController>()) {
        NotificationController.to.addNotification(
          title: 'Order Placed #$trackingCode',
          body: 'Your Kechi poster print order is confirmed & receipt sent to your Gmail!',
          type: 'order',
        );
      }

      // 📧 Send Gmail Notification to User
      String userEmail = 'customer@gmail.com';
      if (Get.isRegistered<ProfileController>() && ProfileController.to.emailCtrl.text.isNotEmpty) {
        userEmail = ProfileController.to.emailCtrl.text.trim();
      }

      EmailService.sendOrderConfirmationEmail(
        userEmail: userEmail,
        userName: widget.ctrl.deliveryAddress.value?.name ?? 'Customer',
        orderId: latestOrder != null ? (latestOrder['orderId'] ?? 'ORD-1001') : 'ORD-1001',
        trackingCode: trackingCode,
        totalAmount: widget.ctrl.grandTotal,
        paymentMethod: paymentMethod,
        items: latestOrder != null ? (latestOrder['items'] ?? []) : [],
      );

      if (latestOrder != null) {
        Get.to(() => OrderTrackingScreen(order: latestOrder));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.ctrl.grandTotal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Options",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        "100% Safe & Encrypted Checkout",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B0000).withValues(alpha: 0.2)),
                ),
                child: Text(
                  "₹${grandTotal.toInt()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Option Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMethodTab('UPI', 'UPI / Apps', Icons.qr_code_scanner_rounded),
                const SizedBox(width: 8),
                _buildMethodTab('Card', 'Cards', Icons.credit_card_rounded),
                const SizedBox(width: 8),
                _buildMethodTab('NetBanking', 'Net Banking', Icons.account_balance_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Method Content
          if (_selectedMethod == 'UPI') _buildUpiSection(),
          if (_selectedMethod == 'Card') _buildCardSection(),
          if (_selectedMethod == 'NetBanking') _buildNetBankingSection(),

          const SizedBox(height: 22),

          // Pay Button
          GestureDetector(
            onTap: _isProcessing ? null : _handlePayment,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFA51D24)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Connecting to Payment...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMethod == 'UPI'
                                ? "Pay ₹${grandTotal.toInt()} with $_selectedUpiApp"
                                : "Pay Securely  •  ₹${grandTotal.toInt()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Security trust badge
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "Secured by Razorpay • 256-Bit SSL Encrypted",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "By placing order, you agree to ",
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const TermsConditionsView()),
                  child: Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  " & ",
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const PrivacyPolicyView()),
                  child: Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String id, String label, IconData icon) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B0000) : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. UPI APPS SECTION ───────────────────────────────────────────────────────
  Widget _buildUpiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose your preferred UPI app",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        _buildUpiTile(
          name: 'Google Pay',
          subtitle: 'Instant direct payment via Google Pay app',
          logo: const _GPayLogo(),
          badgeText: 'FASTEST',
        ),
        const SizedBox(height: 8),
        _buildUpiTile(
          name: 'PhonePe',
          subtitle: 'Instant payment via PhonePe app',
          logo: const _PhonePeLogo(),
        ),
        const SizedBox(height: 8),
        _buildUpiTile(
          name: 'Paytm UPI',
          subtitle: 'Pay via Paytm UPI or Wallet',
          logo: const _PaytmLogo(),
        ),
        const SizedBox(height: 8),
        _buildUpiTile(
          name: 'Other UPI Apps',
          subtitle: 'BHIM, CRED, Amazon Pay or any UPI app',
          logo: const _BhimUpiLogo(),
        ),
      ],
    );
  }

  Widget _buildUpiTile({
    required String name,
    required String subtitle,
    required Widget logo,
    String? badgeText,
  }) {
    final isSelected = _selectedUpiApp == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedUpiApp = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B0000).withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B0000)
                : Colors.black.withValues(alpha: 0.09),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF8B0000).withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            logo,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: const Text(
                            'FASTEST',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF8B0000) : Colors.black26,
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. CARDS SECTION ─────────────────────────────────────────────────────────
  Widget _buildCardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Debit / Credit Cards",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Row(
                children: const [
                  _VisaLogo(),
                  SizedBox(width: 6),
                  _MastercardLogo(),
                  SizedBox(width: 6),
                  _RupayLogo(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "All Indian & International Visa, MasterCard, RuPay, and Maestro cards supported.",
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6), height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 6),
              const Text(
                "Card details entered securely on bank OTP screen",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. NET BANKING SECTION ───────────────────────────────────────────────────
  Widget _buildNetBankingSection() {
    final banks = [
      {'name': 'HDFC Bank', 'color': const Color(0xFF004C8F)},
      {'name': 'SBI Bank',  'color': const Color(0xFF280071)},
      {'name': 'ICICI Bank','color': const Color(0xFFB02A30)},
      {'name': 'Axis Bank', 'color': const Color(0xFF97144D)},
      {'name': 'Kotak',     'color': const Color(0xFFED1C24)},
      {'name': 'All Banks', 'color': Colors.black87},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Bank", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: banks.map((b) {
            final isBankSelected = _selectedBank == b['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedBank = b['name'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isBankSelected
                      ? const Color(0xFF8B0000).withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBankSelected
                        ? const Color(0xFF8B0000)
                        : Colors.black.withValues(alpha: 0.12),
                    width: isBankSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_rounded, size: 15, color: b['color'] as Color),
                    const SizedBox(width: 6),
                    Text(
                      b['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isBankSelected ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHENTIC PAYMENT BRAND LOGOS (Vector & Precision Canvas)
// ─────────────────────────────────────────────────────────────────────────────

/// Google Pay Real Badge (from official logo asset)
class _GPayLogo extends StatelessWidget {
  const _GPayLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/payments/gpay.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// PhonePe Real Purple Badge (from official logo asset)
class _PhonePeLogo extends StatelessWidget {
  const _PhonePeLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/payments/phonepe.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Paytm Real Blue & Cyan Badge (from official logo asset)
class _PaytmLogo extends StatelessWidget {
  const _PaytmLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF002E6E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002E6E).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/payments/paytm.webp',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Official BHIM UPI Badge
class _BhimUpiLogo extends StatelessWidget {
  const _BhimUpiLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF00897B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 4,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6F00),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'UPI',
              style: TextStyle(
                color: Color(0xFF0F4C81),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real Visa Badge
class _VisaLogo extends StatelessWidget {
  const _VisaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71), // Visa Blue
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Real MasterCard Badge (Overlapping Circles)
class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: SizedBox(
        width: 22,
        height: 13,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB001B), // Mastercard Red
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withValues(alpha: 0.85), // Mastercard Orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real RuPay Badge
class _RupayLogo extends StatelessWidget {
  const _RupayLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: const Text(
        'RuPay',
        style: TextStyle(
          color: Color(0xFF0F4C81),
          fontWeight: FontWeight.w900,
          fontSize: 9,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
