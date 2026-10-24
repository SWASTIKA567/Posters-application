import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/wishlist_controller.dart';
import '../controller/order_controller.dart';
import '../controller/home_controller.dart';
import '../themes/app_colors.dart';
import '../views/cart_view.dart';
import 'poster_image.dart';

class PosterDetailScreen extends StatefulWidget {
  final String title;
  final String image;
  final String price; // e.g. "₹49" — treated as the A4 base price
  final String? category;

  const PosterDetailScreen({
    super.key,
    required this.title,
    required this.image,
    required this.price,
    this.category,
  });

  @override
  State<PosterDetailScreen> createState() => _PosterDetailScreenState();
}

class _PosterDetailScreenState extends State<PosterDetailScreen> {
  // Available sizes
  static const List<String> _sizes = ['A5', 'A4', 'A3'];

  // Selected size — default A4
  String _selectedSize = 'A4';

  /// Exact official pricing per size:
  /// A5 = ₹49, A4 = ₹79, A3 = ₹109
  double _priceFor(String size) {
    switch (size) {
      case 'A5':
        return 39.0;
      case 'A4':
        return 59.0;
      case 'A3':
        return 99.0;
      default:
        return 59.0;
    }
  }

  double get _currentPrice => _priceFor(_selectedSize);

  String get _currentPriceFormatted => '₹${_currentPrice.toInt()}';

  /// Approximate physical dimensions label
  String _dimensionFor(String size) {
    switch (size) {
      case 'A5':
        return '148 × 210 mm';
      case 'A4':
        return '210 × 297 mm';
      case 'A3':
        return '297 × 420 mm';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = WishlistController.to;
    final orderCtrl = OrderController.to;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            // ── TOP: IMAGE (Balanced framed presentation) ───────────────
            Expanded(
              flex: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background container with subtle tint
                  Container(color: const Color(0xFFF1F3F6)),

                  // Framed Poster Image (Contain fit, whole artwork visible)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, topPad + 36, 32, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: 'poster_${widget.title}',
                            child: PosterImage(
                              imagePath: widget.image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: topPad + 10,
                    left: 16,
                    child: GestureDetector(
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
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
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
                  ),

                  // Wishlist button — top right
                  Positioned(
                    top: topPad + 10,
                    right: 16,
                    child: Obx(() {
                      final isLiked = wishlistCtrl.isWishlisted(widget.title);
                      return GestureDetector(
                        onTap: () async {
                          if (isLiked) {
                            final item = wishlistCtrl.wishlist.firstWhereOrNull(
                              (e) => e.title == widget.title,
                            );
                            if (item != null) {
                              await wishlistCtrl.removeWishlist(item.docId);
                            }
                          } else {
                            await wishlistCtrl.addToWishlist(
                              title: widget.title,
                              image: widget.image,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLiked
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.95),
                            boxShadow: [
                              BoxShadow(
                                color: isLiked
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── BOTTOM: INFO PANEL (Responsive & Scroll-Safe) ─────────
            Expanded(
              flex: 52,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22, 16, 22, bottomPad + 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Price row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Animated price — gradient shader
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.3),
                                            end: Offset.zero,
                                          ).animate(anim),
                                          child: child,
                                        ),
                                      ),
                                  child: ShaderMask(
                                    key: ValueKey(_currentPriceFormatted),
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            Color(0xFF00796B),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ).createShader(bounds),
                                    child: Text(
                                      _currentPriceFormatted,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Text(
                              'High-quality print  •  ${_dimensionFor(_selectedSize)}',
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── SIZE SELECTOR ────────────────────────────────────
                            const Text(
                              'Select Size',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: _sizes.map((size) {
                                final isSelected = size == _selectedSize;
                                final sizePrice = _priceFor(
                                  size,
                                ).toInt().toString();

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedSize = size),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      margin: EdgeInsets.only(
                                        right: size != _sizes.last ? 8 : 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: AppColors.primaryGrad,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isSelected ? null : Colors.white,
                                        border: isSelected
                                            ? null
                                            : Border.all(
                                                color: const Color(0xFFE8E8E8),
                                                width: 1.5,
                                              ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.30),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            size,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF1A1A1A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹$sizePrice',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white.withValues(
                                                      alpha: 0.85,
                                                    )
                                                  : const Color(0xFF9E9E9E),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),

                            // ── CATEGORY SUGGESTIONS ───────────────────────────
                            _buildCategorySuggestionsSection(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── ADD TO ORDER BUTTON (Pinned at bottom) ─────────
                    Obx(() {
                      // Check if this poster (same image AND same size) is already in cart
                      final inOrder = orderCtrl.items.any(
                        (e) =>
                            e.imageUrl == widget.image &&
                            e.size == _selectedSize,
                      );

                      return GestureDetector(
                        onTap: () {
                          if (!inOrder) {
                            orderCtrl.addItem(
                              CartItem(
                                imageUrl: widget.image,
                                size: _selectedSize,
                                quantity: 1,
                                totalPrice: _currentPrice,
                                addedAt: DateTime.now(),
                              ),
                            );
                            Get.snackbar(
                              '',
                              '',
                              titleText: const Text(
                                'Added to Order 🛒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              messageText: Text(
                                '${widget.title}  •  $_selectedSize  •  $_currentPriceFormatted',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1A1A1A),
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            Get.to(() => const CartView());
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: inOrder
                                ? null
                                : const LinearGradient(
                                    colors: AppColors.primaryGrad,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: inOrder ? Colors.white : null,
                            border: inOrder
                                ? Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 1.5,
                                  )
                                : null,
                            boxShadow: inOrder
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                inOrder
                                    ? Icons.shopping_cart_rounded
                                    : Icons.add_shopping_cart_rounded,
                                color: inOrder
                                    ? AppColors.primary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                inOrder ? 'Go to Cart' : 'Add to Cart',
                                style: TextStyle(
                                  color: inOrder
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _resolvedCategory {
    if (widget.category != null && widget.category!.trim().isNotEmpty) {
      return widget.category!.trim();
    }
    if (Get.isRegistered<HomeController>()) {
      final match = HomeController.to.allPosters.firstWhereOrNull(
        (p) => p['title'] == widget.title || p['image'] == widget.image,
      );
      if (match != null && match['category'] != null) {
        return match['category']!.trim();
      }
    }
    return '';
  }

  List<Map<String, String>> get _suggestedPosters {
    if (!Get.isRegistered<HomeController>()) return [];
    final all = HomeController.to.allPosters;
    final cat = _resolvedCategory.toLowerCase();

    // 1. Same category suggestions (excluding current poster)
    if (cat.isNotEmpty) {
      final sameCat = all.where((p) {
        final itemCat = (p['category'] ?? '').trim().toLowerCase();
        final notCurrent =
            p['title'] != widget.title && p['image'] != widget.image;
        return itemCat == cat && notCurrent;
      }).toList();

      if (sameCat.isNotEmpty) {
        return sameCat;
      }
    }

    // 2. Fallback: other posters from catalog (excluding current poster)
    return all
        .where((p) {
          return p['title'] != widget.title && p['image'] != widget.image;
        })
        .take(8)
        .toList();
  }

  Widget _buildCategorySuggestionsSection() {
    final suggestions = _suggestedPosters;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final cat = _resolvedCategory;
    final bool isCategoryMatch =
        cat.isNotEmpty &&
        suggestions.any(
          (p) => (p['category'] ?? '').toLowerCase() == cat.toLowerCase(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isCategoryMatch ? 'More in $cat' : 'You May Also Like',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${suggestions.length} posters',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              final itemTitle = item['title'] ?? 'Poster';
              final itemImage = item['image'] ?? '';
              final itemPrice = item['price'] ?? '₹59';
              final itemCat = item['category'] ?? cat;

              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => PosterDetailScreen(
                      title: itemTitle,
                      image: itemImage,
                      price: itemPrice,
                      category: itemCat,
                    ),
                    preventDuplicates: false,
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEFEFEF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 115,
                          width: 110,
                          child: PosterImage(
                            imagePath: itemImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              itemPrice,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
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
        ),
      ],
    );
  }
}
