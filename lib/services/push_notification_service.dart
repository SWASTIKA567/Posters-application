import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../controller/notification_controller.dart';
import '../services/api_service.dart';
import '../firebase_options.dart';

// Top-level background message handler (Runs in an isolated background thread)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Background Push Notification received: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kechi_order_updates', // id
    'Kechi Order & Delivery Updates', // title
    description: 'Notifications for order status changes and delivery tracking',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Request user permission (Critical for Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Push notification permission status: ${settings.authorizationStatus}');

      // 2. Initialize Flutter Local Notifications for Foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
          // If payload contains order info, navigate to orders screen
        },
      );

      // 3. Create the Android High-Importance Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 4. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground Push Notification: ${message.notification?.title}');

        final title = message.notification?.title ?? message.data['title'] ?? 'Kechi Update';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final type = message.data['type'] ?? 'order';

        // Add to NotificationController (persists in SharedPreferences)
        if (Get.isRegistered<NotificationController>()) {
          NotificationController.to.addNotification(
            title: title,
            body: body,
            type: type,
            data: message.data,
            showPushBanner: false, // We use local system notification instead
          );
        }

        // Show native system status bar notification
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null && !kIsWeb) {
          _localNotifications.show(
            id: notification.hashCode,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 5. App opened from background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 App opened via notification: ${message.data}');
      });

      // 6. App launched from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App launched from terminated state via notification: ${initialMessage.data}');
      }

      // 7. Get and sync FCM Device Token
      await syncFcmToken();

      // 8. Listen to Token Refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationService initialization notice: $e');
    }
  }

  /// Fetches FCM token and uploads to backend
  static Future<String?> syncFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Device Token: $token');
        await sendTokenToBackend(token);
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Sends the phone's FCM push token to the backend
  static Future<void> sendTokenToBackend(String token) async {
    if (!ApiService.isAuthenticated) return;
    try {
      await ApiService.patch('/users/fcm-token', {
        'fcmToken': token,
      });
      debugPrint('✅ FCM token synced to user profile on backend');
    } catch (e) {
      debugPrint('Backend token sync notice: $e');
    }
  }
}
