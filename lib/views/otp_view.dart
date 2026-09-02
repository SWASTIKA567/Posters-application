import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../themes/app_colors.dart';
import '../views/home_view.dart';
import '../controller/order_controller.dart';
import '../controller/wishlist_controller.dart';
import '../controller/upload_controller.dart';
import '../controller/profile_controller.dart';

enum OtpPurpose {
  signUp,
  passwordReset,
  verification,
}

class OtpView extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  final String? name;
  final String? password;
  final String? phone;

  const OtpView({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.signUp,
    this.name,
    this.password,
    this.phone,
  });

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> with TickerProviderStateMixin {
  static const int otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  late AnimationController _blob1, _blob2, _fadeCtrl, _pulseCtrl;
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startCountdown();

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _initAnimations() {
    _blob1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _blob2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _blob1.dispose();
    _blob2.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp {
    return _controllers.map((c) => c.text.trim()).join();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // User pasted code
      final clean = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < otpLength; i++) {
        if (i < clean.length) {
          _controllers[i].text = clean[i];
        }
      }
      if (clean.length >= otpLength) {
        _focusNodes[otpLength - 1].unfocus();
        _handleVerifyOtp();
      } else {
        _focusNodes[clean.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // If all filled, auto-verify
        if (_enteredOtp.length == otpLength) {
          _handleVerifyOtp();
        }
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final purposeStr = widget.purpose == OtpPurpose.passwordReset
          ? 'password_reset'
          : 'verification';

      final res = await ApiService.post('/auth/send-otp', {
        'email': widget.email,
        'purpose': purposeStr,
      });

      setState(() => _isResending = false);

      if (res['success'] == true) {
        Get.snackbar(
          '🔐 OTP Resent',
          'A new 6-digit code has been sent to ${widget.email}',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        _startCountdown();
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to resend OTP.';
        });
      }
    } catch (e) {
      setState(() {
        _isResending = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < otpLength) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.purpose == OtpPurpose.signUp) {
        // Step 1: Verify OTP code with backend
        final verifyRes = await ApiService.post('/auth/verify-otp', {
          'email': widget.email,
          'otp': otp,
          'purpose': 'verification',
        });

        if (verifyRes['success'] != true) {
          setState(() {
            _isLoading = false;
            _errorMessage = verifyRes['message'] ?? 'Invalid or expired OTP code.';
          });
          return;
        }

        // Step 2: Complete registration
        final res = await ApiService.post('/auth/register', {
          'name': widget.name,
          'email': widget.email,
          'password': widget.password,
          'phone': widget.phone ?? '',
        });

        setState(() => _isLoading = false);

        if (res['success'] == true && res['token'] != null) {
          await ApiService.setAuthToken(res['token']);
          _initAppControllers();

          Get.snackbar(
            '🎉 Welcome!',
            'Your account has been created successfully.',
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          Get.offAll(() => const HomeView());
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Registration failed. Please try again.';
          });
        }
      } else {
        // General OTP verification
        final purposeStr = widget.purpose == OtpPurpose.passwordReset
            ? 'password_reset'
            : 'verification';

        final res = await ApiService.post('/auth/verify-otp', {
          'email': widget.email,
          'otp': otp,
          'purpose': purposeStr,
        });

        setState(() => _isLoading = false);

        if (res['success'] == true) {
          Get.back(result: true);
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Invalid OTP. Please check the code.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _initAppControllers() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          _Blob(
            ctrl: _blob1,
            colors: [const Color(0xFFD32F2F), const Color(0xFFFF5722)],
            size: 260,
            top: -60,
            right: -60,
            opacity: 0.10,
            dx: 20,
            dy: -25,
          ),
          _Blob(
            ctrl: _blob2,
            colors: [const Color(0xFF00796B), const Color(0xFFFF5722)],
            size: 200,
            bottom: 60,
            left: -60,
            opacity: 0.08,
            dx: -20,
            dy: 20,
          ),

          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Icon badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGrad,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle with user email
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A).withOpacity(0.55),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit verification code to\n'),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 6-digit input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        otpLength,
                        (index) => _buildDigitBox(index),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message banner
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.30)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Verify Button
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: 1.0 + _pulseCtrl.value * 0.005,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleVerifyOtp,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGrad,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.30),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      widget.purpose == OtpPurpose.signUp
                                          ? 'Verify & Create Account →'
                                          : 'Verify Code →',
                                      style: const TextStyle(
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
                    const SizedBox(height: 24),

                    // Resend Timer & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _canResend
                              ? "Didn't receive code? "
                              : 'Resend code in ',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1A1A1A).withOpacity(0.50),
                          ),
                        ),
                        if (!_canResend)
                          Text(
                            '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _isResending ? null : _handleResendOtp,
                            child: _isResending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor:
                                          AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  )
                                : const Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primary
              : (controller.text.isNotEmpty
                  ? AppColors.primary.withOpacity(0.5)
                  : Colors.black.withOpacity(0.10)),
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) => _onDigitChanged(index, val),
        ),
      ),
    );
  }
}

// ─── BLOB ANIMATION HELPER ──────────────────────────────────────────────────
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
