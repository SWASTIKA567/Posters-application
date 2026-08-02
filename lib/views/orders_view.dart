import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';
import '../themes/app_colors.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  // ── Date Formatting (ISO 8601 string from MongoDB) ─────────────────────────
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
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
    } catch (_) {
      return 'Recent';
    }
  }

  // ── Poster Thumbnail ──────────────────────────────────────────────────────
  Widget _buildPosterThumbnail(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: path.startsWith('http')
          ? Image.network(
              path,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            )
          : Image.asset(
              path,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            ),
    );
  }

  Widget _imageFallback() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.black38, size: 20),
      );

  // ── Status Color & Icon ────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':    return const Color(0xFFF59E0B);
      case 'confirmed':  return const Color(0xFF3B82F6);
      case 'processing': return const Color(0xFF8B5CF6);
      case 'shipped':    return const Color(0xFF06B6D4);
      case 'delivered':  return const Color(0xFF10B981);
      case 'cancelled':  return const Color(0xFFEF4444);
      default:           return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':    return Icons.hourglass_empty_rounded;
      case 'confirmed':  return Icons.check_circle_outline_rounded;
      case 'processing': return Icons.settings_outlined;
      case 'shipped':    return Icons.local_shipping_outlined;
      case 'delivered':  return Icons.inventory_2_outlined;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.info_outline;
    }
  }

  // ── Timeline Steps ─────────────────────────────────────────────────────────
  static const _timelineSteps = [
    {'label': 'Pending',    'icon': Icons.hourglass_empty_rounded},
    {'label': 'Confirmed',  'icon': Icons.check_circle_outline_rounded},
    {'label': 'Processing', 'icon': Icons.settings_outlined},
    {'label': 'Shipped',    'icon': Icons.local_shipping_outlined},
    {'label': 'Delivered',  'icon': Icons.inventory_2_outlined},
  ];

  Widget _buildStatusTimeline(String currentStatus) {
    if (currentStatus.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              'Order Cancelled',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final steps = _timelineSteps;
    final currentIdx = steps.indexWhere(
      (s) => (s['label'] as String).toLowerCase() == currentStatus.toLowerCase(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (i) {
              final isDone = i <= currentIdx;
              final isActive = i == currentIdx;
              final color = isDone ? _statusColor(currentStatus) : Colors.black12;
              final isLast = i == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: isActive ? 32 : 26,
                      height: isActive ? 32 : 26,
                      decoration: BoxDecoration(
                        color: isDone ? color : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? color : Colors.black12,
                          width: isActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        steps[i]['icon'] as IconData,
                        color: isDone ? Colors.white : Colors.black26,
                        size: isActive ? 16 : 13,
                      ),
                    ),

                    // Connector Line
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: i < currentIdx
                                ? LinearGradient(
                                    colors: [
                                      _statusColor(currentStatus),
                                      _statusColor(currentStatus).withOpacity(.4),
                                    ],
                                  )
                                : null,
                            color: i >= currentIdx ? Colors.black12 : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          // Step Labels
          Row(
            children: List.generate(steps.length, (i) {
              final isDone = i <= currentIdx;
              return Expanded(
                child: Text(
                  (steps[i]['label'] as String).split('').take(3).join() + '.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? _statusColor(currentStatus) : Colors.black26,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
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
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: () => ctrl.fetchOrders(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Orders List or Empty State ─────────────────────────────────
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
                            "Your placed orders will show up here.",
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.primaryGrad),
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
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ctrl.fetchOrders(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: orderList.length,
                    itemBuilder: (context, index) {
                      final order = orderList[index];

                      final orderId = (order['_id'] ?? order['orderId'] ?? '') as String;
                      final shortOrderId = orderId.length > 8
                          ? orderId.substring(0, 8).toUpperCase()
                          : orderId.toUpperCase();

                      final createdAt = order['createdAt'];
                      final status = (order['status'] as String? ?? 'Pending');
                      final items = order['items'] as List<dynamic>? ?? [];

                      // Support both 'address' and 'deliveryAddress' keys
                      final address =
                          (order['deliveryAddress'] ?? order['address'])
                              as Map<String, dynamic>? ??
                          {};
                      final grandTotal =
                          (order['grandTotal'] ?? 0.0).toDouble();
                      final paymentMethod =
                          order['paymentMethod'] as String? ??
                              'Cash on Delivery';

                      final name = address['name'] ?? '';
                      final phone = address['phone'] ?? '';
                      final addressLine = address['addressLine'] ?? '';
                      final city = address['city'] ?? '';
                      final state = address['state'] ?? '';
                      final pincode = address['pincode'] ?? '';
                      final fullAddress =
                          '$addressLine, $city, $state - $pincode';

                      final statusColor = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Order Header ─────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #$shortOrderId',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
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
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withOpacity(.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _statusIcon(status),
                                          color: statusColor,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Visual Status Timeline ───────────────────
                            _buildStatusTimeline(status),

                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 0.5),

                            // ── Items List ───────────────────────────────
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, itemIdx) {
                                final item =
                                    items[itemIdx] as Map<String, dynamic>;
                                final imageUrl =
                                    item['imageUrl'] as String? ?? '';
                                final size = item['size'] as String? ?? 'A4';
                                final quantity = item['quantity'] as int? ?? 1;
                                final totalPrice =
                                    (item['totalPrice'] ?? 0.0).toDouble();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      _buildPosterThumbnail(imageUrl),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFF5F5F5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFE0E0E0),
                                                        width: 0.5),
                                                  ),
                                                  child: Text(
                                                    size,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Qty: $quantity',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black
                                                        .withOpacity(.55),
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

                            // ── Footer: Address + Total ──────────────────
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                color: Colors.black
                                                    .withOpacity(.6),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.payments_outlined,
                                            size: 13,
                                            color: Color(0xFF00796B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            paymentMethod,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF00796B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Total: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  Colors.black.withOpacity(.5),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          ShaderMask(
                                            shaderCallback: (b) =>
                                                const LinearGradient(
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
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
