import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/order_controller.dart';
import '../controller/wishlist_controller.dart';
import '../views/home_view.dart';
import '../controller/upload_controller.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final emailFocused = false.obs;
  final passwordFocused = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    emailFocus.addListener(() => emailFocused.value = emailFocus.hasFocus);
    passwordFocus.addListener(
      () => passwordFocused.value = passwordFocus.hasFocus,
    );
  }

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  // ── Email & Password Login ────────────────────────────────────────────────
  Future<void> loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Please fill in all fields.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // ── Update lastLoginAt in Firestore ───────────────────────────────
      // Also creates the user doc if somehow missing (e.g. old accounts)
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? email,
        'photoUrl': user.photoURL ?? '',
        'provider': 'email',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge = never overwrite existing fields

      isLoading.value = false;
      _initControllers();
      Get.off(() => const HomeView());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Something went wrong. Please try again.';
      debugPrint('Login error: $e');
    }
  }

  void _initControllers() {
    if (!Get.isRegistered<WishlistController>()) {
      Get.put(WishlistController(), permanent: true);
    }
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }
    if (!Get.isRegistered<UploadController>()) {
      Get.put(UploadController(), permanent: true);
    }
  }

  // ── Error Mapping ─────────────────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }
}
