import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poster_application/controller/cart_controller.dart';

import 'views/splash_view.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(CartController(), permanent: true);
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
