import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../widgets/poster_card.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/category_poster_screen.dart';
import '../widgets/poster_detail_screen.dart';
import '../themes/app_colors.dart';
import '../views/upload_view.dart';
import 'cart_view.dart';
import 'wishlist_view.dart';
import 'profile_view.dart';
import 'notifications_view.dart';
import '../controller/notification_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final HomeController ctrl = Get.put(HomeController());
  final TextEditingController _searchCtrl = TextEditingController();

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
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _blob2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _blob3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _searchCtrl.text = ctrl.searchQuery.value;
  }

  @override
  void dispose() {
    _blob1.dispose();
    _blob2.dispose();
    _blob3.dispose();
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
          switch (index) {
            case 0:
              Get.offAll(() => const HomeView());
              break;

            case 1:
              Get.to(() => const CartView());
              break;

            case 2:
              Get.to(() => const WishlistView());
              break;

            case 3:
              Get.to(() => const ProfileView());
              break;
          }
        },
        onCenterTap: () {
          Get.to(() => const UploadView());
        },
      ),
      body: Stack(
        children: [
          _Blob(
            ctrl: _blob1,
            colors: const [Color(0xFF8B0000), Color(0xFFC9A227)],
            size: 260,
            top: -100,
            left: -80,
            opacity: .40,
            dx: 20,
            dy: -30,
          ),
          _Blob(
            ctrl: _blob2,
            colors: const [Color(0xFF6B1A1A), Color(0xFFAF3D1A)],
            size: 220,
            bottom: 80,
            right: -60,
            opacity: .40,
            dx: -20,
            dy: 20,
          ),
          _Blob(
            ctrl: _blob3,
            colors: const [Color(0xFFC9A227), Color(0xFF8B0000)],
            size: 180,
            top: 350,
            left: -30,
            opacity: .35,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 14),
                        _buildCategoryFilterPills(),
                        const SizedBox(height: 20),
                        Obx(() {
                          if (ctrl.isFiltering) {
                            return _buildFilteredResults();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHero(),
                              const SizedBox(height: 24),
                              _buildUploadCard(),
                              const SizedBox(height: 30),
                              _sectionTitle("Want to explore Our Collection?"),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: ctrl.featuredPosters.length,
                                  itemBuilder: (_, index) {
                                    final poster = ctrl.featuredPosters[index];
                                    return PosterCard(
                                      title: poster["title"] as String,
                                      image: poster["image"] as String,
                                      section: PosterSection.featured,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              _sectionTitle("Trending Posters"),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: ctrl.recentPosters.length,
                                  itemBuilder: (_, index) {
                                    final poster = ctrl.recentPosters[index];
                                    return PosterCard(
                                      title: poster["title"] as String,
                                      image: poster["image"] as String,
                                      price: poster["price"] as String,
                                      section: PosterSection.recent,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
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

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Kechi Logo
        SizedBox(
          width: 105,
          height: 40,
          child: Image.asset(
            'assets/kechi_logo.png',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),

        const Spacer(),

        // Notification button with badge
        GestureDetector(
          onTap: () => Get.to(() => const NotificationsView()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(.08)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
              if (Get.isRegistered<NotificationController>())
                Obx(() {
                  final count = NotificationController.to.unreadCount;
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B0000),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ── SEARCH BAR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => ctrl.setSearch(val),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: "Search posters, styles, categories...",
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF8B0000).withOpacity(0.8),
            size: 22,
          ),
          suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                  onPressed: () {
                    _searchCtrl.clear();
                    ctrl.setSearch('');
                  },
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── CATEGORY FILTER PILLS ───────────────────────────────────────────────────
  Widget _buildCategoryFilterPills() {
    return SizedBox(
      height: 38,
      child: Obx(() {
        final selected = ctrl.selectedCategory.value ?? 'All';

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: ctrl.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final cat = ctrl.categories[index];
            final title = cat['title']!;
            final icon = cat['icon']!;
            final isSelected = (selected == title);

            return GestureDetector(
              onTap: () {
                if (title == 'All') {
                  ctrl.setCategory(null);
                } else {
                  ctrl.setCategory(isSelected ? null : title);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B0000)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B0000)
                        : Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B0000).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ── FILTERED RESULTS GRID ───────────────────────────────────────────────────
  Widget _buildFilteredResults() {
    final list = ctrl.filteredPosters;
    final cat = ctrl.selectedCategory.value;
    final q = ctrl.searchQuery.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Search Results (${list.length})",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                ctrl.setSearch('');
                ctrl.setCategory(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Clear filters",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (cat != null || q.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            "Filtering by: ${cat != null ? 'Category "$cat"' : ''} ${q.isNotEmpty ? 'Query "$q"' : ''}",
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
          ),
        ],
        const SizedBox(height: 16),

        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                const Text("🔍", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  "No posters found",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  "Try searching for another keyword or pick a different category.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (_, index) {
              final poster = list[index];
              return GestureDetector(
                onTap: () {
                  Get.to(() => PosterDetailScreen(
                        title: poster["title"]!,
                        image: poster["image"]!,
                        price: poster["price"] ?? "₹49",
                      ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: Image.asset(
                            poster["image"]!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poster["title"]!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  poster["price"] ?? "₹49",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B0000),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC9A227).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    poster["category"] ?? "Poster",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8B0000),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHero() {
    final screenWidth = MediaQuery.of(context).size.width;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text side
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
                  ).createShader(b),
                  child: Text(
                    "Print it.\nFrame it.\nLove it.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: screenWidth * 0.075,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Turn your digital posters into premium prints.",
                  style: TextStyle(
                    color: Colors.black.withOpacity(.55),
                    fontSize: screenWidth * 0.030,
                  ),
                ),
              ],
            ),
          ),

          // Image fills whatever height the text column naturally takes
          Flexible(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/bg.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: () {
        Get.to(() => const UploadView());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Poster",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gallery • Drive • URL",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.black,
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
