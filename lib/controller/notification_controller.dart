import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String type; // 'order', 'promo', 'system'
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
    this.data,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type,
        'data': data,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.parse(map['timestamp'])
            : DateTime.now(),
        isRead: map['isRead'] ?? false,
        type: map['type'] ?? 'system',
        data: map['data'],
      );
}

class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

  // ── Notifications List ──────────────────────────────────────────────────────
  final RxList<AppNotification> notifications = <AppNotification>[
    AppNotification(
      id: '1',
      title: '🎉 Welcome to Kechi!',
      body: 'Explore high-resolution wall posters or upload your own photos to frame!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'system',
      isRead: false,
    ),
    AppNotification(
      id: '2',
      title: '🔥 Special Offer: 20% OFF',
      body: 'Use code KECHI20 at checkout for 20% discount on Matisse collection posters.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'promo',
      isRead: false,
    ),
    AppNotification(
      id: '3',
      title: '✨ Custom Print Ready',
      body: 'Your uploaded posters are printed on 300 GSM matte paper with rich pigment inks.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: 'system',
      isRead: true,
    ),
  ].obs;

  // ── Selected Filter ('all', 'order', 'promo', 'system') ──────────────────────
  final RxString selectedFilter = 'all'.obs;

  // ── Reactive Unread Counter ─────────────────────────────────────────────────
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // ── Filtered List ───────────────────────────────────────────────────────────
  RxList<AppNotification> get filteredNotifications {
    final filter = selectedFilter.value;
    if (filter == 'all') return notifications;
    return notifications.where((n) => n.type == filter).toList().obs;
  }

  // ── Add New Notification & Trigger Push Snackbar ───────────────────────────
  void addNotification({
    required String title,
    required String body,
    String type = 'order',
    Map<String, dynamic>? data,
    bool showPushBanner = true,
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${notifications.length}';
    final notif = AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      data: data,
    );

    // Insert at beginning of list
    notifications.insert(0, notif);
    notifications.refresh();

    // Show Push Banner Snackbar if enabled
    if (showPushBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          title,
          body,
          icon: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'order'
                  ? Icons.local_shipping_rounded
                  : type == 'promo'
                      ? Icons.local_offer_rounded
                      : Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          backgroundColor: const Color(0xFF8B0000),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          borderRadius: 16,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          boxShadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          dismissDirection: DismissDirection.horizontal,
          forwardAnimationCurve: Curves.easeOutBack,
        );
      });
    }
  }

  // ── Mark Single Notification as Read ────────────────────────────────────────
  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      notifications.refresh();
    }
  }

  // ── Mark All Notifications as Read ──────────────────────────────────────────
  void markAllAsRead() {
    bool updated = false;
    for (var n in notifications) {
      if (!n.isRead) {
        n.isRead = true;
        updated = true;
      }
    }
    if (updated) {
      notifications.refresh();
    }
  }

  // ── Delete Single Notification ──────────────────────────────────────────────
  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifications.refresh();
  }

  // ── Clear All Notifications ─────────────────────────────────────────────────
  void clearAll() {
    notifications.clear();
    notifications.refresh();
  }

  // ── Set Filter ──────────────────────────────────────────────────────────────
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
}
