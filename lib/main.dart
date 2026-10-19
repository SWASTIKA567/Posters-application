import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'controller/order_controller.dart';
import 'controller/wishlist_controller.dart';
import 'controller/upload_controller.dart';
import 'controller/profile_controller.dart';
import 'controller/notification_controller.dart';
import 'controller/navigation_controller.dart';
import 'controller/home_controller.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with current platform options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background push message listener
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Controllers
  Get.put(NavigationController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(WishlistController(), permanent: true);
  Get.put(UploadController(), permanent: true);
  Get.put(OrderController(), permanent: true);
  Get.put(ProfileController(), permanent: true);

  // Initialize Push Notifications
  await PushNotificationService.initialize();

  runApp(const KechiApp());
}

class KechiApp extends StatelessWidget {
  const KechiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kechi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        fontFamily: 'SpaceGrotesk',
      ),
      home: const SplashScreen(),
    );
  }
}
