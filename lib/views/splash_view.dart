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
  late final AnimationController _ctrl;

  // K: small jump (bounce) into position
  late final Animation<double> _kY;
  late final Animation<double> _kOpacity;

  // echi: fades in after K lands
  late final Animation<double> _echiOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // K drops 15px with a subtle elastic bounce
    _kY = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    _kOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // echi appears after K settles
    _echiOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 6500), () {
      if (!mounted) return;
      Get.off(
        () => const LoginScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 1000),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          // slight upward nudge for optical centering
          padding: const EdgeInsets.only(bottom: 60),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // K — bounces in from slightly above
                      Transform.translate(
                        offset: Offset(0, _kY.value),
                        child: Opacity(
                          opacity: _kOpacity.value,
                          child: Image.asset(
                            'assets/kechi_K_only.png',
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // echi — fades in once K has landed
                      Opacity(
                        opacity: _echiOpacity.value,
                        child: Image.asset(
                          'assets/kechi_echi_only.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _echiOpacity.value,
                    child: Text(
                      'create · express · vibe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.35),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
