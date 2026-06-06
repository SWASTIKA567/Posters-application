import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controller/order_controller.dart';

import 'views/splash_view.dart';
import 'package:get/get.dart';
import 'controller/wishlist_controller.dart';
import 'controller/upload_controller.dart';
import 'controller/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(WishlistController(), permanent: true);
  Get.put(UploadController(), permanent: true);
  Get.put(OrderController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  runApp(const PostlyApp());
}

class PostlyApp extends StatelessWidget {
  const PostlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Postly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        fontFamily: 'SpaceGrotesk',
      ),
      home: const SplashScreen(),
    );
  }
}
