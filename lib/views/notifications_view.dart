import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/notification_controller.dart';
import '../themes/app_colors.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
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
        leading: Center(
          child: GestureDetector(
            onTap: () => Get.back(),
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
          "Notifications",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            onSelected: (val) {
              if (val == 'read_all') {
                notifCtrl.markAllAsRead();
                Get.snackbar(
                  'Marked as Read',
                  'All notifications marked as read.',
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF8B0000),
                  colorText: Colors.white,
                );
              } else if (val == 'clear_all') {
                notifCtrl.clearAll();
                Get.snackbar(
                  'Cleared',
                  'All notifications cleared.',
                  duration: const Duration(seconds: 2),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF8B0000)),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear all notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Filter Tabs (All, Orders, Offers)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Obx(() {
                final current = notifCtrl.selectedFilter.value;
                return Row(
                  children: [
                    _buildFilterChip(notifCtrl, 'all', 'All', current),
                    const SizedBox(width: 8),
                    _buildFilterChip(notifCtrl, 'order', 'Orders', current),
                    const SizedBox(width: 8),
                    _buildFilterChip(notifCtrl, 'promo', 'Offers', current),
                  ],
                );
              }),
            ),

            // Notifications List
            Expanded(
              child: Obx(() {
                final list = notifCtrl.filteredNotifications;

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

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        notifCtrl.deleteNotification(item.id);
                      },
                      child: GestureDetector(
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

  Widget _buildFilterChip(NotificationController ctrl, String id, String label, String current) {
    final isSelected = id == current;
    return GestureDetector(
      onTap: () => ctrl.setFilter(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B0000) : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
