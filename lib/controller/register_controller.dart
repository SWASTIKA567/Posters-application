import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/home_view.dart';
import '../controller/order_controller.dart';
import '../controller/wishlist_controller.dart';
import '../controller/upload_controller.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Update display name in Auth
      await user.updateDisplayName(name);

      // ── Save user profile to Firestore ────────────────────────────────
      // This creates users/{uid} doc so you can see every user in console
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'photoUrl': user.photoURL ?? '',
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge so existing data isn't wiped

      isLoading.value = false;
      _initControllers();
      Get.off(() => const HomeView());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Something went wrong. Please try again.';
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
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
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
