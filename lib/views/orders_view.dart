import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';
import '../themes/app_colors.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  // Date formatting helper
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Recent';
    final dt = timestamp.toDate();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute $period';
  }

  Widget _buildPosterThumbnail(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: path.startsWith('http')
          ? Image.network(
              path,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.black.withOpacity(.08),
                child: const Icon(Icons.image_outlined, color: Colors.black38, size: 20),
              ),
            )
          : Image.asset(
              path,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.black.withOpacity(.08),
                child: const Icon(Icons.image_outlined, color: Colors.black38, size: 20),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: AppColors.logoGrad,
                    ).createShader(b),
                    child: const Text(
                      "Order History",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders list or empty state
            Expanded(
              child: Obx(() {
                final orderList = ctrl.orders;

                if (orderList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: Colors.black.withOpacity(.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No orders yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your placed orders will show up here. Place your first order to get started!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.primaryGrad),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Browse Posters",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: orderList.length,
                  itemBuilder: (context, index) {
                    final order = orderList[index];
                    final orderId = order['orderId'] as String? ?? '';
                    final shortOrderId = orderId.length > 8
                        ? orderId.substring(0, 8).toUpperCase()
                        : orderId.toUpperCase();
                    final createdAt = order['createdAt'] as Timestamp?;
                    final status = order['status'] as String? ?? 'placed';
                    final items = order['items'] as List<dynamic>? ?? [];
                    final address = order['address'] as Map<String, dynamic>? ?? {};
                    final grandTotal = (order['grandTotal'] ?? 0.0).toDouble();
                    final paymentMethod = order['paymentMethod'] as String? ?? 'Cash on Delivery';

                    // Address formatting
                    final name = address['name'] ?? '';
                    final phone = address['phone'] ?? '';
                    final addressLine = address['addressLine'] ?? '';
                    final city = address['city'] ?? '';
                    final state = address['state'] ?? '';
                    final pincode = address['pincode'] ?? '';
                    final fullAddress = '$addressLine, $city, $state - $pincode';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #$shortOrderId',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withOpacity(.4),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 0.5),

                          // Items List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, itemIdx) {
                              final item = items[itemIdx] as Map<String, dynamic>;
                              final imageUrl = item['imageUrl'] as String? ?? '';
                              final size = item['size'] as String? ?? 'A4';
                              final quantity = item['quantity'] as int? ?? 1;
                              final totalPrice = (item['totalPrice'] ?? 0.0).toDouble();

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    _buildPosterThumbnail(imageUrl),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                                                ),
                                                child: Text(
                                                  size,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Qty: $quantity',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black.withOpacity(.55),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹${totalPrice.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, thickness: 0.5),

                          // Collapsible/Simple Shipping address and pricing footer
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$name • $phone',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fullAddress,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black.withOpacity(.6),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      paymentMethod,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF00796B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Total: ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black.withOpacity(.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        ShaderMask(
                                          shaderCallback: (b) => const LinearGradient(
                                            colors: AppColors.primaryGrad,
                                          ).createShader(b),
                                          child: Text(
                                            '₹${grandTotal.toInt()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
