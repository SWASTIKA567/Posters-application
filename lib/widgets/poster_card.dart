// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/wishlist_controller.dart';
import 'package:collection/collection.dart';

class PosterCard extends StatelessWidget {
  final String title;
  final String image;

  const PosterCard({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = WishlistController.to;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(.3),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────
          Opacity(
            opacity: 0.8,
            child: Image.asset(
              image,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // ── Center title ──────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.3,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black87),
                    Shadow(blurRadius: 20, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),

          // ── Heart button (top-right) ──────────────────────────
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.elasticOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey(isLiked), // triggers AnimatedSwitcher
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? Colors.redAccent.withOpacity(0.85)
                          : Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 18,
                    ),
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
