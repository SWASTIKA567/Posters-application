import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/notification_controller.dart';
import '../themes/app_colors.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final notifCtrl = NotificationController.to;

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
          "Notifications",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF8B0000), size: 20),
            tooltip: "Mark all as read",
            onPressed: () {
              notifCtrl.markAllAsRead();
              Get.snackbar(
                'Done',
                'All notifications marked as read.',
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Push Notification Test Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF8B0000).withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Color(0xFF8B0000), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Push Notifications Active",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      notifCtrl.addNotification(
                        title: '🚚 Order Update #KCH-84920',
                        body: 'Your custom poster print is out for delivery! Rider arriving today.',
                        type: 'order',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Test Push Alert",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: Obx(() {
                final list = notifCtrl.notifications;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 32,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "No notifications yet",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "We'll notify you about orders and special discounts.",
                          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = list[index];

                    return GestureDetector(
                      onTap: () => notifCtrl.markAsRead(item.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: item.isRead ? Colors.white : const Color(0xFF8B0000).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isRead
                                ? Colors.black.withOpacity(0.06)
                                : const Color(0xFF8B0000).withOpacity(0.2),
                            width: item.isRead ? 1 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.type == 'order'
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : item.type == 'promo'
                                        ? const Color(0xFFC9A227).withOpacity(0.15)
                                        : const Color(0xFF8B0000).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.type == 'order'
                                    ? Icons.local_shipping_rounded
                                    : item.type == 'promo'
                                        ? Icons.local_offer_rounded
                                        : Icons.notifications_active_rounded,
                                size: 20,
                                color: item.type == 'order'
                                    ? const Color(0xFF10B981)
                                    : item.type == 'promo'
                                        ? const Color(0xFFB8860B)
                                        : const Color(0xFF8B0000),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF8B0000),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.6),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(item.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
