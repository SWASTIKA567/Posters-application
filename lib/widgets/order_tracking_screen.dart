import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':    return const Color(0xFFF59E0B);
      case 'confirmed':  return const Color(0xFF3B82F6);
      case 'processing': return const Color(0xFF8B0000);
      case 'shipped':    return const Color(0xFF06B6D4);
      case 'delivered':  return const Color(0xFF10B981);
      case 'cancelled':  return const Color(0xFFEF4444);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? 'Pending').toString();
    final trackingCode = (order['trackingCode'] ?? 'KCH-849201').toString();
    final addressMap = order['deliveryAddress'] as Map<String, dynamic>?;
    final itemsList = order['items'] as List?;
    final grandTotal = order['grandTotal'] ?? 0;
    final paymentMethod = order['paymentMethod'] ?? 'Cash on Delivery';

    final steps = [
      {'title': 'Order Placed',        'desc': 'Your order has been received.',             'time': 'Step 1'},
      {'title': 'Printing & Quality', 'desc': 'Kechi high-resolution poster print in progress.', 'time': 'Step 2'},
      {'title': 'Shipped & In Transit','desc': 'Handed over to courier partner.',          'time': 'Step 3'},
      {'title': 'Out for Delivery',    'desc': 'Rider is on the way to your address.',      'time': 'Step 4'},
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Get.back(),
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
                      const Text(
                        "TRACKING NUMBER",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        trackingCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: trackingCode));
                          Get.snackbar(
                            'Copied!',
                            'Tracking code copied to clipboard.',
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
                  const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Estimated Delivery: 2 - 4 Business Days",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

            // Support & Contact Button
            GestureDetector(
              onTap: () {
                Get.snackbar(
                  'Kechi Support',
                  'Support helpline: +91 1800-KECHI-HELP',
                  backgroundColor: const Color(0xFF8B0000),
                  colorText: Colors.white,
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
