import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'login_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _kDrop;
  late final Animation<double> _kFade;
  late final Animation<double> _echiSlide;
  late final Animation<double> _echiFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // K drops with bouncy elastic overshoot — first 60 % of timeline
    _kDrop = Tween<double>(begin: -260, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // K fades in fast so you see it falling
    _kFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // "echi" slides in from left once K has landed
    _echiSlide = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );

    // "echi" fades in together with the slide
    _echiFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );

    // Tagline appears last
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Get.off(
        () => const LoginScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Use a full-screen Stack with Clip.none so the K can
          // genuinely travel from above the screen into its final position.
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // White background fill (safety net)
              Container(color: Colors.white, width: size.width, height: size.height),

              // ── K  ────────────────────────────────────────────────────────
              // Positioned at horizontal centre, vertically centred - 10 px
              // and shifted UP by _kDrop (starts at -260, ends at 0).
              Positioned(
                left: size.width / 2 - 45, // ~half the K width (90 h ≈ 80 w)
                top: size.height / 2 - 55 + _kDrop.value,
                child: Opacity(
                  opacity: _kFade.value,
                  child: Image.asset(
                    'assets/kechi_K_only.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ── echi  ────────────────────────────────────────────────────
              // Sits immediately right of K, same vertical centre.
              // Slides in from _echiSlide (starts at -20 extra left offset).
              Positioned(
                left: size.width / 2 + 38 + _echiSlide.value,
                top: size.height / 2 - 35,   // echi height 70 → centre offset 35
                child: Opacity(
                  opacity: _echiFade.value,
                  child: Image.asset(
                    'assets/kechi_echi_only.png',
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ── Tagline  ─────────────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                top: size.height / 2 + 55,
                child: Opacity(
                  opacity: _taglineFade.value,
                  child: Text(
                    'create · express · vibe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.35),
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
