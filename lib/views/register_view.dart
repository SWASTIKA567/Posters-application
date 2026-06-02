import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controller/register_controller.dart';
import '../themes/app_colors.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final RegisterController _ctrl = Get.put(RegisterController());

  late AnimationController _blob1, _blob2, _blob3;
  late AnimationController _fadeCtrl, _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _blob1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _blob2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _blob3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blob1.dispose();
    _blob2.dispose();
    _blob3.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _Blob(
            ctrl: _blob1,
            colors: AppColors.logoGrad,
            size: 260,
            top: -100,
            left: -80,
            opacity: 0.30,
            dx: 20,
            dy: -30,
          ),
          _Blob(
            ctrl: _blob2,
            colors: AppColors.logoGrad,
            size: 200,
            bottom: 100,
            right: -60,
            opacity: 0.22,
            dx: -20,
            dy: 20,
          ),
          _Blob(
            ctrl: _blob3,
            colors: [const Color(0xFF10B981), const Color(0xFF3B82F6)],
            size: 150,
            top: 300,
            left: -30,
            opacity: 0.15,
            dx: 15,
            dy: -20,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeCtrl,
                curve: Curves.easeOut,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildHeading(),
                    const SizedBox(height: 24),
                    _buildForm(),
                    const SizedBox(height: 20),
                    Obx(
                      () => _ctrl.errorMessage.value != null
                          ? Column(
                              children: [
                                _buildError(),
                                const SizedBox(height: 12),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    _buildCTA(),
                    const SizedBox(height: 18),
                    _buildSignIn(),
                    const SizedBox(height: 16),
                    _buildTerms(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ERROR BANNER ──────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _ctrl.errorMessage.value ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOGO ──────────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) =>
              const LinearGradient(colors: AppColors.logoGrad).createShader(b),
          child: const Text(
            'postly.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _pulseCtrl.value * 0.02,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(
                          0.5 + _pulseCtrl.value * 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'create · express · vibe',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── HEADING ───────────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            children: [
              const TextSpan(text: 'Join the\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: AppColors.logoGrad,
                  ).createShader(b),
                  child: const Text(
                    'poster community.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create your account and start making posters that slap.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0x73FFFFFF), height: 1.5),
        ),
      ],
    );
  }

  // ── FORM ──────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InputField(
            label: 'full name',
            hint: 'your name',
            controller: _ctrl.nameController,
            focusNode: _ctrl.nameFocus,
            isFocused: _ctrl.nameFocused.value,
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: 'email address',
            hint: 'you@postly.app',
            controller: _ctrl.emailController,
            focusNode: _ctrl.emailFocus,
            isFocused: _ctrl.emailFocused.value,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: 'password',
            hint: '••••••••',
            controller: _ctrl.passwordController,
            focusNode: _ctrl.passwordFocus,
            isFocused: _ctrl.passwordFocused.value,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _ctrl.obscurePassword.value,
            suffixIcon: _ctrl.obscurePassword.value
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixTap: _ctrl.togglePasswordVisibility,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: 'confirm password',
            hint: '••••••••',
            controller: _ctrl.confirmPasswordController,
            focusNode: _ctrl.confirmPasswordFocus,
            isFocused: _ctrl.confirmPasswordFocused.value,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _ctrl.obscureConfirmPassword.value,
            suffixIcon: _ctrl.obscureConfirmPassword.value
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixTap: _ctrl.toggleConfirmPasswordVisibility,
          ),
        ],
      ),
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────────
  Widget _buildCTA() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Transform.scale(
        scale: 1.0 + _pulseCtrl.value * 0.008,
        child: Obx(
          () => GestureDetector(
            onTap: _ctrl.isLoading.value ? null : _ctrl.registerWithEmail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: AppColors.primaryGrad),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _ctrl.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'create account →',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SIGN IN ───────────────────────────────────────────────────────────────────
  Widget _buildSignIn() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35)),
        children: [
          const TextSpan(text: 'already have an account? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const Text(
                'sign in',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TERMS ─────────────────────────────────────────────────────────────────────
  Widget _buildTerms() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.2),
          height: 1.6,
        ),
        children: const [
          TextSpan(text: 'by signing up you agree to our '),
          TextSpan(
            text: 'terms',
            style: TextStyle(color: Color(0x99A78BFA)),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'privacy policy',
            style: TextStyle(color: Color(0x99A78BFA)),
          ),
        ],
      ),
    );
  }
}

// ─── BLOB ─────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final AnimationController ctrl;
  final List<Color> colors;
  final double size, opacity, dx, dy;
  final double? top, left, right, bottom;

  const _Blob({
    required this.ctrl,
    required this.colors,
    required this.size,
    required this.opacity,
    required this.dx,
    required this.dy,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final t = (math.sin(ctrl.value * math.pi * 2) + 1) / 2;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(dx * t, dy * t),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [colors[0], colors[1].withOpacity(0.1)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── INPUT FIELD ──────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF7C3AED).withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: isFocused ? 1.5 : 1,
            ),
            color: isFocused
                ? const Color(0xFF7C3AED).withOpacity(0.07)
                : Colors.white.withOpacity(0.05),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: Colors.white.withOpacity(0.35),
              ),
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(
                        suffixIcon,
                        size: 18,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
