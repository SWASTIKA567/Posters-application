import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/wishlist_controller.dart';
import '../controller/home_controller.dart';
import '../themes/app_colors.dart';
import 'poster_detail_screen.dart';
import 'poster_image.dart';

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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        final posters = homeCtrl.postersByCategory(widget.categoryTitle);

        return CustomScrollView(
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
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Get.back();
                                }
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.black.withOpacity(.08)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.07),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${posters.length} Posters',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Category',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),

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
                        final delay = (index * 80).clamp(0, 600);
                        return _AnimatedPosterTile(
                          title: poster["title"]!,
                          image: poster["image"]!,
                          price: poster["price"] ?? '₹49',
                          category: widget.categoryTitle,
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
        );
      }),
    );
  }
}

// ── Animated tile wrapper ──────────────────────────────────────────────────
class _AnimatedPosterTile extends StatefulWidget {
  final String title;
  final String image;
  final String price;
  final String category;
  final WishlistController wishlistCtrl;
  final AnimationController parentCtrl;
  final int delay;
  final int index;

  const _AnimatedPosterTile({
    required this.title,
    required this.image,
    required this.price,
    required this.category,
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
  late AnimationController _tileCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _tileCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _tileCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tileCtrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _tileCtrl.forward();
    });
  }

  @override
  void dispose() {
    _tileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            Get.to(
              () => PosterDetailScreen(
                title: widget.title,
                image: widget.image,
                price: widget.price,
                category: widget.category,
              ),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 300),
            );
          },
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: _buildTileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent() {
    final title = widget.title;
    final image = widget.image;
    final wishlistCtrl = widget.wishlistCtrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
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
                PosterImage(
                  imagePath: image,
                  fit: BoxFit.cover,
                ),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
