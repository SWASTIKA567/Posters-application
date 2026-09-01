import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../controller/order_controller.dart';
import '../controller/wishlist_controller.dart';
import '../views/home_view.dart';
import '../controller/upload_controller.dart';
import '../controller/profile_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
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

  // ── Email & Password Login via REST API ────────────────────────────────────
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
      final res = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (res['success'] == true && res['token'] != null) {
        // Save JWT token in ApiService & SharedPreferences
        await ApiService.setAuthToken(res['token']);

        isLoading.value = false;
        _initControllers();
        Get.off(() => const HomeView());
      } else {
        isLoading.value = false;
        errorMessage.value = res['message'] ?? 'Login failed. Try again.';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Login error: $e');
    }
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    errorMessage.value = null;

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled Google Sign-In sheet
        isGoogleLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final res = await ApiService.post('/auth/google', {
        'idToken': idToken,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'picture': googleUser.photoUrl,
      });

      if (res['success'] == true && res['token'] != null) {
        await ApiService.setAuthToken(res['token']);
        isGoogleLoading.value = false;
        _initControllers();
        Get.off(() => const HomeView());
      } else {
        isGoogleLoading.value = false;
        errorMessage.value = res['message'] ?? 'Google sign-in failed.';
      }
    } catch (e) {
      isGoogleLoading.value = false;
      final err = e.toString().replaceAll('Exception: ', '');
      if (err.toLowerCase().contains('cancel') || err.toLowerCase().contains('canceled')) {
        return; // User simply closed the picker
      }
      errorMessage.value = err.contains('ApiException: 10')
          ? 'Google Sign-In notice: SHA-1 fingerprint needs to be added in Firebase Console.'
          : err;
      debugPrint('Google sign-in error: $e');
    }
  }

  // ── Forgot Password / OTP ──────────────────────────────────────────────────
  final isOtpSending = false.obs;
  final isResettingPassword = false.obs;

  Future<bool> sendForgotPasswordOtp(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar('Email Required', 'Please enter your registered email address.');
      return false;
    }
    try {
      isOtpSending.value = true;
      final res = await ApiService.post('/auth/forgot-password', {
        'email': email.trim(),
      });
      isOtpSending.value = false;
      if (res['success'] == true) {
        Get.snackbar(
          '🔐 OTP Sent',
          'A 6-digit verification code has been sent to $email',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      isOtpSending.value = false;
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (otp.trim().isEmpty || newPassword.trim().isEmpty) {
      Get.snackbar('Missing Fields', 'Please enter the OTP and your new password.');
      return false;
    }
    try {
      isResettingPassword.value = true;
      final res = await ApiService.post('/auth/reset-password', {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword.trim(),
      });
      isResettingPassword.value = false;
      if (res['success'] == true) {
        Get.snackbar(
          '🎉 Password Reset',
          'Your password has been reset successfully! You can now log in.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar('Reset Failed', res['message'] ?? 'Invalid or expired OTP');
        return false;
      }
    } catch (e) {
      isResettingPassword.value = false;
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
      return false;
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
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: true);
    profile.loadProfile();
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
