import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus    = FocusNode();
  final passwordFocus = FocusNode();

  bool isLoading       = false;
  bool obscurePassword = true;
  bool emailFocused    = false;
  bool passwordFocused = false;
  String? errorMessage;

  void togglePasswordVisibility(VoidCallback refresh) {
    obscurePassword = !obscurePassword;
    refresh();
  }

  // ── Email & Password Login ──────────────────────────────────────────────────
  Future<void> loginWithEmail(VoidCallback refresh, VoidCallback onSuccess) async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      errorMessage = 'Please fill in all fields.';
      refresh();
      return;
    }

    isLoading    = true;
    errorMessage = null;
    refresh();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isLoading = false;
      refresh();
      onSuccess();
    } on FirebaseAuthException catch (e) {
      isLoading    = false;
      errorMessage = _mapError(e.code);
      refresh();
    }
  }

  // ── Google Login ────────────────────────────────────────────────────────────
  Future<void> loginWithGoogle(VoidCallback refresh, VoidCallback onSuccess) async {
    isLoading    = true;
    errorMessage = null;
    refresh();

    try {
      // TODO: add google_sign_in package and implement
      // final googleUser = await GoogleSignIn().signIn();
      // final googleAuth = await googleUser!.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // await _auth.signInWithCredential(credential);
      isLoading = false;
      refresh();
      onSuccess();
    } catch (e) {
      isLoading    = false;
      errorMessage = 'Google sign-in failed. Try again.';
      refresh();
    }
  }

  // ── Error Mapping ───────────────────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with this email.';
      case 'wrong-password':    return 'Incorrect password. Try again.';
      case 'invalid-email':     return 'Please enter a valid email.';
      case 'user-disabled':     return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default:                  return 'Something went wrong. Please try again.';
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
  }
}