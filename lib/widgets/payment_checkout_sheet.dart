import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../controller/order_controller.dart';
import '../controller/notification_controller.dart';
import '../controller/profile_controller.dart';
import '../services/email_service.dart';
import '../services/razorpay_service.dart';
import 'order_tracking_screen.dart';

class PaymentCheckoutSheet extends StatefulWidget {
  final OrderController ctrl;

  const PaymentCheckoutSheet({super.key, required this.ctrl});

  @override
  State<PaymentCheckoutSheet> createState() => _PaymentCheckoutSheetState();
}

class _PaymentCheckoutSheetState extends State<PaymentCheckoutSheet> {
  String _selectedMethod = 'UPI'; // UPI, Card, NetBanking, COD
  String _selectedUpiApp = 'Google Pay';
  
  final TextEditingController _upiIdCtrl = TextEditingController();
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _expiryCtrl = TextEditingController();
  final TextEditingController _cvvCtrl = TextEditingController();

  late RazorpayService _razorpayService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.init(
      onSuccess: _onRazorpaySuccess,
      onError: _onRazorpayError,
    );
  }

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) async {
    _finalizeOrder(
      paymentMethod: 'Razorpay Online (${response.paymentId ?? "UPI"})',
      paymentStatus: 'Paid',
    );
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isProcessing = false);
    Get.snackbar(
      'Payment Failed',
      response.message ?? 'Payment was cancelled or failed.',
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

    setState(() => _isProcessing = true);

    // If Cash on Delivery, place directly without Razorpay
    if (_selectedMethod == 'COD') {
      await _finalizeOrder(
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pay on Delivery',
      );
      return;
    }

    // If Online Payment (UPI, Card, NetBanking), trigger Razorpay Checkout
    String userEmail = 'customer@gmail.com';
    if (Get.isRegistered<ProfileController>() && ProfileController.to.emailCtrl.text.isNotEmpty) {
      userEmail = ProfileController.to.emailCtrl.text.trim();
    }

    final addr = widget.ctrl.deliveryAddress.value!;
    
    // Open Razorpay Native Payment Gateway
    if (RazorpayService.razorpayKeyId.contains('rzp_test_YOUR_KEY_HERE')) {
      // Demo simulation fallback if live key is not yet set by user
      await Future.delayed(const Duration(seconds: 2));
      await _finalizeOrder(
        paymentMethod: _selectedMethod == 'UPI'
            ? 'UPI ($_selectedUpiApp)'
            : _selectedMethod == 'Card'
                ? 'Credit/Debit Card'
                : 'Net Banking',
        paymentStatus: 'Paid',
      );
    } else {
      _razorpayService.openCheckout(
        amountInRupees: widget.ctrl.grandTotal,
        customerName: addr.name,
        customerPhone: addr.phone,
        customerEmail: userEmail,
        description: 'Kechi Poster Order Payment',
      );
    }
  }

  Future<void> _finalizeOrder({
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final success = await widget.ctrl.placeOrder(
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );

    if (mounted) setState(() => _isProcessing = false);

    if (success) {
      Get.back(); // close bottom sheet

      final latestOrder = widget.ctrl.orders.isNotEmpty ? widget.ctrl.orders.first : null;
      final trackingCode = latestOrder != null ? latestOrder['trackingCode'] ?? 'KCH-84920' : 'KCH-84920';

      // Push Notification
      if (Get.isRegistered<NotificationController>()) {
        NotificationController.to.addNotification(
          title: '🎉 Order Placed #$trackingCode',
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
        left: 24,
        right: 24,
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
                color: Colors.black.withOpacity(0.15),
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
                    "Checkout & Payment",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Secured by Razorpay Payment Gateway",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.2)),
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
                _buildMethodTab('UPI', Icons.qr_code_2_rounded, 'UPI / GPay'),
                const SizedBox(width: 10),
                _buildMethodTab('Card', Icons.credit_card_rounded, 'Cards'),
                const SizedBox(width: 10),
                _buildMethodTab('NetBanking', Icons.account_balance_rounded, 'NetBanking'),
                const SizedBox(width: 10),
                _buildMethodTab('COD', Icons.local_atm_rounded, 'Cash on Delivery'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Body based on selected method
          if (_selectedMethod == 'UPI') _buildUpiSection(),
          if (_selectedMethod == 'Card') _buildCardSection(),
          if (_selectedMethod == 'NetBanking') _buildNetBankingSection(),
          if (_selectedMethod == 'COD') _buildCodSection(),

          const SizedBox(height: 24),

          // Pay Button
          GestureDetector(
            onTap: _isProcessing ? null : _handlePayment,
            child: Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Connecting to Razorpay...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _selectedMethod == 'COD'
                            ? "Confirm Order (COD)  •  ₹${grandTotal.toInt()}"
                            : "Pay via Razorpay  •  ₹${grandTotal.toInt()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String id, IconData icon, String label) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B0000) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPI SECTION ─────────────────────────────────────────────────────────────
  Widget _buildUpiSection() {
    final upiApps = [
      {'name': 'Google Pay', 'icon': '🟢'},
      {'name': 'PhonePe',    'icon': '🟣'},
      {'name': 'Paytm',      'icon': '🔵'},
      {'name': 'BHIM UPI',   'icon': '🟠'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Popular UPI Apps (Razorpay Auto Launch)",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: upiApps.map((app) {
            final isAppSelected = _selectedUpiApp == app['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedUpiApp = app['name']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isAppSelected
                      ? const Color(0xFFC9A227).withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAppSelected
                        ? const Color(0xFFC9A227)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Text(app['icon']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      app['name']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isAppSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _upiIdCtrl,
            decoration: const InputDecoration(
              hintText: "Enter VPA ID (e.g. mobile@upi)",
              hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── CARD SECTION ────────────────────────────────────────────────────────────
  Widget _buildCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _cardNumberCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Card Number (16 digits)",
              hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: Icon(Icons.credit_card, size: 20, color: Colors.black54),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _expiryCtrl,
                  decoration: const InputDecoration(
                    hintText: "MM/YY",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _cvvCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "CVV (3 digits)",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── NET BANKING SECTION ──────────────────────────────────────────────────────
  Widget _buildNetBankingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Popular Bank", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['HDFC Bank', 'SBI Bank', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra']
              .map((bank) => Chip(
                    label: Text(bank, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.black.withOpacity(0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── COD SECTION ──────────────────────────────────────────────────────────────
  Widget _buildCodSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pay with Cash on Delivery",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  "Pay in cash or UPI directly when your poster package arrives at your doorstep.",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
