import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'login_view.dart';

class AppColors {
  static const bg = Color(0xFF0A0A0F);
  static const purple = Color(0xFFA78BFA);
  static const blue = Color(0xFF38BDF8);
  static const green = Color(0xFF34D399);
  static const pink = Color(0xFFF472B6);
  static const amber = Color(0xFFFBBF24);

  static const List<Color> logoGrad = [
    Color(0xFFA78BFA),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
  ];
  static const List<Color> primaryGrad = [Color(0xFF7C3AED), Color(0xFF3B82F6)];

  static const List<Color> p1 = [
    Color(0xFF1e1040),
    Color(0xFF7C3AED),
    Color(0xFF3B82F6),
  ];
  static const List<Color> p2 = [
    Color(0xFF2d0a1e),
    Color(0xFFEC4899),
    Color(0xFFFBBF24),
  ];
  static const List<Color> p3 = [
    Color(0xFF0a1f1a),
    Color(0xFF10B981),
    Color(0xFF38BDF8),
  ];
  static const List<Color> p4 = [
    Color(0xFFFAC775),
    Color(0xFFD4537E),
    Color(0xFF534AB7),
  ];
}

class PosterConfig {
  final List<Color> colors;
  final Offset entryOffset;
  final Offset exitOffset;
  final double entryRotation;
  final double exitRotation;
  final Size size;

  const PosterConfig({
    required this.colors,
    required this.entryOffset,
    required this.exitOffset,
    required this.entryRotation,
    required this.exitRotation,
    required this.size,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _posterCtrls;
  late final AnimationController _overlayCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _tagCtrl;
  late final AnimationController _taglineCtrl;

  late final List<Animation<double>> _posterAnimations;
  late final Animation<double> _overlayAnim;
  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _logoOpacityAnim;
  late final Animation<double> _tagAnim;
  late final Animation<double> _taglineAnim;

  static const _flightDuration = Duration(milliseconds: 950);
  static const _gapBetween = Duration(milliseconds: 420);
  static const _pauseAt = Duration(milliseconds: 220);

  final _posters = [
    PosterConfig(
      colors: AppColors.p1,
      entryOffset: const Offset(-300, -200),
      exitOffset: const Offset(700, 900),
      entryRotation: -20,
      exitRotation: 10,
      size: const Size(280, 380),
    ),
    PosterConfig(
      colors: AppColors.p2,
      entryOffset: const Offset(300, 40),
      exitOffset: const Offset(-700, 700),
      entryRotation: 15,
      exitRotation: -8,
      size: const Size(260, 360),
    ),
    PosterConfig(
      colors: AppColors.p3,
      entryOffset: const Offset(250, 350),
      exitOffset: const Offset(-700, -500),
      entryRotation: 20,
      exitRotation: -15,
      size: const Size(270, 370),
    ),
    PosterConfig(
      colors: AppColors.p4,
      entryOffset: const Offset(280, -180),
      exitOffset: const Offset(-700, 900),
      entryRotation: -18,
      exitRotation: 12,
      size: const Size(265, 355),
    ),
  ];

  int _activePoster = -1;
  bool _showOverlay = false;
  bool _showLogo = false;
  bool _showTag = false;
  bool _showTagline = false;

  @override
  void initState() {
    super.initState();

    _posterCtrls = List.generate(
      _posters.length,
      (_) => AnimationController(vsync: this, duration: _flightDuration),
    );

    _posterAnimations = _posterCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _overlayAnim = CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScaleAnim = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOutBack));
    _logoOpacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _tagAnim = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut);

    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _taglineAnim = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (int i = 0; i < _posters.length; i++) {
      if (!mounted) return;
      setState(() => _activePoster = i);
      _posterCtrls[i].forward();

      if (i < _posters.length - 1) {
        await Future.delayed(_gapBetween);
      }
    }

    final lastFlight = _flightDuration + _pauseAt;
    await Future.delayed(lastFlight);

    if (!mounted) return;
    setState(() => _showOverlay = true);
    _overlayCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _showLogo = true);
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _showTag = true);
    _tagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _showTagline = true);
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // ✅ GetX navigation replacing vanilla Navigator
    Get.off(
      () => const LoginScreen(),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    for (final c in _posterCtrls) c.dispose();
    _overlayCtrl.dispose();
    _logoCtrl.dispose();
    _tagCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          ...List.generate(_posters.length, (i) {
            final p = _posters[i];
            final halfDur = _flightDuration.inMilliseconds / 2;
            final pauseMs = _pauseAt.inMilliseconds;
            final totalMs = _flightDuration.inMilliseconds + pauseMs;

            return AnimatedBuilder(
              animation: _posterCtrls[i],
              builder: (_, __) {
                final rawT = _posterCtrls[i].value;
                final tMs = rawT * totalMs;

                Offset offset;
                double rotation;
                double opacity;
                double scale;

                if (tMs <= halfDur) {
                  final t = _easeOut(tMs / halfDur);
                  offset = Offset.lerp(p.entryOffset, Offset.zero, t)!;
                  rotation = _lerp(p.entryRotation, 0, t);
                  opacity = _easeOut(tMs / halfDur);
                  scale = _lerp(0.6, 1.0, t);
                } else if (tMs <= halfDur + pauseMs) {
                  offset = Offset.zero;
                  rotation = 0;
                  opacity = 1.0;
                  scale = 1.0;
                } else {
                  final exitT = (tMs - halfDur - pauseMs) / halfDur;
                  final t = _easeIn(math.min(exitT, 1.0));
                  offset = Offset.lerp(Offset.zero, p.exitOffset, t)!;
                  rotation = _lerp(0, p.exitRotation, t);
                  opacity = math.max(1.0 - t * 1.4, 0.0);
                  scale = _lerp(1.0, 0.6, t);
                }

                if (i > _activePoster) return const SizedBox.shrink();

                return Positioned(
                  left: cx - p.size.width / 2 + offset.dx,
                  top: cy - p.size.height / 2 + offset.dy,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(p.size.width / 2, p.size.height / 2)
                      ..rotateZ(rotation * math.pi / 180)
                      ..scale(scale)
                      ..translate(-p.size.width / 2, -p.size.height / 2),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: _PosterCard(colors: p.colors, size: p.size),
                    ),
                  ),
                );
              },
            );
          }),

          if (_showOverlay)
            AnimatedBuilder(
              animation: _overlayAnim,
              builder: (_, __) => Container(
                color: AppColors.bg.withOpacity(_overlayAnim.value * 0.92),
              ),
            ),

          if (_showLogo)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _logoScaleAnim.value,
                        child: ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: AppColors.logoGrad,
                          ).createShader(b),
                          child: const Text(
                            'postly.',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -3,
                              fontFamily: 'Syne',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_showTag)
                    AnimatedBuilder(
                      animation: _tagCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _tagAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, _lerp(14, 0, _tagAnim.value)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'create · express · vibe',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFC4B5FD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          if (_showTagline)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _taglineCtrl,
                builder: (_, __) => Opacity(
                  opacity: _taglineAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _lerp(12, 0, _taglineAnim.value)),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0x59FFFFFF),
                          letterSpacing: 0.4,
                          fontFamily: 'SpaceGrotesk',
                        ),
                        children: const [
                          TextSpan(text: 'make posters that '),
                          TextSpan(
                            text: 'slap.',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static double _easeIn(double t) => t * t * t;
}

class _PosterCard extends StatelessWidget {
  final List<Color> colors;
  final Size size;

  const _PosterCard({required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }
}
