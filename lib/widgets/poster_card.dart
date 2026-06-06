import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../controller/wishlist_controller.dart';

enum PosterSection { featured, recent }

class PosterCard extends StatelessWidget {
  final String title;
  final String image;
  final PosterSection section;

  const PosterCard({
    super.key,
    required this.title,
    required this.image,
    required this.section, // ← this was missing from your on-disk file
  });

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = WishlistController.to;
    final isFeatured = section == PosterSection.featured;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isFeatured ? 155 : 130,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isFeatured ? 20 : 14),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── IMAGE ──────────────────────────────────────────
          Image.asset(image, fit: BoxFit.cover),

          // ── FEATURED: centred title ────────────────────────
          if (isFeatured)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.black),
                      Shadow(blurRadius: 20, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            )
          // ── RECENT: bottom title ───────────────────────────
          else
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // ── WISHLIST BUTTON (featured only) ───────────────
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
                        ? Colors.redAccent.withOpacity(0.9)
                        : Colors.black.withOpacity(0.4),
                  ),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
