import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poster_application/views/home_view.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // ── Email & Password Login ──────────────────────────────────────────────────
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isLoading.value = false;
      Get.offAll(() => const HomeView());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _mapError(e.code);
    }
  }

  // ── Google Login ────────────────────────────────────────────────────────────

  // ── Error Mapping ───────────────────────────────────────────────────────────
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
