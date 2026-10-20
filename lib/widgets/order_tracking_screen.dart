import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';
import '../themes/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? 'Pending').toString();
    final waybill = (order['waybillNumber'] ?? order['trackingCode'] ?? 'SFX849201824').toString();
    final courierPartner = (order['courierPartner'] ?? 'Shadowfax Express').toString();
    final trackingUrl = (order['trackingUrl'] ?? 'https://tracker.shadowfax.in/track?orderId=$waybill').toString();
    final addressMap = order['deliveryAddress'] as Map<String, dynamic>?;

    final steps = [
      {'title': 'Order Placed',        'desc': 'Your order has been received.',             'time': 'Step 1'},
      {'title': 'Printing & Quality', 'desc': 'Kechi high-resolution poster print in progress.', 'time': 'Step 2'},
      {'title': 'Shipped & In Transit','desc': 'Handed over to $courierPartner.',          'time': 'Step 3'},
      {'title': 'Out for Delivery',    'desc': 'Shadowfax rider is out for delivery.',      'time': 'Step 4'},
      {'title': 'Delivered',           'desc': 'Package delivered to recipient.',            'time': 'Step 5'},
    ];

    int currentStepIndex = 1;
    final sLower = status.toLowerCase();
    if (sLower == 'confirmed') currentStepIndex = 1;
    if (sLower == 'processing') currentStepIndex = 2;
    if (sLower == 'shipped') currentStepIndex = 3;
    if (sLower == 'delivered') currentStepIndex = 4;
    if (sLower == 'cancelled') currentStepIndex = -1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        title: const Text(
          "Order Tracking",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking Code Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            courierPartner.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "SHADOWFAX WAYBILL (AWB)",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        waybill,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: waybill));
                          Get.snackbar(
                            'AWB Copied!',
                            'Shadowfax Waybill #$waybill copied to clipboard.',
                            backgroundColor: Colors.black,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Express Delivery (2-4 Days)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: trackingUrl));
                          Get.snackbar(
                            'Tracking Link Copied',
                            'Paste into your browser to track live on Shadowfax.',
                            backgroundColor: Colors.black,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Track Online",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B0000),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Header
            const Text(
              "Delivery Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Timeline Steps Widget
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: sLower == 'cancelled'
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "This order has been cancelled.",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length,
                      itemBuilder: (_, idx) {
                        final step = steps[idx];
                        final isCompleted = idx <= currentStepIndex;
                        final isCurrent = idx == currentStepIndex;
                        final isLast = idx == steps.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline Indicator Column
                              Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? const Color(0xFF8B0000)
                                          : Colors.black.withOpacity(0.08),
                                      border: isCurrent
                                          ? Border.all(
                                              color: const Color(0xFFC9A227),
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                          : Text(
                                              "${idx + 1}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black.withOpacity(0.4),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        color: idx < currentStepIndex
                                            ? const Color(0xFF8B0000)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Text Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: isCompleted ? Colors.black87 : Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step['desc']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Delivery Address Card
            if (addressMap != null) ...[
              const Text(
                "Shipping Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF8B0000), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressMap['name'] ?? 'Recipient',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${addressMap['addressLine'] ?? ''}, ${addressMap['city'] ?? ''} - ${addressMap['pincode'] ?? ''}",
                            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2-Hour Cancellation Window / Policy Info
            if (sLower == 'pending') ...[
              Builder(
                builder: (context) {
                  DateTime? orderTime;
                  try {
                    if (order['createdAt'] != null) {
                      orderTime = DateTime.parse(order['createdAt'].toString());
                    }
                  } catch (_) {}

                  final diffHours = orderTime != null
                      ? DateTime.now().difference(orderTime).inHours
                      : 0;

                  final canCancel = diffHours < 2;

                  if (canCancel) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: Colors.red.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Free cancellation available within 2 hours of order placement.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Cancel Order?'),
                                    content: const Text('Are you sure you want to cancel this poster order?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Keep Order')),
                                      ElevatedButton(
                                        onPressed: () => Get.back(result: true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final orderId = order['orderId'] ?? order['_id'];
                                  if (orderId != null) {
                                    await OrderController.to.cancelOrder(orderId.toString());
                                    Get.back();
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Cancel Order', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Order is now in high-definition printing production. Custom items cannot be cancelled after 2 hours.",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ] else if (sLower == 'delivered') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 18, color: Colors.green.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Order Delivered! For any defect or damage, report to support.kechi@gmail.com within 24 hours for a 100% Free Replacement.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Support & Contact Button
            GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kechi Customer Support",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Have a question about your order or need a free replacement for a defective print?",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.email_outlined, color: Color(0xFF8B0000)),
                              SizedBox(width: 10),
                              Text(
                                "support.kechi@gmail.com",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "• Operating hours: Mon - Sat, 10 AM - 7 PM\n• Please mention your Order ID for faster resolution.",
                          style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.headset_mic_outlined, color: Color(0xFF8B0000), size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Contact Kechi Support",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
