import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../controller/wishlist_controller.dart';
import '../themes/app_colors.dart'; // adjust path if needed
import 'category_poster_screen.dart';
import 'poster_detail_screen.dart';

enum PosterSection { featured, recent }

class PosterCard extends StatelessWidget {
  final String title;
  final String image;
  final PosterSection section;
  final String price;

  const PosterCard({
    super.key,
    required this.title,
    required this.image,
    required this.section,
    this.price = '₹49',
  });

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = WishlistController.to;
    final isFeatured = section == PosterSection.featured;

    return GestureDetector(
      onTap: () {
        if (isFeatured) {
          Get.to(
            () => CategoryPostersScreen(categoryTitle: title),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 350),
          );
        } else {
          Get.to(
            () => PosterDetailScreen(title: title, image: image, price: price),
            transition: Transition.downToUp,
            duration: const Duration(milliseconds: 400),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isFeatured ? 155 : 130,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isFeatured ? 20 : 14),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── IMAGE ──────────────────────────────────────────
            Image.asset(image, fit: BoxFit.cover),

            // ── FEATURED: centred title with gradient overlay ──
            if (isFeatured)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            if (isFeatured)
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              )
            // ── RECENT: bottom title on light surface ──────────
            else ...[
              // bottom white pill
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  color: Colors.white,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],

            // ── WISHLIST BUTTON ────────────────────────────────
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
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLiked
                          ? AppColors.primary.withOpacity(0.9)
                          : Colors.white.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked ? Colors.white : AppColors.primary,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
