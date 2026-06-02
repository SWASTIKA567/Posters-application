import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../widgets/poster_card.dart';
import '../widgets/custom_bottom_navbar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final HomeController ctrl = Get.put(HomeController());
  int selectedIndex = 0;

  late AnimationController _blob1;
  late AnimationController _blob2;
  late AnimationController _blob3;
  late AnimationController _fadeCtrl;

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
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _blob1.dispose();
    _blob2.dispose();
    _blob3.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        onCenterTap: () {
          print("Print Clicked");
        },
      ),
      body: Stack(
        children: [
          _Blob(
            ctrl: _blob1,
            colors: const [Color(0xFF7C3AED), Color(0xFF3B82F6)],
            size: 260,
            top: -100,
            left: -80,
            opacity: .30,
            dx: 20,
            dy: -30,
          ),
          _Blob(
            ctrl: _blob2,
            colors: const [Color(0xFFEC4899), Color(0xFFF59E0B)],
            size: 220,
            bottom: 100,
            right: -60,
            opacity: .22,
            dx: -20,
            dy: 20,
          ),
          _Blob(
            ctrl: _blob3,
            colors: const [Color(0xFF10B981), Color(0xFF3B82F6)],
            size: 160,
            top: 350,
            left: -30,
            opacity: .15,
            dx: 15,
            dy: -20,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildHero(),
                        const SizedBox(height: 24),
                        _buildUploadCard(),
                        const SizedBox(height: 30),
                        _sectionTitle("Featured Posters"),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: Obx(
                            () => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ctrl.featuredPosters.length,
                              itemBuilder: (_, index) {
                                final poster = ctrl.featuredPosters[index];
                                return PosterCard(
                                  title: poster["title"]!,
                                  image: poster["image"]!,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _sectionTitle("Recent Posters"),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: Obx(
                            () => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ctrl.recentPosters.length,
                              itemBuilder: (_, index) {
                                final poster = ctrl.recentPosters[index];
                                return PosterCard(
                                  title: poster["title"]!,
                                  image: poster["image"]!,
                                );
                              },
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) =>
              const LinearGradient(colors: _AppColors.logoGrad).createShader(b),
          child: const Text(
            "postly.",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(.05),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: _AppColors.primaryGrad,
            ).createShader(b),
            child: const Text(
              "Print it.\nFrame it.\nLove it.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 34,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Turn your digital posters into premium prints.",
            style: TextStyle(color: Colors.white.withOpacity(.55)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: _AppColors.primaryGrad),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upload Poster",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Gallery • Drive • URL",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

// ─── COLORS ───────────────────────────────────────────────────────────────────
class _AppColors {
  static const bg = Color(0xFF0A0A0F);

  static const List<Color> primaryGrad = [Color(0xFF7C3AED), Color(0xFF3B82F6)];

  static const List<Color> logoGrad = [
    Color(0xFFA78BFA),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
  ];
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
