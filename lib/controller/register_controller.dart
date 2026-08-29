import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../views/home_view.dart';
import '../controller/order_controller.dart';
import '../controller/wishlist_controller.dart';
import '../controller/upload_controller.dart';
import '../controller/profile_controller.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final nameFocused = false.obs;
  final emailFocused = false.obs;
  final passwordFocused = false.obs;
  final confirmPasswordFocused = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    nameFocus.addListener(() => nameFocused.value = nameFocus.hasFocus);
    emailFocus.addListener(() => emailFocused.value = emailFocus.hasFocus);
    passwordFocus.addListener(
      () => passwordFocused.value = passwordFocus.hasFocus,
    );
    confirmPasswordFocus.addListener(
      () => confirmPasswordFocused.value = confirmPasswordFocus.hasFocus,
    );
  }

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  void toggleConfirmPasswordVisibility() =>
      obscureConfirmPassword.value = !obscureConfirmPassword.value;

  // ── Register User via REST API ──────────────────────────────────────────────
  Future<void> registerWithEmail() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      errorMessage.value = 'Please fill in all fields.';
      return;
    }

    if (password != confirmPassword) {
      errorMessage.value = 'Passwords do not match.';
      return;
    }

    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final res = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (res['success'] == true && res['token'] != null) {
        await ApiService.setAuthToken(res['token']);

        isLoading.value = false;
        _initControllers();
        Get.off(() => const HomeView());
      } else {
        isLoading.value = false;
        errorMessage.value = res['message'] ?? 'Registration failed. Try again.';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Register error: $e');
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
