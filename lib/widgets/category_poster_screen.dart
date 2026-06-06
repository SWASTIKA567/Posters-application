import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../controller/wishlist_controller.dart';
import '../controller/home_controller.dart';
import '../themes/app_colors.dart';
import 'poster_detail_screen.dart';

class CategoryPostersScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryPostersScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryPostersScreen> createState() => _CategoryPostersScreenState();
}

class _CategoryPostersScreenState extends State<CategoryPostersScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _gridCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _gridCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();
    final wishlistCtrl = WishlistController.to;
    final posters = homeCtrl.postersByCategory(widget.categoryTitle);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── CUSTOM HEADER ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bg,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF1A1A1A),
                                size: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Poster count pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.tealOrange,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${posters.length} Posters',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category title
                      Text(
                        widget.categoryTitle,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Gradient divider
                      Container(
                        height: 3,
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGrad,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── GRID ───────────────────────────────────────────────────────
          posters.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.08),
                          ),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary.withOpacity(0.4),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No posters here yet',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final poster = posters[index];
                      // Staggered entry animation per card
                      final delay = (index * 80).clamp(0, 600);
                      return _AnimatedPosterTile(
                        title: poster["title"]!,
                        image: poster["image"]!,
                        price: poster["price"]!,
                        wishlistCtrl: wishlistCtrl,
                        parentCtrl: _gridCtrl,
                        delay: delay.toInt(),
                        index: index,
                      );
                    }, childCount: posters.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── Animated tile wrapper ──────────────────────────────────────────────────
class _AnimatedPosterTile extends StatefulWidget {
  final String title;
  final String image;
  final String price;
  final WishlistController wishlistCtrl;
  final AnimationController parentCtrl;
  final int delay;
  final int index;

  const _AnimatedPosterTile({
    required this.title,
    required this.image,
    required this.price,
    required this.wishlistCtrl,
    required this.parentCtrl,
    required this.delay,
    required this.index,
  });

  @override
  State<_AnimatedPosterTile> createState() => _AnimatedPosterTileState();
}

class _AnimatedPosterTileState extends State<_AnimatedPosterTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final start = (widget.delay / 800).clamp(0.0, 1.0);
    final end = ((widget.delay + 400) / 800).clamp(0.0, 1.0);
    final interval = Interval(start, end, curve: Curves.easeOutCubic);

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: widget.parentCtrl, curve: interval));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: widget.parentCtrl, curve: interval));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            Get.to(
              () => PosterDetailScreen(
                title: widget.title,
                image: widget.image,
                price: widget.price,
              ),
              transition: Transition.downToUp,
              duration: const Duration(milliseconds: 400),
            );
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: _PosterTileContent(
              title: widget.title,
              image: widget.image,
              price: widget.price,
              wishlistCtrl: widget.wishlistCtrl,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tile content ───────────────────────────────────────────────────────────
class _PosterTileContent extends StatelessWidget {
  final String title;
  final String image;
  final String price;
  final WishlistController wishlistCtrl;

  const _PosterTileContent({
    required this.title,
    required this.image,
    required this.price,
    required this.wishlistCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image section ─────────────────────────────────────
          Expanded(
            flex: 75,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image, fit: BoxFit.cover),

                // Subtle top-to-transparent gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final isLiked = wishlistCtrl.isWishlisted(title);
                    return GestureDetector(
                      onTap: () async {
                        if (isLiked) {
                          final item = wishlistCtrl.wishlist.firstWhereOrNull(
                            (e) => e.title == title,
                          );
                          if (item != null) {
                            await wishlistCtrl.removeWishlist(item.docId);
                          }
                        } else {
                          await wishlistCtrl.addToWishlist(
                            title: title,
                            image: image,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLiked
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.92),
                          boxShadow: [
                            BoxShadow(
                              color: isLiked
                                  ? AppColors.primary.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: isLiked ? Colors.white : AppColors.primary,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Info section ──────────────────────────────────────
          Expanded(
            flex: 25,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.primaryGrad,
                    ).createShader(bounds),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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
}
