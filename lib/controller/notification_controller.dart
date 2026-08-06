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
}

class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

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

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String body,
    String type = 'order',
    Map<String, dynamic>? data,
    bool showPushBanner = true,
  }) {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
    );

    notifications.insert(0, notif);

    if (showPushBanner) {
      Get.snackbar(
        title,
        body,
        icon: Icon(
          type == 'order'
              ? Icons.local_shipping_rounded
              : type == 'promo'
                  ? Icons.local_offer_rounded
                  : Icons.notifications_active_rounded,
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifications.refresh();
    }
  }

  void markAllAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifications.refresh();
  }

  void clearAll() {
    notifications.clear();
  }
}
