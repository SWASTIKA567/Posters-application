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

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    errorMessage.value = null;

    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final String? idToken = googleUser.authentication.idToken;

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
          ? 'Google Sign-In configuration notice: SHA-1 fingerprint needed in Firebase Console.'
          : err;
      debugPrint('Google sign-in error: $e');
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
